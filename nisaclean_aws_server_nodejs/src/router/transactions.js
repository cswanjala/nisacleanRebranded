const express = require("express");
const router = express.Router();

const {
  refundClientFromEscrow,
  requestDeposit,
  transferBetweenWallets,
  adminTopUpWallet,
  getWalletBalance,
  adminReleaseEscrow,
  requestPaymentRoute,
  releaseFundsRoute,
} = require("../controllers/transactionsController");

router.route("/wallet/balance").get(getWalletBalance);

router.route("/deposit/request").post(requestDeposit);
router.route("/payment/request").post(requestPaymentRoute);
router.route("/wallet/transfer").post(transferBetweenWallets);
router.route("/wallet/topup").post(adminTopUpWallet);

router.route("/escrow/release").post(releaseFundsRoute);
router.route("/escrow/refund").post(refundClientFromEscrow);
router.route("/escrow/admin-release").patch(adminReleaseEscrow);

module.exports = router;
