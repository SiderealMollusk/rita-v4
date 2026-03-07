import { beforeEach, describe, expect, it, vi } from 'vitest';
import { Effect } from 'effect';

import { fetchHealth } from './health-client.js';

describe('fetchHealth', () => {
  beforeEach(() => {
    vi.restoreAllMocks();
  });

  it('returns parsed json for ok responses', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn().mockResolvedValue({
        ok: true,
        json: async () => ({ ok: true, service: 'akasha-api' })
      })
    );

    await expect(Effect.runPromise(fetchHealth('/x'))).resolves.toEqual({
      ok: true,
      service: 'akasha-api'
    });
  });

  it('throws for non-ok responses', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn().mockResolvedValue({
        ok: false,
        status: 503
      })
    );

    await expect(Effect.runPromise(fetchHealth('/x'))).rejects.toThrow('health_request_failed:503');
  });

  it('normalizes non-error rejection values', async () => {
    vi.stubGlobal('fetch', vi.fn().mockRejectedValue('bad-network'));

    await expect(Effect.runPromise(fetchHealth('/x'))).rejects.toThrow(
      'health_request_failed:bad-network'
    );
  });
});
