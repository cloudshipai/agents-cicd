# Express Middleware System (TypeScript)

This example demonstrates a production-ready Express.js middleware stack with:

- Security (helmet, CORS, HPP) and rate limiting
- Request logging with correlation IDs (pino + AsyncLocalStorage)
- Centralized error handling (with Zod validation errors)
- Input validation using Zod
- Graceful shutdown
- Comprehensive tests with Vitest + Supertest

## Quick start

- Install dependencies

```
cd examples
npm i
```

- Run tests

```
npm test
```

- Start dev server

```
npm run dev
```

- Build + run

```
npm run build && npm start
```

## Environment

See `.env.example` for available variables.

## Project Layout

- src/middleware/security.ts – helmet, cors, hpp, rate limiter
- src/middleware/logging.ts – correlation IDs + pino-http
- src/middleware/error.ts – AppError, 404 + centralized error handler
- src/middleware/validation.ts – zod-based validator factory
- src/server.ts – server wiring + graceful shutdown
- test/* – integration tests

## Notes

- Correlation IDs are attached to request and response header `x-correlation-id`.
- The logger automatically includes correlationId on all log lines.
- Rate limiting applies to `/api/*` paths. Configure via env vars.