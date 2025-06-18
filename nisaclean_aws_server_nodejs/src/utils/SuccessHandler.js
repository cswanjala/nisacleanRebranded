const SuccessHandler = (message, statusCode, res, data = {}) => {
  return res.status(statusCode).json({
    success: true,
    message,
    data,
  });
};

module.exports = SuccessHandler;
