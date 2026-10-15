from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from app.deps import store


router = APIRouter(prefix="/deliveries", tags=["deliveries"])


class DeliveryResponse(BaseModel):
    id: str
    rider_id: str
    customer_id: str
    status: str
    origin: dict
    destination: dict
    current_location: dict | None
    eta_seconds: float | None
    notes: str | None
    events: list[dict]
    assumed_speed_mps: float


def _to_response(d) -> DeliveryResponse:
    return DeliveryResponse(
        id=d.id,
        rider_id=d.rider_id,
        customer_id=d.customer_id,
        status=d.status.value,
        origin=d.origin.model_dump(),
        destination=d.destination.model_dump(),
        current_location=d.current_location.model_dump() if d.current_location else None,
        eta_seconds=d.eta_seconds,
        notes=d.notes,
        events=[e.model_dump() for e in d.events],
        assumed_speed_mps=d.assumed_speed_mps,
    )


@router.get("")
async def list_deliveries():
    return [_to_response(d) for d in store.list_all()]


@router.get("/active")
async def list_active_deliveries():
    return [_to_response(d) for d in store.list_active()]


@router.get("/{delivery_id}")
async def get_delivery(delivery_id: str):
    delivery = store.get(delivery_id)
    if not delivery:
        raise HTTPException(404, "Delivery not found")
    return _to_response(delivery)


@router.post("/{delivery_id}/accept")
async def accept_delivery(delivery_id: str):
    try:
        delivery = await store.accept(delivery_id)
        return _to_response(delivery)
    except KeyError:
        raise HTTPException(404, "Delivery not found")
    except ValueError as e:
        raise HTTPException(400, str(e))


@router.post("/{delivery_id}/start")
async def start_trip(delivery_id: str):
    try:
        delivery = await store.start_trip(delivery_id)
        return _to_response(delivery)
    except KeyError:
        raise HTTPException(404, "Delivery not found")
    except ValueError as e:
        raise HTTPException(400, str(e))


@router.post("/{delivery_id}/handover")
async def confirm_handover(delivery_id: str):
    try:
        delivery = await store.handover(delivery_id)
        return _to_response(delivery)
    except KeyError:
        raise HTTPException(404, "Delivery not found")
    except ValueError as e:
        raise HTTPException(400, str(e))


@router.post("/{delivery_id}/received")
async def confirm_received(delivery_id: str):
    try:
        delivery = await store.received(delivery_id)
        return _to_response(delivery)
    except KeyError:
        raise HTTPException(404, "Delivery not found")
    except ValueError as e:
        raise HTTPException(400, str(e))
