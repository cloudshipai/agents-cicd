const { cleanEnv, str, port, url, bool } = require('envalid');

const config = cleanEnv(process.env, {
  NODE_ENV: str({ choices: ['development', 'production', 'test'], default: 'development' }),
  PORT: port({ default: 3000 }),
  API_URL: url({ default: 'http://flask-api:5000' }),
  LOG_LEVEL: str({ choices: ['fatal', 'error', 'warn', 'info', 'debug', 'trace'], default: 'info' }),
  TRUST_PROXY: bool({ default: false }),
  CORS_ORIGIN: str({ default: '*' }),
  RATE_LIMIT_WINDOW_MS: str({ default: '900000' }),
  RATE_LIMIT_MAX_REQUESTS: str({ default: '100' }),
  REQUEST_TIMEOUT_MS: str({ default: '30000' }),
  BODY_LIMIT: str({ default: '10mb' })
});

module.exports = config;