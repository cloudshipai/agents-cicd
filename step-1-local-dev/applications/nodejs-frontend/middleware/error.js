const { logger } = require('../logger');

const notFound = (req, res, next) => {
  const error = new Error(`Not Found - ${req.originalUrl}`);
  error.status = 404;
  next(error);
};

const errorHandler = (err, req, res, next) => {
  const status = err.status || err.statusCode || 500;
  const message = err.message || 'Internal Server Error';

  logger.error({
    err,
    req: {
      method: req.method,
      url: req.url,
      headers: req.headers,
      body: req.body
    },
    status
  }, message);

  if (req.xhr || req.get('Content-Type') === 'application/json') {
    return res.status(status).json({
      error: message,
      status,
      ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
    });
  }

  res.status(status).render('error', {
    error: message,
    status,
    stack: process.env.NODE_ENV === 'development' ? err.stack : null
  });
};

module.exports = { notFound, errorHandler };