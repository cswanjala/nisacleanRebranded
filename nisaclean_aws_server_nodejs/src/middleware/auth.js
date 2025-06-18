const jwt = require("jsonwebtoken");
const User = require("../models/User/user");
const dotenv = require("dotenv");

dotenv.config({ path: ".././src/config/config.env" });

const isAuthenticated = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    console.log('Auth header:', authHeader);
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ success: false, message: "Not logged in" });
    }
    
    const token = authHeader.substring(7); // Remove 'Bearer ' prefix
    console.log('Extracted token:', token);
    
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    console.log('Decoded token:', decoded);
    
    req.user = await User.findById(decoded._id);
    if (!req.user) {
      return res
        .status(401)
        .json({ success: false, message: "User not found" });
    }
    
    console.log('User found:', req.user.name, req.user.role);
    next();
  } catch (error) {
    console.error('Auth error:', error.message);
    res.status(401).json({ success: false, message: "Invalid token" });
  }
};

const isAdmin = async (req, res, next) => {
  try {
    if (req.user.role !== "admin") {
      return res
        .status(403)
        .json({ success: false, message: "Not authorized as an admin" });
    }
    next();
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

const isWorker = async (req, res, next) => {
  try {
    if (req.user.role !== "worker") {
      return res
        .status(403)
        .json({ success: false, message: "Not authorized as a worker" });
    }
    next();
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

const isClient = async (req, res, next) => {
  try {
    if (req.user.role !== "client") {
      return res
        .status(403)
        .json({ success: false, message: "Not authorized as a client" });
    }
    next();
  } catch (error) {
    console.log(error);
    res.status(500).json({ success: false, message: error.message });
  }
};

module.exports = { isAuthenticated, isAdmin, isWorker, isClient };
