import os
from dataclasses import dataclass, field


def flag(name: str) -> bool:
    return os.getenv(name, "false").lower() == "true"


@dataclass
class Settings:
    enabled: bool = field(default_factory=lambda: flag("BACKEND_ENABLED"))
    mongo_uri: str = field(default_factory=lambda: os.getenv("MONGO_URI", "mongodb://mongo:27017/?replicaSet=rs0"))
    database: str = field(default_factory=lambda: os.getenv("MONGO_DATABASE", "karma"))
    demo_auth: bool = field(default_factory=lambda: flag("DEMO_AUTH_ENABLED"))
    demo_token: str = field(default_factory=lambda: os.getenv("DEMO_TOKEN", ""), repr=False)
    seed: bool = field(default_factory=lambda: flag("SEED_DEMO_DATA"))
    ifm: bool = field(default_factory=lambda: flag("IFM_ENABLED"))
    ifm_key: str = field(default_factory=lambda: os.getenv("IFM_API_KEY", ""), repr=False)
    elevenlabs: bool = field(default_factory=lambda: flag("ELEVENLABS_ENABLED"))
    elevenlabs_key: str = field(default_factory=lambda: os.getenv("ELEVENLABS_API_KEY", ""), repr=False)
