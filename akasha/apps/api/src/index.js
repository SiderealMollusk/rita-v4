import { buildServer } from './server.js';

const port = Number(process.env.AKASHA_API_PORT ?? 8787);
const host = process.env.AKASHA_API_HOST ?? '0.0.0.0';

const app = buildServer();
app.listen({ port, host });
