import math
from datetime import datetime
from typing import Callable, Awaitable

from app.models import DeliveryStatus, Location, DeliveryEvent


EventCallback = Callable[[dict], Awaitable[None]]

# Valid state transitions
TRANSITIONS: dict[DeliveryStatus, set[DeliveryStatus]] = {
    DeliveryStatus.PENDING: {DeliveryStatus.ASSIGNED},
    DeliveryStatus.ASSIGNED: {DeliveryStatus.EN_ROUTE},
    DeliveryStatus.EN_ROUTE: {DeliveryStatus.HANDOVER_CONFIRMED},
    DeliveryStatus.HANDOVER_CONFIRMED: {DeliveryStatus.RECEIVED},
    DeliveryStatus.RECEIVED: set(),
}


def haversine_distance_m(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    """Distance between two coordinates in meters."""
    r = 6371000
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlambda = math.radians(lng2 - lng1)
    a = math.sin(dphi / 2) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlambda / 2) ** 2
    return 2 * r * math.atan2(math.sqrt(a), math.sqrt(1 - a))


def compute_eta_seconds(current: Location, destination: Location, speed_mps: float) -> float:
    distance = haversine_distance_m(current.lat, current.lng, destination.lat, destination.lng)
    if speed_mps <= 0:
        return 0.0
    return round(distance / speed_mps, 1)


class DeliveryStateMachine:
    def __init__(self, emit_event: EventCallback):
        self._emit = emit_event
        self._event_counter = 0

    def _next_event_id(self) -> str:
        self._event_counter += 1
        return f"evt-{self._event_counter:04d}"

    def can_transition(self, current: DeliveryStatus, target: DeliveryStatus) -> bool:
        return target in TRANSITIONS.get(current, set())

    async def transition(self, delivery, target: DeliveryStatus, message: str) -> None:
        if not self.can_transition(delivery.status, target):
            raise ValueError(
                f"Invalid transition: {delivery.status.value} → {target.value}"
            )

        delivery.status = target
        delivery.updated_at = datetime.utcnow()

        event = DeliveryEvent(
            id=self._next_event_id(),
            delivery_id=delivery.id,
            type="delivery.status_changed",
            status=target,
            message=message,
        )
        delivery.events.append(event)

        await self._emit({
            "type": "delivery.status_changed",
            "deliveryId": delivery.id,
            "status": target.value,
            "message": message,
            "timestamp": event.timestamp.isoformat(),
        })

    async def update_location(
        self, delivery, lat: float, lng: float, rider_id: str
    ) -> None:
        delivery.current_location = Location(lat=lat, lng=lng)
        delivery.eta_seconds = compute_eta_seconds(
            delivery.current_location,
            delivery.destination,
            delivery.assumed_speed_mps,
        )
        delivery.updated_at = datetime.utcnow()

        await self._emit({
            "type": "rider.location_updated",
            "deliveryId": delivery.id,
            "riderId": rider_id,
            "lat": lat,
            "lng": lng,
            "timestamp": datetime.utcnow().isoformat(),
        })

        await self._emit({
            "type": "delivery.eta_updated",
            "deliveryId": delivery.id,
            "etaSeconds": delivery.eta_seconds,
            "timestamp": datetime.utcnow().isoformat(),
        })
