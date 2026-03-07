import Fastify from 'fastify';
import { Effect } from 'effect';

import { healthProgram, nodesProgram } from './programs.js';

async function runProgram(reply, program) {
  try {
    return await Effect.runPromise(program);
  } catch (error) {
    reply.code(500);
    return { ok: false, error: error.message };
  }
}

export function buildServer() {
  const app = Fastify({ logger: false });

  app.get('/healthz', async (_request, reply) => {
    return runProgram(reply, healthProgram());
  });

  app.get('/nodes', async (request, reply) => {
    const fail = request.query?.fail === '1';
    return runProgram(reply, nodesProgram({ fail }));
  });

  return app;
}
