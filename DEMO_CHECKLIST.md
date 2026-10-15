# Demo Checklist — Delivery Tracking MVP

Use this as a clickable walkthrough during the demo.

## Setup (before demo)

- [ ] Backend running on port 8000
- [ ] Dashboard open at http://localhost:5173
- [ ] Flutter app open (Rider role ready)
- [ ] WebSocket indicator on dashboard shows **● Live**

---

## Demo Flow

### Step 1 — Dashboard baseline
- [ ] Dashboard shows `delivery-001` with status **PENDING**
- [ ] Map shows origin + destination markers
- [ ] ETA displayed (~2–3 min at rest)

### Step 2 — Rider accepts
- [ ] Rider app: tap **Accept Delivery**
- [ ] Status badge → **ASSIGNED**
- [ ] Dashboard updates in realtime (status badge + timeline event)

### Step 3 — Rider starts trip
- [ ] Rider app: tap **Start Trip**
- [ ] Status → **EN_ROUTE**
- [ ] "Simulating movement…" appears on rider app
- [ ] Location pings sent every 2 seconds

### Step 4 — Live tracking
- [ ] Dashboard map marker moves toward destination
- [ ] ETA counts down live
- [ ] Timeline shows `location_updated` and `eta_updated` events

### Step 5 — Handover
- [ ] Rider app: tap **Confirm Handover** (when near destination or anytime)
- [ ] Status → **HANDOVER_CONFIRMED**
- [ ] Movement simulation stops

### Step 6 — Customer confirms
- [ ] Switch to **Customer** role in Flutter app
- [ ] Tap **Confirm Received**
- [ ] Status → **RECEIVED**

### Step 7 — Complete
- [ ] Dashboard shows green **Received** badge
- [ ] Timeline shows full state progression:
  - PENDING → ASSIGNED → EN_ROUTE → HANDOVER_CONFIRMED → RECEIVED

---

## Reset for re-demo

Restart the backend server to reset in-memory state:

```bash
# Ctrl+C the running server, then:
uvicorn app.main:app --reload --port 8000
```
