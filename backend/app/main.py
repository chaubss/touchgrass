from contextlib import asynccontextmanager
import hmac
from typing import Annotated

import httpx
from fastapi import Depends, FastAPI, Header, HTTPException, Query, Request, UploadFile
from fastapi.responses import JSONResponse
from pymongo import MongoClient
from pymongo.errors import PyMongoError

from .config import Settings
from .models import CheckInInput, GrantInput, RedeemInput
from .recaps import recap
from .seed import DEMO_USER, seed
from .store import Store, initialize, public


def create_app(settings=None):
    settings = settings or Settings()

    @asynccontextmanager
    async def lifespan(app):
        app.state.db = None
        client = None
        if settings.enabled:
            client = MongoClient(settings.mongo_uri, serverSelectionTimeoutMS=3000,
                connectTimeoutMS=3000, socketTimeoutMS=10000, tz_aware=True)
            try:
                client.admin.command("ping")
                db = client[settings.database]
                initialize(db)
                if settings.seed:
                    seed(db)
                app.state.db = db
            except PyMongoError:
                # Startup stays alive; readiness explains the outage. No writes silently fall back.
                client.close()
        yield
        if client:
            client.close()

    app = FastAPI(title="Karma optional backend", version="0.1.0", lifespan=lifespan)

    @app.middleware("http")
    async def kill_switch(request: Request, call_next):
        if request.url.path.startswith("/v1") and not settings.enabled:
            return JSONResponse(status_code=503, content={"detail": "Backend disabled", "code": "backend_disabled"})
        return await call_next(request)

    @app.exception_handler(PyMongoError)
    async def database_error(request, exc):
        return JSONResponse(status_code=503, content={"detail": "Database unavailable; retry with the SAME Idempotency-Key"})

    def db():
        value = app.state.db
        if value is None:
            raise HTTPException(503, "Database unavailable; restart the API after MongoDB recovers")
        return value

    def actor(authorization: Annotated[str | None, Header()] = None, database=Depends(db)):
        if not settings.demo_auth or len(settings.demo_token) < 24:
            raise HTTPException(503, "Demo authentication is not configured")
        expected = "Bearer " + settings.demo_token
        if not authorization or not hmac.compare_digest(authorization, expected):
            raise HTTPException(401, "Invalid bearer token", headers={"WWW-Authenticate": "Bearer"})
        if database.students.find_one({"_id": DEMO_USER}) is None:
            raise HTTPException(403, "Demo account not provisioned")
        return DEMO_USER

    def key(idempotency_key: Annotated[str, Header(min_length=8, max_length=128)]):
        return idempotency_key

    @app.get("/health/live")
    def live():
        return {"status": "alive", "backendEnabled": settings.enabled}

    @app.get("/health/ready")
    def ready():
        if not settings.enabled:
            return {"status": "disabled"}
        db().command("ping")
        return {"status": "ready"}

    @app.get("/v1/config")
    def config(user=Depends(actor)):
        return {"backendEnabled": True, "ifmEnabled": settings.ifm,
                "elevenLabsEnabled": settings.elevenlabs, "authentication": "demo-only"}

    @app.get("/v1/me")
    def me(user=Depends(actor), database=Depends(db)):
        return Store(database).balance(user)

    @app.get("/v1/students")
    def students(q: str = Query("", max_length=100), user=Depends(actor), database=Depends(db)):
        import re
        query = {"$or": [{"fullName": {"$regex": re.escape(q), "$options": "i"}},
                         {"andrewID": {"$regex": re.escape(q), "$options": "i"}}]} if q else {}
        return [public(p) for p in database.students.find(query, {"andrewID": 1, "fullName": 1,
            "program": 1, "followers": 1, "following": 1}).limit(50)]

    @app.get("/v1/me/ledger")
    def ledger(limit: int = Query(50, ge=1, le=100), offset: int = Query(0, ge=0, le=10000),
               user=Depends(actor), database=Depends(db)):
        return [public(x) for x in database.ledger.find({"userID": user}).sort("date", -1).skip(offset).limit(limit)]

    @app.get("/v1/grants")
    def grants(limit: int = Query(30, ge=1, le=100), offset: int = Query(0, ge=0, le=10000),
               user=Depends(actor), database=Depends(db)):
        visible = {"$or": [{"isPublic": True}, {"from": user}, {"to": user}]}
        return [{**public(g), "cheers": database.cheers.count_documents({"grantID": g["_id"]}),
                 "cheeredByMe": database.cheers.count_documents({"grantID": g["_id"], "userID": user}) > 0}
                for g in database.grants.find(visible).sort("createdAt", -1).skip(offset).limit(limit)]

    @app.post("/v1/grants", status_code=201)
    def give(data: GrantInput, user=Depends(actor), request_key=Depends(key), database=Depends(db)):
        return Store(database).give(user, data, request_key)

    @app.put("/v1/grants/{grant_id}/cheer")
    def cheer(grant_id: str, active: bool, user=Depends(actor), database=Depends(db)):
        if not database.grants.find_one({"_id": grant_id, "isPublic": True}):
            raise HTTPException(404, "Public grant not found")
        identity = {"_id": user + ":" + grant_id}
        if active:
            database.cheers.update_one(identity, {"$setOnInsert": {"userID": user, "grantID": grant_id}}, upsert=True)
        else:
            database.cheers.delete_one(identity)
        return {"cheeredByMe": active, "cheers": database.cheers.count_documents({"grantID": grant_id})}

    @app.get("/v1/events")
    def events(user=Depends(actor), database=Depends(db)):
        checked = {c["eventID"] for c in database.checkins.find({"userID": user})}
        return [{**public(e), "checkedIn": e["_id"] in checked} for e in database.events.find().sort("start", 1).limit(100)]

    @app.post("/v1/events/{event_id}/check-in")
    def check_in(event_id: str, data: CheckInInput, user=Depends(actor), request_key=Depends(key), database=Depends(db)):
        return Store(database).check_in(user, event_id, data, request_key)

    @app.get("/v1/catalog")
    def catalog(user=Depends(actor), database=Depends(db)):
        return [public(x) for x in database.catalog.find().limit(100)]

    @app.post("/v1/redemptions", status_code=201)
    def redeem(data: RedeemInput, user=Depends(actor), request_key=Depends(key), database=Depends(db)):
        return Store(database).redeem(user, data, request_key)

    @app.get("/v1/me/badges")
    def badges(user=Depends(actor), database=Depends(db)):
        return Store(database).badges(user)

    @app.get("/v1/recap")
    def digest(user=Depends(actor), database=Depends(db)):
        return recap(database, settings)

    @app.post("/v1/transcriptions")
    def transcribe(file: UploadFile, user=Depends(actor)):
        if not settings.elevenlabs or not settings.elevenlabs_key:
            raise HTTPException(503, "ElevenLabs transcription disabled or not configured")
        audio = file.file.read(5 * 1024 * 1024 + 1)
        if len(audio) > 5 * 1024 * 1024:
            raise HTTPException(413, "Recording must be under 5 MB")
        if not audio:
            raise HTTPException(422, "Empty recording")
        try:
            result = httpx.post("https://api.elevenlabs.io/v1/speech-to-text", timeout=30,
                headers={"xi-api-key": settings.elevenlabs_key},
                data={"model_id": "scribe_v2", "tag_audio_events": "false"},
                files={"file": ("reason.m4a", audio, "audio/mp4")})
            result.raise_for_status()
            text = result.json()["text"].strip()
            if not text:
                raise ValueError("No speech")
            return {"text": text, "provider": "ElevenLabs"}
        except (httpx.HTTPError, KeyError, ValueError, TypeError):
            raise HTTPException(502, "Transcription unavailable; retry or type the reason")

    return app


app = create_app()
