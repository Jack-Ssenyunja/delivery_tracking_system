import json
from pathlib import Path
from datetime import datetime
from typing import Optional

from app.models import Delivery, DeliveryStatus, Rider, Customer, Location
from app.state_machine import DeliveryStateMachine, compute_eta_seconds


class DeliveryStore:
    """In-memory delivery store seeded from JSON."""

    def __init__(self, seed_path: Path):
        self.deliveries: dict[str, Delivery] = {}
        self.riders: dict[str, Rider] = {}
        self.customers: dict[str, Customer] = {}
        self._state_machine: Optional[DeliveryStateMachine] = None
        self._load_seed(seed_path)

    def set_state_machine(self, sm: DeliveryStateMachine) -> None:
        self._state_machine = sm

    def _load_seed(self, seed_path: Path) -> None:
        with open(seed_path) as f:
            data = json.load(f)

        for r in data.get("riders", []):
            self.riders[r["id"]] = Rider(**r)

        for c in data.get("customers", []):
            self.customers[c["id"]] = Customer(**c)

        for d in data.get("deliveries", []):
            delivery = Delivery(
                id=d["id"],
                rider_id=d["rider_id"],
                customer_id=d["customer_id"],
                origin=Location(**d["origin"]),
                destination=Location(**d["destination"]),
                notes=d.get("notes"),
                assumed_speed_mps=d.get("assumed_speed_mps", 5.0),
                status=DeliveryStatus.PENDING,
                current_location=Location(**d["origin"]),
            )
            delivery.eta_seconds = compute_eta_seconds(
                delivery.current_location,
                delivery.destination,
                delivery.assumed_speed_mps,
            )
            self.deliveries[delivery.id] = delivery

    def get(self, delivery_id: str) -> Optional[Delivery]:
        return self.deliveries.get(delivery_id)

    def list_active(self) -> list[Delivery]:
        return [
            d for d in self.deliveries.values()
            if d.status != DeliveryStatus.RECEIVED
        ]

    def list_all(self) -> list[Delivery]:
        return list(self.deliveries.values())

    async def accept(self, delivery_id: str) -> Delivery:
        delivery = self._require(delivery_id)
        await self._state_machine.transition(
            delivery, DeliveryStatus.ASSIGNED, "Rider accepted delivery"
        )
        return delivery

    async def start_trip(self, delivery_id: str) -> Delivery:
        delivery = self._require(delivery_id)
        await self._state_machine.transition(
            delivery, DeliveryStatus.EN_ROUTE, "Rider started trip"
        )
        return delivery

    async def handover(self, delivery_id: str) -> Delivery:
        delivery = self._require(delivery_id)
        await self._state_machine.transition(
            delivery, DeliveryStatus.HANDOVER_CONFIRMED, "Rider confirmed handover"
        )
        return delivery

    async def received(self, delivery_id: str) -> Delivery:
        delivery = self._require(delivery_id)
        await self._state_machine.transition(
            delivery, DeliveryStatus.RECEIVED, "Customer confirmed receipt"
        )
        return delivery

    async def location_ping(
        self, delivery_id: str, rider_id: str, lat: float, lng: float
    ) -> Delivery:
        delivery = self._require(delivery_id)
        if delivery.rider_id != rider_id:
            raise ValueError("Rider does not match this delivery")
        if delivery.status not in (DeliveryStatus.ASSIGNED, DeliveryStatus.EN_ROUTE):
            raise ValueError(f"Cannot ping location in status {delivery.status.value}")

        await self._state_machine.update_location(delivery, lat, lng, rider_id)
        return delivery

    def _require(self, delivery_id: str) -> Delivery:
        delivery = self.get(delivery_id)
        if not delivery:
            raise KeyError(f"Delivery {delivery_id} not found")
        return delivery
