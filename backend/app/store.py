import hashlib
import json
import math
import secrets
from datetime import datetime, timedelta, timezone
from uuid import uuid4

from fastapi import HTTPException
from pymongo import ReturnDocument
from pymongo.errors import DuplicateKeyError
from pymongo.read_concern import ReadConcern
from pymongo.write_concern import WriteConcern


def now():
    instant = datetime.now(timezone.utc)
    # BSON stores milliseconds. Match that precision on first responses so an
    # idempotent replay is byte-for-byte equivalent after database round-tripping.
    return instant.replace(microsecond=(instant.microsecond // 1000) * 1000)


def public(doc):
    if doc is None:
        raise HTTPException(404, "Not found")
    return {("id" if k == "_id" else k): v for k, v in doc.items() if not k.startswith("internal")}


def initialize(db):
    db.students.create_index("andrewID", unique=True)
    db.grants.create_index([("from", 1), ("to", 1), ("createdAt", -1)])
    db.ledger.create_index([("userID", 1), ("date", -1)])
    db.checkins.create_index([("userID", 1), ("eventID", 1)], unique=True)
    db.redemptions.create_index([("userID", 1), ("date", -1)])
    db.cheers.create_index([("userID", 1), ("grantID", 1)], unique=True)
    db.recaps.create_index("expiresAt", expireAfterSeconds=0)
    # Create collections before transactions, including the idempotency collection.
    for name in ["events", "catalog", "operations"]:
        if name not in db.list_collection_names():
            db.create_collection(name)


class Store:
    def __init__(self, db):
        self.db = db

    def balance(self, user_id, session=None):
        month = now().strftime("%Y-%m")
        self.db.students.update_one({"_id": user_id, "allowanceMonth": {"$ne": month}},
            {"$set": {"allowanceRemaining": 500, "allowanceMonth": month}}, session=session)
        return public(self.db.students.find_one({"_id": user_id}, session=session))

    def operation(self, actor, key, kind, payload, action):
        identity = f"{actor}:{key}"
        fingerprint = hashlib.sha256(json.dumps([kind, payload], sort_keys=True).encode()).hexdigest()

        def replay(doc):
            if doc["fingerprint"] != fingerprint:
                raise HTTPException(409, "Idempotency-Key already used for another request")
            return doc["response"]

        def execute(session):
            old = self.db.operations.find_one({"_id": identity}, session=session)
            if old:
                return replay(old)
            result = action(session)
            self.db.operations.insert_one({"_id": identity, "fingerprint": fingerprint,
                "response": result, "createdAt": now()}, session=session)
            return result

        try:
            with self.db.client.start_session() as session:
                return session.with_transaction(execute, read_concern=ReadConcern("snapshot"),
                    write_concern=WriteConcern("majority"), max_commit_time_ms=10000)
        except DuplicateKeyError:
            old = self.db.operations.find_one({"_id": identity})
            if old:
                return replay(old)
            raise HTTPException(409, "This action has already been recorded")

    def ledger(self, user, delta, title, subtitle, kind, session, allowance=0):
        self.db.ledger.insert_one({"_id": str(uuid4()), "userID": user, "delta": delta,
            "allowanceDelta": allowance, "title": title, "subtitle": subtitle,
            "kind": kind, "date": now()}, session=session)

    def give(self, user, data, key):
        def action(s):
            if data.to == user:
                raise HTTPException(400, "You cannot give karma to yourself")
            self.balance(user, s)
            recipient = self.db.students.find_one({"_id": data.to}, session=s)
            if not recipient:
                raise HTTPException(404, "Recipient not found")
            # This shared account write serializes concurrent gifts before checking the rolling cap.
            sender = self.db.students.find_one_and_update({"_id": user,
                "wallet": {"$gte": data.amount}, "allowanceRemaining": {"$gte": data.amount}},
                {"$inc": {"wallet": -data.amount, "allowanceRemaining": -data.amount}},
                return_document=ReturnDocument.AFTER, session=s)
            if not sender:
                raise HTTPException(409, "Insufficient balance or monthly giving allowance")
            repeats = self.db.grants.count_documents({"from": user, "to": data.to,
                "createdAt": {"$gt": now() - timedelta(days=7)}}, session=s)
            if repeats >= 3:
                raise HTTPException(409, "Only three recognitions per recipient in seven days")
            self.db.students.update_one({"_id": data.to}, {"$inc": {"wallet": data.amount}}, session=s)
            grant = {"_id": str(uuid4()), "from": user, **data.model_dump(), "createdAt": now()}
            self.db.grants.insert_one(grant, session=s)
            self.ledger(user, -data.amount, f"You recognised {recipient['fullName']}", data.reason, "given", s, -data.amount)
            self.ledger(data.to, data.amount, f"Recognised by {sender['fullName']}", data.reason, "received", s)
            return {"grant": public(grant), "wallet": sender["wallet"], "allowanceRemaining": sender["allowanceRemaining"]}
        return self.operation(user, key, "give", data.model_dump(), action)

    def check_in(self, user, event_id, data, key):
        def action(s):
            event = self.db.events.find_one({"_id": event_id}, session=s)
            if not event:
                raise HTTPException(404, "Event not found")
            if self.db.checkins.find_one({"userID": user, "eventID": event_id}, session=s):
                raise HTTPException(409, "Already checked in")
            if not event["start"] - timedelta(minutes=30) <= now() <= event["end"]:
                raise HTTPException(409, "Outside check-in window")
            if (data.latitude is None) != (data.longitude is None):
                raise HTTPException(422, "Provide both coordinates or neither")
            if data.latitude is not None:
                lat1, lat2 = map(math.radians, [data.latitude, event["venue"]["latitude"]])
                dlon = math.radians(data.longitude - event["venue"]["longitude"])
                a = math.sin((lat1 - lat2) / 2) ** 2 + math.cos(lat1) * math.cos(lat2) * math.sin(dlon / 2) ** 2
                distance = 6371000 * 2 * math.asin(min(1, math.sqrt(a)))
                if distance > 150:
                    raise HTTPException(409, "Move within 150 metres of the event")
            # Same no-location fallback as the current app; not fraud-proof attendance verification.
            updated = self.db.events.update_one({"_id": event_id, "attending": {"$lt": event["capacity"]}},
                {"$inc": {"attending": 1}}, session=s)
            if not updated.modified_count:
                raise HTTPException(409, "Event is full")
            self.db.checkins.insert_one({"_id": str(uuid4()), "userID": user, "eventID": event_id,
                "date": now(), "category": event["category"], "isPantryVolunteerEvent": event["isPantryVolunteerEvent"]}, session=s)
            self.db.students.update_one({"_id": user}, {"$inc": {"wallet": event["karmaReward"]}}, session=s)
            self.ledger(user, event["karmaReward"], event["title"], event["organizer"], "event", s)
            return {"eventID": event_id, "checkedIn": True, "karmaAwarded": event["karmaReward"]}
        return self.operation(user, key, "check-in:" + event_id, data.model_dump(), action)

    def redeem(self, user, data, key):
        def action(s):
            option = self.db.catalog.find_one({"_id": data.optionID}, session=s)
            if not option:
                raise HTTPException(404, "Reward not found")
            cost = data.amount if option["isOpenAmount"] else option["cost"]
            if cost is None or cost <= 0:
                raise HTTPException(422, "A positive donation amount is required")
            if not option["isOpenAmount"] and data.amount is not None and data.amount != cost:
                raise HTTPException(422, "Reward price is fixed by the server")
            if option["remaining"] is not None:
                result = self.db.catalog.update_one({"_id": data.optionID, "remaining": {"$gt": 0}},
                    {"$inc": {"remaining": -1}}, session=s)
                if not result.modified_count:
                    raise HTTPException(409, "Reward is sold out")
            result = self.db.students.update_one({"_id": user, "wallet": {"$gte": cost}},
                {"$inc": {"wallet": -cost}}, session=s)
            if not result.modified_count:
                raise HTTPException(409, "Insufficient balance")
            charity = option["category"] == "charity"
            claim = None if charity else "TRTN-" + secrets.token_hex(4).upper()
            receipt = {"_id": str(uuid4()), "userID": user, "optionID": data.optionID,
                "cost": cost, "claimCode": claim, "isDonation": charity, "date": now(), "status": "demo"}
            self.db.redemptions.insert_one(receipt, session=s)
            self.ledger(user, -cost, option["title"], "Donated (demo)" if charity else claim, "redeemed", s)
            return public(receipt)
        return self.operation(user, key, "redeem", data.model_dump(), action)

    def badges(self, user):
        given = self.db.grants.count_documents({"from": user})
        checkins = list(self.db.checkins.find({"userID": user}))
        redeemed = self.db.redemptions.count_documents({"userID": user})
        definitions = [
            ("firstRipple", "First Ripple", 1, given, "Give your first recognition."),
            ("clutchScotty", "Clutch Scotty", 5, self.db.grants.count_documents({"to": user, "category": "lifting"}), "Receive 5 teamwork recognitions."),
            ("bugWhisperer", "Bug Whisperer", 5, self.db.grants.count_documents({"to": user, "category": "debugging"}), "Receive 5 debugging recognitions."),
            ("touchGrass", "Touch Grass", 5, sum(x["category"] == "wellness" for x in checkins), "Check in to 5 wellness events."),
            ("pantryPal", "Pantry Pal", 3, sum(x["isPantryVolunteerEvent"] for x in checkins), "Check in to 3 pantry volunteer events."),
            ("fullCircle", "Full Circle", 3, sum([bool(checkins), bool(given), bool(redeemed)]), "Attend an event, give recognition and redeem or donate."),
        ]
        return [{"id": i, "title": title, "target": target, "count": count,
            "completed": min(target, count), "earned": count >= target, "nextStep": step}
            for i, title, target, count, step in definitions]
