import type { WsEvent } from "../types";

interface Props {
  events: WsEvent[];
}

const EVENT_LABELS: Record<string, string> = {
  "delivery.status_changed": "Status changed",
  "delivery.eta_updated": "ETA updated",
  "rider.location_updated": "Location updated",
};

export function Timeline({ events }: Props) {
  return (
    <div className="timeline">
      <h2>Live Events</h2>
      {events.length === 0 && (
        <p className="empty">Waiting for events…</p>
      )}
      {events.map((e, i) => (
        <div key={`${e.type}-${e.timestamp}-${i}`} className="timeline-item">
          <span className="timeline-type">
            {EVENT_LABELS[e.type] ?? e.type}
          </span>
          <span className="timeline-detail">
            {e.deliveryId}
            {e.status && ` → ${e.status}`}
            {e.etaSeconds !== undefined && ` (${Math.round(e.etaSeconds)}s)`}
          </span>
          {e.timestamp && (
            <span className="timeline-time">
              {new Date(e.timestamp).toLocaleTimeString()}
            </span>
          )}
        </div>
      ))}
    </div>
  );
}
