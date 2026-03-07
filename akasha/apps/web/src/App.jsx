// @flow
import React from 'react';
import { useEffect, useMemo, useState } from 'react';
import { Effect } from 'effect';
import ReactFlow, { Background, Controls } from 'reactflow';
import 'reactflow/dist/style.css';

import { fetchHealth } from './health-client.js';
import { colorForState } from './status-light.js';

export default function App({ loadHealth = fetchHealth }) {
  const [status, setStatus] = useState({ phase: 'loading', message: 'Loading health...' });

  useEffect(() => {
    let cancelled = false;

    Effect.runPromise(loadHealth())
      .then((payload) => {
        if (!cancelled) {
          setStatus({ phase: 'ready', message: `API: ${payload.service}` });
        }
      })
      .catch((error) => {
        if (!cancelled) {
          setStatus({ phase: 'error', message: error.message });
        }
      });

    return () => {
      cancelled = true;
    };
  }, [loadHealth]);

  const lightState = status.phase === 'ready' ? 'green' : status.phase === 'error' ? 'red' : 'unknown';
  const lightColor = colorForState(lightState);

  const nodes = useMemo(
    () => [
      {
        id: 'sample-node',
        position: { x: 120, y: 80 },
        data: {
          label: (
            <div title="Node turns green only when health checks and reducer conditions pass.">
              <strong>sample-node</strong>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 6 }}>
                <span
                  aria-label="status-light"
                  style={{
                    width: 12,
                    height: 12,
                    borderRadius: 999,
                    display: 'inline-block',
                    backgroundColor: lightColor
                  }}
                />
                <span>{status.message}</span>
              </div>
            </div>
          )
        }
      }
    ],
    [lightColor, status.message]
  );

  return (
    <main style={{ width: '100vw', height: '100vh' }}>
      <ReactFlow nodes={nodes} edges={[]} fitView>
        <Background />
        <Controls />
      </ReactFlow>
    </main>
  );
}
