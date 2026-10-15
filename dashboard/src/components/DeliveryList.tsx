import type { Delivery } from "../types";
import {
  STATUS_COLORS,
  STATUS_LABELS,
  formatEta,
} from "../types";

interface Props {
  deliveries: Delivery[];
  selectedId: string | null;
  onSelect: (id: string) => void;
}

export function DeliveryList({ deliveries, selectedId, onSelect }: Props) {
  return (
    <div className="delivery-list">
      <h2>Deliveries</h2>
      {deliveries.map((d) => (
        <button
          key={d.id}
          className={`delivery-card ${selectedId === d.id ? "selected" : ""}`}
          onClick={() => onSelect(d.id)}
        >
          <div className="delivery-card-header">
            <span className="delivery-id">{d.id}</span>
            <span
              className="status-badge"
              style={{ background: STATUS_COLORS[d.status] }}
            >
              {STATUS_LABELS[d.status]}
            </span>
          </div>
          <div className="delivery-card-body">
            <p>{d.destination.label ?? "Destination"}</p>
            <p className="eta">ETA: {formatEta(d.eta_seconds)}</p>
          </div>
        </button>
      ))}
    </div>
  );
}
