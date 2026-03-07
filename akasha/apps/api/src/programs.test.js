import { describe, expect, it } from 'vitest';
import { Effect } from 'effect';

import { healthProgram, nodesProgram } from './programs.js';

describe('programs', () => {
  it('returns health payload with provided timestamp', async () => {
    await expect(Effect.runPromise(healthProgram({ now: '2026-03-06T00:00:00.000Z' }))).resolves.toEqual({
      ok: true,
      service: 'akasha-api',
      ts: '2026-03-06T00:00:00.000Z'
    });
  });

  it('returns node payload', async () => {
    await expect(Effect.runPromise(nodesProgram())).resolves.toEqual({
      nodes: [
        {
          id: 'sample-node',
          state: {
            color: 'green',
            why: ['all_required_signals_ok'],
            failedChecks: []
          }
        }
      ]
    });
  });

  it('fails when fail flag is true', async () => {
    await expect(Effect.runPromise(nodesProgram({ fail: true }))).rejects.toThrow('forced_failure');
  });
});
