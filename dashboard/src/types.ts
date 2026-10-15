export const API_BASE = "http://localhost:8000";
export const WS_URL = "ws://localhost:8000/ws";

export type DeliveryStatus =
  | "PENDING"
  | "ASSIGNED"
  | "EN_ROUTE"
  | "HANDOVER_CONFIRMED"
  | "RECEIVED";

export interface Location {
  lat: number;
  lng: number;
  label?: string;
}

export interface DeliveryEvent {
  id: string;
  delivery_id: string;
  type: string;
  status?: DeliveryStatus;
  message: string;
  timestamp: string;
}

export interface Delivery {
  id: string;
  rider_id: string;
  customer_id: string;
  status: DeliveryStatus;
  origin: Location;
  destination: Location;
  current_location: Location | null;
  eta_seconds: number | null;
  notes: string | null;
  events: DeliveryEvent[];
  assumed_speed_mps: number;
}

export interface WsEvent {
  type: string;
  deliveryId: string;
  status?: DeliveryStatus;
  etaSeconds?: number;
  lat?: number;
  lng?: number;
  riderId?: string;
  message?: string;
  timestamp?: string;
}

export const STATUS_COLORS: Record<DeliveryStatus, string> = {
  PENDING: "#94a3b8",
  ASSIGNED: "#3b82f6",
  EN_ROUTE: "#f59e0b",
  HANDOVER_CONFIRMED: "#8b5cf6",
  RECEIVED: "#22c55e",
};

export const STATUS_LABELS: Record<DeliveryStatus, string> = {
  PENDING: "Pending",
  ASSIGNED: "Assigned",
  EN_ROUTE: "En Route",
  HANDOVER_CONFIRMED: "Handover Confirmed",
  RECEIVED: "Received",
};

export function formatEta(seconds: number | null): string {
  if (seconds === null) return "—";
  if (seconds < 60) return `${Math.round(seconds)}s`;
  const mins = Math.floor(seconds / 60);
  const secs = Math.round(seconds % 60);
  return `${mins}m ${secs}s`;
}
