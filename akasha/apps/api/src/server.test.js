import { afterEach, describe, expect, it } from 'vitest';

import { buildServer } from './server.js';

describe('server', () => {
  let app;

  afterEach(async () => {
    if (app) {
      await app.close();
      app = undefined;
    }
  });

  it('serves healthz', async () => {
    app = buildServer();
    const response = await app.inject({ method: 'GET', url: '/healthz' });

    expect(response.statusCode).toBe(200);
    expect(response.json()).toMatchObject({ ok: true, service: 'akasha-api' });
  });

  it('serves nodes', async () => {
    app = buildServer();
    const response = await app.inject({ method: 'GET', url: '/nodes' });

    expect(response.statusCode).toBe(200);
    expect(response.json()).toMatchObject({
      nodes: [
        {
          id: 'sample-node',
          state: { color: 'green' }
        }
      ]
    });
  });

  it('handles effect failure as 500', async () => {
    app = buildServer();
    const response = await app.inject({ method: 'GET', url: '/nodes?fail=1' });

    expect(response.statusCode).toBe(500);
    expect(response.json()).toEqual({ ok: false, error: 'forced_failure' });
  });
});
