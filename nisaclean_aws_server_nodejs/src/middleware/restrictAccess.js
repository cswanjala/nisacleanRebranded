module.exports = (req, res, next) => {
    const allowOrigins = [
      "http://localhost:3000",
      "http://localhost:3001",
      "https://nisaclean.com",
    ]; // add your own domains here
    // uncomment before deployment
    // if (!allowOrigins.includes(req.headers["origin"])) {
    //   return res.status(401).json({
    //     message: "Not Authenticated",
    //   });
    // }

    next();
  };
