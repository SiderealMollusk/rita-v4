// @flow
import { Effect } from 'effect';

export function fetchHealth(baseUrl = '/api') {
  return Effect.tryPromise({
    try: async () => {
      const response = await fetch(`${baseUrl}/healthz`);
      if (!response.ok) {
        throw new Error(`health_request_failed:${response.status}`);
      }
      return response.json();
    },
    catch: (error) =>
      error instanceof Error ? error : new Error(`health_request_failed:${String(error)}`)
  });
}
