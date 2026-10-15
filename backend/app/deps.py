from pathlib import Path
from app.store import DeliveryStore
from app.state_machine import DeliveryStateMachine
from app.ws_manager import ConnectionManager

SEED_PATH = Path(__file__).resolve().parent.parent / "seed_data.json"

store = DeliveryStore(SEED_PATH)
manager = ConnectionManager()


async def emit_event(event: dict):
    await manager.broadcast(event)


state_machine = DeliveryStateMachine(emit_event)
store.set_state_machine(state_machine)
