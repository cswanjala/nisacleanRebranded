const Wallet = require("../models/Transactions/WalletSchema");
const ErrorHandler = require("../utils/ErrorHandler");
const SuccessHandler = require("../utils/SuccessHandler");

const getWalletBalance = async (req, res) => {
  // #swagger.tags = ['wallet']
  try {
    const { userId } = req.body;

    const wallet = await Wallet.findOne({ user: userId });

    if (!wallet) {
      return ErrorHandler("Wallet not found", 404, req, res);
    }

    return SuccessHandler("Wallet balance retrieved", 200, res, {
      userId,
      balance: wallet.balance,
    });
  } catch (error) {
    return ErrorHandler(error.message, 500, req, res);
  }
};

module.exports = {
  getWalletBalance,
};
