const express = require("express");
const admin = require("../controllers/adminController.js");
const { isAuthenticated, isAdmin } = require("../middleware/auth");
const router = express.Router();

// get
router
  .route("/makeUserAdmin/:id")
  .get(isAuthenticated, isAdmin, admin.makeUserAdmin);
router
  .route("/approveService/:id/:status")
  .get(isAuthenticated, isAdmin, admin.updateProviderStatus);
router
  .route("/approveUser/:id/:delete")
  .get(isAuthenticated, isAdmin, admin.deleteUserById);

router.route("/generalStats").get(isAuthenticated, isAdmin, admin.generalStats);

module.exports = router;
