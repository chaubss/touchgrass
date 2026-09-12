from datetime import datetime, timedelta, timezone

DEMO_USER = "11111111-1111-4111-8111-111111111111"
PEER = "22222222-2222-4222-8222-222222222222"


def seed(db):
    """Explicitly opt-in fictional fixtures; never reset existing accounts/balances."""
    now = datetime.now(timezone.utc)
    for ident, andrew, name in [(DEMO_USER, "demo", "Demo Student"), (PEER, "peer", "Campus Peer")]:
        db.students.update_one({"_id": ident}, {"$setOnInsert": {
            "andrewID": andrew, "fullName": name, "program": "CMU · Demo account",
            "wallet": 1500, "allowanceRemaining": 500, "allowanceMonth": now.strftime("%Y-%m"),
            "followers": 0, "following": 0,
        }}, upsert=True)
    venue = {"id": "cohon", "name": "Cohon University Center", "shortName": "Cohon",
             "latitude": 40.4430, "longitude": -79.9423}
    for ident, title, category, pantry in [
        ("33333333-3333-4333-8333-333333333333", "Campus pantry volunteer shift", "service", True),
        ("44444444-4444-4444-8444-444444444444", "Campus walking group", "wellness", False),
    ]:
        db.events.update_one({"_id": ident}, {"$setOnInsert": {
            "title": title, "organizer": "Demo student organizers", "summary": "Fictional event for testing the backend.",
            "start": now - timedelta(minutes=10), "end": now + timedelta(hours=2),
            "venue": venue, "room": "Main entrance", "category": category, "karmaReward": 100,
            "capacity": 30, "attending": 0, "isPantryVolunteerEvent": pantry,
        }}, upsert=True)
    options = [
        ("dining-block", "Dining block", "One campus meal", 600, "dining", "fork.knife"),
        ("entropy", "Entropy+ snack credit", "$5 snack credit", 250, "dining", "cart"),
        ("la-prima", "La Prima coffee", "$5 coffee credit", 250, "dining", "cup.and.saucer"),
        ("cmu-store", "CMU Store credit", "$25 store credit", 1250, "merch", "bag"),
        ("cmu-stickers", "Scottie sticker pair", "Two CMU stickers", 300, "merch", "seal"),
        ("cmu-pantry", "CMU Food Pantry", "Support student groceries", 0, "charity", "heart"),
        ("pittsburgh-food-bank", "Greater Pittsburgh Community Food Bank", "Support local groceries", 0, "charity", "heart"),
    ]
    for image, title, detail, cost, category, symbol in options:
        db.catalog.update_one({"_id": image}, {"$setOnInsert": {
            "title": title, "detail": detail, "cost": cost, "category": category,
            "symbol": symbol, "imageName": image, "remaining": None, "isOpenAmount": category == "charity",
        }}, upsert=True)
