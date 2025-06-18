const express = require("express");
const mpesaController = require("../utils/mpesa");
const { isAdmin } = require("../middleware/auth");

const router = express.Router();

router.route("/stk-push").post(isAdmin, mpesaController.initiateStkPush);

router.route("/callback").post(mpesaController.handleStkCallback);

router
  .route("/check-payment/:transactionId")
  .get(mpesaController.checkPaymentStatus);

module.exports = router;
