const winston = require('winston');
const path = require('path');

/**
 * Creates a logger instance for a specific module
 * @param {string} moduleName - The name of the module creating the logger
 * @returns {winston.Logger} - A configured logger instance
 */
const createLogger = (moduleName) => {
  const logger = winston.createLogger({
    level: process.env.LOG_LEVEL || 'info',
    format: winston.format.combine(
      winston.format.timestamp(),
      winston.format.json()
    ),
    defaultMeta: { module: moduleName },
    transports: [
      // Write all logs to console
      new winston.transports.Console({
        format: winston.format.combine(
          winston.format.colorize(),
          winston.format.simple()
        ),
      }),
      // Write all logs with level 'error' and below to error.log
      new winston.transports.File({
        filename: path.join('logs', 'error.log'),
        level: 'error',
      }),
      // Write all logs with level 'info' and below to combined.log
      new winston.transports.File({
        filename: path.join('logs', 'combined.log'),
      }),
    ],
  });

  // Create logs directory if it doesn't exist
  const fs = require('fs');
  const logsDir = path.join(process.cwd(), 'logs');
  if (!fs.existsSync(logsDir)) {
    fs.mkdirSync(logsDir);
  }

  return logger;
};

module.exports = {
  createLogger,
}; 