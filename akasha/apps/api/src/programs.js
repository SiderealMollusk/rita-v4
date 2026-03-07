import { Effect } from 'effect';

import { computeNodeState } from '@akasha/reducer';

export function healthProgram(options = {}) {
  return Effect.succeed({
    ok: true,
    service: 'akasha-api',
    ts: options.now ?? new Date().toISOString()
  });
}

export function nodesProgram(options = {}) {
  if (options.fail === true) {
    return Effect.fail(new Error('forced_failure'));
  }

  const state = computeNodeState({
    checks: [{ id: 'http', ok: true }],
    docsPass: true,
    reachable: true
  });

  return Effect.succeed({
    nodes: [
      {
        id: 'sample-node',
        state
      }
    ]
  });
}
