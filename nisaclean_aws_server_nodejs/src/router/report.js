const express = require("express");
const router = express.Router();
const report = require("../controllers/reportsController");

// Range report
router.route("/range")
    .get((req, res, next) => {
        console.log("Route /reports/range hit", req.query);
        next();
    }, report.generateReportByRange);

// Missing reports - handle both GET and POST
router.route("/missing")
    .get(async (req, res) => {
        console.log("GET /reports/missing called");
        try {
            const result = await report.generateMissingReports();
            res.json({
                success: true,
                message: "Missing reports generated successfully",
                details: result,
            });
        } catch (err) {
            console.error("Error generating missing reports:", err);
            res.status(500).json({
                success: false,
                message: "Error generating missing reports",
                error: err.message,
            });
        }
    })
    .post(async (req, res) => {
        console.log("POST /reports/missing called");
        try {
            const result = await report.generateMissingReports();
            res.json({
                success: true,
                message: "Missing reports generated successfully",
                details: result,
            });
        } catch (err) {
            console.error("Error generating missing reports:", err);
            res.status(500).json({
                success: false,
                message: "Error generating missing reports",
                error: err.message,
            });
        }
    });

// Regenerate all reports
router.route("/regenerate-all")
    .get(async (req, res) => {
        console.log("GET /reports/regenerate-all called");
        try {
            await report.regenerateAllReports();
            res.json({
                success: true,
                message: "All reports regenerated successfully",
            });
        } catch (err) {
            console.error("Error regenerating reports:", err);
            res.status(500).json({
                success: false,
                message: "Error regenerating reports",
                error: err.message,
            });
        }
    })
    .post(async (req, res) => {
        console.log("POST /reports/regenerate-all called");
        try {
            await report.regenerateAllReports();
            res.json({
                success: true,
                message: "All reports regenerated successfully",
            });
        } catch (err) {
            console.error("Error regenerating reports:", err);
            res.status(500).json({
                success: false,
                message: "Error regenerating reports",
                error: err.message,
            });
        }
    });

module.exports = router;
