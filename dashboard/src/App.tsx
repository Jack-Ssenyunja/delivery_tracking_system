import { useState } from "react";
import { useDeliveries } from "./hooks/useDeliveries";
import { DeliveryList } from "./components/DeliveryList";
import { DeliveryMap } from "./components/DeliveryMap";
import { Timeline } from "./components/Timeline";
import { formatEta } from "./types";
import "./App.css";

function App() {
  const { deliveries, loading, connected, timeline } = useDeliveries();
  const [selectedId, setSelectedId] = useState<string | null>(null);

  const selected =
    deliveries.find((d) => d.id === selectedId) ?? deliveries[0] ?? null;

  if (loading) {
    return <div className="loading">Loading deliveries…</div>;
  }

  return (
    <div className="app">
      <header className="header">
        <div>
          <h1>Delivery Dashboard</h1>
          <p className="subtitle">Live tracking &amp; status management</p>
        </div>
        <div className={`ws-status ${connected ? "connected" : "disconnected"}`}>
          {connected ? "● Live" : "○ Reconnecting…"}
        </div>
      </header>

      <main className="main">
        <aside className="sidebar">
          <DeliveryList
            deliveries={deliveries}
            selectedId={selected?.id ?? null}
            onSelect={setSelectedId}
          />
        </aside>

        <section className="map-section">
          {selected ? (
            <>
              <div className="map-header">
                <h2>{selected.destination.label}</h2>
                <span className="live-eta">
                  ETA: {formatEta(selected.eta_seconds)}
                </span>
              </div>
              <div className="map-container">
                <DeliveryMap delivery={selected} />
              </div>
            </>
          ) : (
            <div className="empty-state">No deliveries to show</div>
          )}
        </section>

        <aside className="timeline-panel">
          <Timeline events={timeline} />
        </aside>
      </main>
    </div>
  );
}

export default App;
