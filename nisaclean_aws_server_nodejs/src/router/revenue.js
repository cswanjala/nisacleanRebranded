const express = require("express");
const router = express.Router();
const RevenueController = require("../controllers/revenueContoller");

// Sync revenue - accepts both GET and POST
router.route("/sync")
    .get(RevenueController.getAndSyncRevenue)
    .post(RevenueController.getAndSyncRevenue);

// Get revenue by date range
router.route("/range")
    .get(RevenueController.getRevenueByDateRange);

// Generate yearly report
router.route("/generate-yearly")
    .get(RevenueController.generateYearlyReport);

module.exports = router;
