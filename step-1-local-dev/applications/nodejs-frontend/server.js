require('dotenv').config();

const express = require('express');
const path = require('path');
const { body, validationResult } = require('express-validator');

const config = require('./config');
const { logger, httpLogger } = require('./logger');
const { setupSecurity } = require('./middleware/security');
const { notFound, errorHandler } = require('./middleware/error');
const apiClient = require('./lib/apiClient');

const app = express();

app.use(httpLogger);

setupSecurity(app);

app.use(express.static('public'));
app.set('view engine', 'ejs');

app.use((req, res, next) => {
  res.locals.req = req;
  next();
});

const validateUserInput = [
  body('username').trim().isLength({ min: 3, max: 50 }).withMessage('Username must be 3-50 characters'),
  body('email').isEmail().normalizeEmail().withMessage('Valid email is required'),
  body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters')
];

app.get('/', async (req, res, next) => {
  try {
    const response = await apiClient.get('/users');
    res.render('index', { 
      users: response.data,
      apiStatus: 'connected' 
    });
  } catch (error) {
    logger.warn({ err: error }, 'Failed to fetch users from API');
    res.render('index', { 
      users: [],
      apiStatus: 'disconnected',
      error: error.response?.data?.error || error.message 
    });
  }
});

app.get('/create', (req, res) => {
  res.render('create-user');
});

app.post('/users', validateUserInput, async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.render('create-user', { 
        error: errors.array()[0].msg,
        formData: req.body 
      });
    }

    const { username, email, password } = req.body;
    
    const response = await apiClient.post('/users', {
      username,
      email, 
      password
    });
    
    logger.info({ username, email }, 'User created successfully');
    res.redirect('/?success=User created successfully');
  } catch (error) {
    const errorMessage = error.response?.data?.error || error.message;
    logger.warn({ err: error, formData: req.body }, 'Failed to create user');
    res.render('create-user', { 
      error: errorMessage,
      formData: req.body 
    });
  }
});

app.get('/health', async (req, res) => {
  try {
    const apiHealth = await apiClient.get('/health');
    res.json({
      frontend: 'healthy',
      api: apiHealth.data,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(503).json({
      frontend: 'healthy',
      api: 'unreachable',
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

app.use(notFound);
app.use(errorHandler);

const server = app.listen(config.PORT, '0.0.0.0', () => {
  logger.info({
    port: config.PORT,
    env: config.NODE_ENV,
    apiUrl: config.API_URL
  }, 'Frontend server started');
});

server.keepAliveTimeout = 61000;
server.headersTimeout = 62000;

const gracefulShutdown = (signal) => {
  logger.info({ signal }, 'Received shutdown signal');
  
  server.close((err) => {
    if (err) {
      logger.error({ err }, 'Error during server shutdown');
      process.exit(1);
    }
    
    logger.info('Server closed gracefully');
    process.exit(0);
  });

  setTimeout(() => {
    logger.error('Forced shutdown after timeout');
    process.exit(1);
  }, 10000);
};

process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));

process.on('uncaughtException', (err) => {
  logger.fatal({ err }, 'Uncaught exception');
  process.exit(1);
});

process.on('unhandledRejection', (reason, promise) => {
  logger.fatal({ reason, promise }, 'Unhandled promise rejection');
  process.exit(1);
});