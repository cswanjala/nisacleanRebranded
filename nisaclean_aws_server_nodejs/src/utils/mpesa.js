const axios = require("axios");
const uuid = require("uuid").v4;
const SuccessHandler = require("./SuccessHandler");
const ErrorHandler = require("./ErrorHandler");
const { createLogger } = require("./logger");
const dotenv = require("dotenv");
const Transaction = require("../models/Transactions/GenTransactions");
const Wallet = require("../models/Transactions/WalletSchema");
const WalletTransaction = require("../models/Transactions/WalletTransaction");

// Load environment variables from config.env
dotenv.config({ path: "./src/config/config.env" });
const logger = createLogger("mpesa-controller");

const ENV = "production";
// M-Pesa API Configuration
const config = {
  sandbox: {
    baseUrl: "https://sandbox.safaricom.co.ke",
    shortcode: process.env.MPESA_SANDBOX_SHORTCODE || "174379",
    passkey: process.env.MPESA_SANDBOX_PASSKEY,
    consumerKey: process.env.MPESA_SANDBOX_CONSUMER_KEY,
    consumerSecret: process.env.MPESA_SANDBOX_CONSUMER_SECRET,
    CallBackURL: process.env.MPESA_C2B_CALLBACK_URL,
  },
  production: {
    baseUrl: "https://api.safaricom.co.ke",
    shortcode: process.env.MPESA_SHORTCODE,
    passkey: process.env.MPESA_PASSKEY,
    consumerKey: process.env.MPESA_CONSUMER_KEY,
    consumerSecret: process.env.MPESA_CONSUMER_SECRET,
    CallBackURL: process.env.MPESA_C2B_CALLBACK_URL,
  },
}[ENV];

// Generate token
const getAccessToken = async () => {
  const auth = Buffer.from(
    `${config.consumerKey}:${config.consumerSecret}`
  ).toString("base64");

  try {
    const res = await axios.get(
      `${config.baseUrl}/oauth/v1/generate?grant_type=client_credentials`,
      {
        headers: { Authorization: `Basic ${auth}` },
      }
    );
    return res.data.access_token;
  } catch (err) {
    console.error("Failed to get access token", err.response?.data || err);
    throw new Error("Token request failed");
  }
};

const formatPhoneNumber = (phone) => phone.replace(/^0/, "254");

// Initiate STK Push
const initiateStkPush = async (
  phonenumber,
  amount,
  accountRef = "Nisafi",
  TransactionDesc = "Deposit to User Account"
) => {
  try {
    // Input validation
    if (!phonenumber || !amount) {
      return ErrorHandler("Phone number, amount are required", 400, req, res);
    }
    const now = new Date();
    const timestamp = now
      .toISOString()
      .replace(/[-T:Z.]/g, "")
      .slice(0, 14);

    const password = Buffer.from(
      config.shortcode + config.passkey + timestamp
    ).toString("base64");

    const minAmount = 2;
    if (amount < minAmount) {
      return ErrorHandler(
        `Amount must be at least ${minAmount} KES`,
        400,
        req,
        res
      );
    }

    const formattedPhone = formatPhoneNumber(phonenumber);
    const accessToken = await getAccessToken();

    const transactionId = uuid();

    // Calculate amounts
    const originalAmount = parseFloat(amount);
    const revenue = originalAmount * 0.2;
    const finalAmount = originalAmount - revenue;

    const payload = {
      BusinessShortCode: config.shortcode,
      Password: password,
      Timestamp: timestamp,
      TransactionType: "CustomerBuyGoodsOnline",
      Amount: amount,
      PartyA: formattedPhone,
      PartyB: "5656420",
      // PartyB: config.shortcode,
      PhoneNumber: formattedPhone,
      CallBackURL: config.CallBackURL,
      AccountReference: accountRef,
      TransactionDesc: TransactionDesc,
    };

    logger.info("Initiating STK Push", {
      amount: originalAmount,
      phoneNumber: formattedPhone,
      shortcode: config.shortcode,
    });

    try {
      logger.info("STK Push request details", {
        url: `${config.baseUrl}/mpesa/stkpush/v1/processrequest`,
        headers: {
          Authorization: `Bearer ${accessToken.substring(0, 10)}...`,
          "Content-Type": "application/json",
        },
        payload: payload,
      });

      const response = await axios.post(
        `${config.baseUrl}/mpesa/stkpush/v1/processrequest`,
        payload,
        {
          headers: {
            Authorization: `Bearer ${accessToken}`,
            "Content-Type": "application/json",
          },
        }
      );
      console.log("STK Push success:", response.data);

      logger.info("STK Push request sent", {
        transactionId,
        url: `${config.baseUrl}/mpesa/stkpush/v1/processrequest`,
        headers: {
          Authorization: "Bearer [REDACTED]",
          "Content-Type": "application/json",
        },
      });

      const responseData = response.data;

      return responseData;
    } catch (axiosError) {
      logger.error("M-Pesa API request failed", {
        transactionId,
        error: axiosError.message,
        response: axiosError.response?.data,
        status: axiosError.response?.status,
        url: axiosError.config?.url,
      });

      // Handle specific M-Pesa error cases
      if (axiosError.response?.status === 400) {
        const errorMessage =
          axiosError.response.data?.errorMessage ||
          axiosError.response.data?.ResponseDescription ||
          "Invalid request to M-Pesa";
        return ErrorHandler(errorMessage, 400, req, res);
      }

      return ErrorHandler(
        "Failed to communicate with M-Pesa service. Please try again later.",
        500,
        req,
        res
      );
    }
  } catch (error) {
    logger.error("Error in initiateStkPush:", error);
    return ErrorHandler(error.message, 500, req, res);
  }
};

const handleStkCallback = async (req, res) => {
  try {
    console.log("Callback URL hit");
    const callback = req.body?.Body?.stkCallback;

    const merchantRequestId = callback?.MerchantRequestID;
    const resultCode = callback?.ResultCode;
    const resultDesc = callback?.ResultDesc;

    // Find the related transaction
    const transaction = await Transaction.findOne({
      referenceId: merchantRequestId,
      type: "deposit",
      status: "pending",
    });

    if (!transaction) {
      console.warn("Transaction not found or already processed.");
      return res.status(404).json({ message: "Transaction not found." });
    }

    // If transaction failed
    if (resultCode !== 0) {
      transaction.status = "failed";
      transaction.notes = resultDesc || "STK push failed";
      await transaction.save();
      return res.status(200).json({ message: "Transaction marked as failed." });
    }

    // Extract amount and phone from metadata
    const metadata = callback?.CallbackMetadata?.Item;
    const amountItem = metadata?.find((item) => item.Name === "Amount");
    const phoneItem = metadata?.find((item) => item.Name === "PhoneNumber");

    const amount = amountItem?.Value;
    const phone = phoneItem?.Value;

    if (!amount || !phone) {
      return res.status(400).json({ message: "Incomplete callback metadata." });
    }

    // Update original transaction
    transaction.status = "success";
    transaction.notes = `Deposit of ${amount} successful from ${phone}`;
    await transaction.save();

    // Credit user's wallet
    const userId = transaction.paidBy;
    let wallet = await Wallet.findOne({ user: userId });

    if (!wallet) {
      wallet = await Wallet.create({ user: userId, balance: 0 });
    }

    wallet.balance += amount;
    await wallet.save();

    // Log wallet transaction
    await WalletTransaction.create({
      wallet: wallet._id,
      user: userId,
      amount,
      type: "credit",
      source: "deposit",
      linkedTransaction: transaction._id,
      notes: `Wallet topped up via M-Pesa STK push`,
    });

    console.log("Wallet updated and transaction completed.");
    return SuccessHandler(res, 200, "Deposit Processed Successfully");
  } catch (error) {
    console.error("Error handling STK callback:", error);
    return ErrorHandler(res, 500, "Internal server error");
  }
};

const checkPaymentStatus = async (req, res) => {
  // #swagger.tags = ['Safaricom']
  try {
    const transaction = await EscrowDeposit.findOne({
      transaction_id: req.params.transactionId,
    });

    if (!transaction) {
      return ErrorHandler("Transaction not found", 404, req, res);
    }

    if (transaction.isExpired() && transaction.status === "PENDING") {
      transaction.status = "EXPIRED";
      await transaction.save();
    }

    return SuccessHandler(
      {
        transaction_id: transaction.transaction_id,
        status: transaction.status,
        escrowStatus: transaction.escrowStatus,
        amount: transaction.amount,
        phone_number: transaction.phonenumber,
        paymentDetails: transaction.paymentDetails,
        disputeDetails: transaction.disputeDetails,
        expiresAt: transaction.expiresAt,
      },
      200,
      res
    );
  } catch (error) {
    logger.error("Error in checkPaymentStatus:", error);
    return ErrorHandler(error.message, 500, req, res);
  }
};

module.exports = {
  initiateStkPush,
  handleStkCallback,
  checkPaymentStatus,
};
