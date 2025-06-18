const express = require("express");
const walletController = require("../controllers/walletController");

const router = express.Router();
router.route("/get-balance").get(walletController.getWalletBalance);

module.exports = router;
