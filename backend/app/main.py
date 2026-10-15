from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware

from app.deps import store
from app.routers import deliveries, location, ws


@asynccontextmanager
async def lifespan(app: FastAPI):
    yield


app = FastAPI(
    title="Delivery Tracking API",
    description="Real-time delivery tracking prototype",
    version="0.1.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(deliveries.router)
app.include_router(location.router)
app.include_router(ws.router)


@app.get("/health")
async def health():
    return {"status": "ok", "deliveries": len(store.deliveries)}


@app.get("/riders/{rider_id}")
async def get_rider(rider_id: str):
    rider = store.riders.get(rider_id)
    if not rider:
        raise HTTPException(404, "Rider not found")
    return rider.model_dump()


@app.get("/customers/{customer_id}")
async def get_customer(customer_id: str):
    customer = store.customers.get(customer_id)
    if not customer:
        raise HTTPException(404, "Customer not found")
    return customer.model_dump()
