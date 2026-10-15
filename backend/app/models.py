from enum import Enum
from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field


class DeliveryStatus(str, Enum):
    PENDING = "PENDING"
    ASSIGNED = "ASSIGNED"
    EN_ROUTE = "EN_ROUTE"
    HANDOVER_CONFIRMED = "HANDOVER_CONFIRMED"
    RECEIVED = "RECEIVED"


class Location(BaseModel):
    lat: float
    lng: float
    label: Optional[str] = None


class DeliveryEvent(BaseModel):
    id: str
    delivery_id: str
    type: str
    status: Optional[DeliveryStatus] = None
    message: str
    timestamp: datetime = Field(default_factory=datetime.utcnow)


class Delivery(BaseModel):
    id: str
    rider_id: str
    customer_id: str
    origin: Location
    destination: Location
    notes: Optional[str] = None
    assumed_speed_mps: float = 5.0
    status: DeliveryStatus = DeliveryStatus.PENDING
    current_location: Optional[Location] = None
    eta_seconds: Optional[float] = None
    events: list[DeliveryEvent] = Field(default_factory=list)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)


class LocationPing(BaseModel):
    delivery_id: str
    rider_id: str
    lat: float
    lng: float
    timestamp: Optional[datetime] = None


class Rider(BaseModel):
    id: str
    name: str
    phone: str


class Customer(BaseModel):
    id: str
    name: str
    phone: str
