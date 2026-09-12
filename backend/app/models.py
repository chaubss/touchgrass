from typing import Literal
from pydantic import BaseModel, ConfigDict, Field, field_validator


class Input(BaseModel):
    model_config = ConfigDict(extra="forbid")


class GrantInput(Input):
    to: str = Field(min_length=1, max_length=100)
    amount: int = Field(ge=1, le=100, strict=True)
    category: Literal["debugging", "teaching", "lifting", "organizing", "kindness"]
    reason: str = Field(min_length=10, max_length=140)
    isPublic: bool = True

    @field_validator("reason", mode="before")
    @classmethod
    def trim(cls, value):
        return value.strip() if isinstance(value, str) else value


class CheckInInput(Input):
    latitude: float | None = Field(default=None, ge=-90, le=90, allow_inf_nan=False)
    longitude: float | None = Field(default=None, ge=-180, le=180, allow_inf_nan=False)


class RedeemInput(Input):
    optionID: str = Field(min_length=1, max_length=100)
    amount: int | None = Field(default=None, ge=1, le=100000, strict=True)
