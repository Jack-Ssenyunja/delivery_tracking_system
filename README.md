# Delivery Tracking Prototype

Real-time delivery tracking MVP built per the project spec:

- **Backend** — Python + FastAPI (REST + WebSockets)
- **Mobile** — Flutter (Rider + Customer roles in one app)
- **Dashboard** — React + TypeScript (live map, ETA, timeline)

## Demo Delivery

| Field | Value |
|-------|-------|
| Delivery ID | `delivery-001` |
| Rider | Alex Mwangi (`rider-001`) |
| Customer | Jane Wanjiku (`customer-001`) |
| Origin | Warehouse - Kimathi Street, Nairobi |
| Destination | Customer - Kenyatta Avenue, Nairobi |

## Quick Start

### 1. Backend

```bash
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
```

API docs: http://localhost:8000/docs

### 2. Dashboard

```bash
cd dashboard
npm install
npm run dev
```

Open http://localhost:5173

### 3. Mobile App

```bash
cd mobile
flutter pub get
flutter run
```

For Android emulator, pass the host machine IP:

```bash
flutter run --dart-define=API_URL=http://10.0.2.2:8000
```

## Demo Script

See [DEMO_CHECKLIST.md](./DEMO_CHECKLIST.md) for the step-by-step walkthrough.

1. Open the **dashboard** — delivery shows as PENDING
2. Open **Flutter app** → choose **Rider**
3. Tap **Accept Delivery** → status becomes ASSIGNED
4. Tap **Start Trip** → rider simulation begins, ETA updates live
5. Watch **dashboard** — map marker moves, timeline fills with events
6. Rider taps **Confirm Handover** → HANDOVER_CONFIRMED
7. Open **Customer** role → tap **Confirm Received**
8. Dashboard shows RECEIVED — demo complete ✅

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/deliveries` | List all deliveries |
| GET | `/deliveries/active` | Active deliveries |
| POST | `/deliveries/{id}/accept` | Rider accepts |
| POST | `/deliveries/{id}/start` | Start trip (EN_ROUTE) |
| POST | `/deliveries/{id}/handover` | Confirm handover |
| POST | `/deliveries/{id}/received` | Customer confirms |
| POST | `/location-ping` | Rider location update |
| WS | `/ws` | Realtime events |

## WebSocket Events

- `delivery.status_changed` — status transition
- `delivery.eta_updated` — new ETA in seconds
- `rider.location_updated` — lat/lng update

## Project Structure

```
delivery project/
├── backend/          # FastAPI + state machine + WebSocket
├── dashboard/        # React management dashboard
├── mobile/           # Flutter rider/customer app
├── DEMO_CHECKLIST.md # Demo walkthrough
└── README.md
```

## Later: SAP ByD Integration

When ready, swap mock seed data in `backend/seed_data.json` with SAP ByD API fetch — the rest of the architecture stays the same.
