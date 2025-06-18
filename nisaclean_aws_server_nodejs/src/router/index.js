const router = require("express").Router();
const auth = require("./auth");
const admin = require("./admin");
const booking = require("./booking");
const notification = require("./notification");
const safaricom = require("./safaricom");
const report = require("./report");
const revenue = require("./revenue");
const wallet = require("./wallet");
const transaction = require("./transactions");

// Mount all routes with their prefixes
router.use("/auth", auth);
router.use("/admin", admin);
router.use("/notification", notification);
router.use("/safaricom", safaricom);
router.use("/reports", report);
router.use("/revenue", revenue);
router.use("/wallet", wallet);
router.use("/transaction", transaction);
router.use("/booking", booking);

module.exports = router;
