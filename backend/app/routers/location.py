from fastapi import APIRouter, HTTPException
from app.models import LocationPing
from app.deps import store
from app.routers.deliveries import _to_response


router = APIRouter(tags=["location"])


@router.post("/location-ping")
async def location_ping(ping: LocationPing):
    try:
        delivery = await store.location_ping(
            ping.delivery_id, ping.rider_id, ping.lat, ping.lng
        )
        return _to_response(delivery)
    except KeyError:
        raise HTTPException(404, "Delivery not found")
    except ValueError as e:
        raise HTTPException(400, str(e))
