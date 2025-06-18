const logger = require("../functions/logger");

const ErrorHandler = (message, statusCode, res, req = null) => {
  if (req) {
    logger.error({
      method: req.method,
      url: req.url,
      date: new Date(),
      message,
    });
  } else {
    logger.error({
      date: new Date(),
      message,
    });
  }

  return res.status(statusCode).json({
    success: false,
    message,
  });
};

module.exports = ErrorHandler;
