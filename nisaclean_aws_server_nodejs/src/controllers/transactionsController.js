const SuccessHandler = require("../utils/SuccessHandler");
const ErrorHandler = require("../utils/ErrorHandler");
const { initiateStkPush } = require("../utils/mpesa");
const Transaction = require("../models/Transactions/GenTransactions");
const Wallet = require("../models/Transactions/WalletSchema");
const EscrowDeposit = require("../models/Transactions/EscrowDeposit");
const Booking = require("../models/Bookings/booking");
const User = require("../models/User/user");
const Revenue = require("../models/Transactions/Revenue");
const WalletTransaction = require("../models/Transactions/WalletTransaction");

const { v4: uuidv4 } = require("uuid");

const requestDeposit = async (req, res) => {
  try {
    const { amount, phone } = req.body;
    const userId = req.user?._id;

    if (!amount || !phone) {
      return ErrorHandler("Amount and Phone Number are required.", 400, res);
    }

    // Triggers STK Push
    const stkResponse = await initiateStkPush(phone, amount);

    if (!stkResponse?.MerchantRequestID) {
      return;
    }

    // Store the transaction
    const transaction = await Transaction.create({
      referenceId: stkResponse.MerchantRequestID, // could also use CheckoutRequestID
      amount,
      type: "deposit",
      direction: "credit",
      status: "pending",
      paidBy: userId,
      paidTo: userId,
      notes: `STK push sent to ${phone}`,
    });
    return SuccessHandler(
      "Deposit initiated. Await STK push confirmation.",
      200,
      res,
      { stkResponse, transaction: transaction._id }
    );
  } catch (err) {
    console.log("Request deposit error:", err);
    return ErrorHandler("Failed to process deposit request.", 500, res);
  }
};

const requestPayment = async ({ userId, amount, bookingId, workerId }) => {
  if (!amount || !bookingId || !workerId) {
    throw new Error("amount, bookingId, and workerId are required.");
  }

  const wallet = await Wallet.findOne({ user: userId });
  if (!wallet || wallet.balance < amount) {
    throw new Error("Insufficient wallet balance.");
  }

  const revenue = Math.round(amount * 0.2);
  const netAmount = amount - revenue;

  wallet.balance -= amount;
  await wallet.save();

  const escrow = await EscrowDeposit.create({
    transaction_id: uuidv4(),
    amount,
    revenue,
    client: userId,
    worker: workerId,
    bookingId,
    status: "SUCCESS",
    escrowStatus: "HELD",
  });

  const booking = await Booking.findById(bookingId).select("service");
  const client = await User.findById(userId).select("name");
  const worker = await User.findById(workerId).select("name");

  const revenueRecord = await Revenue.create({
    escrowDepositId: escrow._id,
    transactionId: escrow.transaction_id,
    amount,
    revenue,
    client: {
      id: userId,
      name: client?.name || "Client",
    },
    worker: {
      id: workerId,
      name: worker?.name || "Worker",
    },
    booking: {
      id: bookingId,
      name: booking?.service || "Untitled Booking",
    },
    date: new Date(),
  });

  const transaction = await Transaction.create({
    user: userId,
    type: "escrow",
    direction: "debit",
    amount,
    paidTo: workerId,
    revenue,
    booking: bookingId,
    revenueRecord: revenueRecord._id,
    notes: `Payment for booking ${bookingId} held in escrow`,
  });

  await WalletTransaction.create({
    wallet: wallet._id,
    user: userId,
    amount: netAmount,
    type: "debit",
    source: "payment",
    booking: bookingId,
    linkedTransaction: transaction._id,
    notes: `Payout for completed booking: ${bookingId}`,
  });

  return { escrow, transaction };
};

const releaseFundsToWorker = async ({ escrowDepositId }) => {
  const escrow = await EscrowDeposit.findById(escrowDepositId).populate(
    "worker client bookingId"
  );

  if (!escrow) throw new Error("Escrow Deposit not found");

  if (escrow.status !== "SUCCESS" || escrow.escrowStatus !== "RELEASED") {
    throw new Error(
      "Escrow must be released and successful before transferring funds"
    );
  }

  if (escrow.fundsSent) {
    throw new Error("Funds already sent to worker");
  }

  const workerWallet = await Wallet.findOne({
    user: escrow.worker._id,
  });
  if (!workerWallet) throw new Error("Worker wallet not found");

  const netAmount = escrow.amount - escrow.revenue;
  workerWallet.balance += netAmount;
  await workerWallet.save();

  const transaction = await Transaction.create({
    type: "payment",
    amount: netAmount,
    direction: "credit",
    escrow: true,
    status: "success",
    paidBy: escrow.client._id,
    paidTo: escrow.worker._id,
    booking: escrow.bookingId,
    notes: `Funds released to ${escrow.worker.name} for ${escrow.bookingId}`,
  });

  await WalletTransaction.create({
    wallet: workerWallet._id,
    user: escrow.worker._id,
    amount: netAmount,
    type: "credit",
    source: "payment",
    booking: escrow.bookingId,
    linkedTransaction: transaction._id,
    notes: `Payout for completed booking: ${escrow.bookingId}`,
  });

  escrow.fundsSent = true;
  await escrow.save();

  return {
    wallet: {
      balance: workerWallet.balance,
    },
    transaction,
  };
};

const refundClientFromEscrow = async (req, res) => {
  try {
    const { escrowDepositId } = req.body;

    const escrow =
      await EscrowDeposit.findById(escrowDepositId).populate(
        "client bookingId"
      );

    if (!escrow) return ErrorHandler("Escrow deposit not found", 404, res);

    if (escrow.status !== "SUCCESS" || escrow.escrowStatus !== "HELD") {
      return ErrorHandler(
        "Escrow must be successful and still held to process refund",
        400,
        res
      );
    }

    if (escrow.refunded) {
      return ErrorHandler("Funds already refunded to client", 400, res);
    }

    const clientWallet = await Wallet.findOne({ userId: escrow.client._id });
    if (!clientWallet) return ErrorHandler("Client wallet not found", 404, res);

    clientWallet.balance += escrow.amount;
    await clientWallet.save();

    const transaction = await Transaction.create({
      type: "refund",
      amount: escrow.amount,
      direction: "credit",
      escrow: true,
      status: "success",
      paidBy: null,
      paidTo: escrow.client._id,
      booking: escrow.bookingId,
      notes: `Refund to client ${escrow.client.name} for booking ${escrow.bookingId}`,
    });

    await WalletTransaction.create({
      wallet: clientWallet._id,
      user: escrow.client._id,
      amount: escrow.amount,
      type: "credit",
      source: "refund",
      booking: escrow.bookingId,
      linkedTransaction: transaction._id,
      notes: `Refund for booking: ${escrow.bookingId}`,
    });

    escrow.refunded = true;
    escrow.escrowStatus = "REFUNDED";
    await escrow.save();

    return SuccessHandler(
      "Refund issued to client wallet successfully",
      200,
      res,
      {
        wallet: {
          balance: clientWallet.balance,
        },
        transaction,
      }
    );
  } catch (error) {
    return ErrorHandler("Failed to refund client", 500, res);
  }
};

const transferBetweenWallets = async (req, res) => {
  try {
    const { recipientId, amount, notes } = req.body;
    const senderId = req.user._id;

    if (!recipientId || !amount || amount <= 0) {
      return ErrorHandler("Recipient and valid amount required.", 500, res);
    }

    const senderWallet = await Wallet.findOne({ user: senderId });
    const recipientWallet = await Wallet.findOne({ user: recipientId });

    if (!senderWallet || !recipientWallet) {
      return ErrorHandler("Wallet not found for one or both users.", 404, res);
    }

    if (senderWallet.balance < amount) {
      return ErrorHandler("Insufficient funds.", 400, res);
    }

    // Deduct from sender
    senderWallet.balance -= amount;
    await senderWallet.save();

    // Add to recipient
    recipientWallet.balance += amount;
    await recipientWallet.save();

    const transaction = await Transaction.create({
      type: "wallet_transfer",
      direction: "debit",
      amount,
      paidBy: senderId,
      paidTo: recipientId,
      status: "success",
      notes: notes || `Transfer to user ${recipientId}`,
    });

    await WalletTransaction.create([
      {
        wallet: senderWallet._id,
        user: senderId,
        amount,
        type: "debit",
        source: "transfer",
        linkedTransaction: transaction._id,
        notes: `Transfer to ${recipientId}`,
      },
      {
        wallet: recipientWallet._id,
        user: recipientId,
        amount,
        type: "credit",
        source: "transfer",
        linkedTransaction: transaction._id,
        notes: `Transfer from ${senderId}`,
      },
    ]);

    return SuccessHandler("Transfer successful", 200, res, { transaction });
  } catch (error) {
    return ErrorHandler("Wallet transfer failed", 500, res);
  }
};

const adminTopUpWallet = async (req, res) => {
  try {
    const { userId, amount, notes } = req.body;

    if (!userId || !amount || amount <= 0) {
      return ErrorHandler("User ID and valid amount required.", 400, res);
    }

    const wallet = await Wallet.findOne({ user: userId });
    if (!wallet) return ErrorHandler("User wallet not found.", 404, res);

    wallet.balance += amount;
    await wallet.save();

    const transaction = await Transaction.create({
      type: "admin_topup",
      direction: "credit",
      amount,
      paidBy: req.user._id, // admin
      paidTo: userId,
      status: "success",
      notes: notes || "Admin top-up",
    });

    await WalletTransaction.create({
      wallet: wallet._id,
      user: userId,
      amount,
      type: "credit",
      source: "revenue",
      linkedTransaction: transaction._id,
      notes: notes || "Admin wallet top-up",
    });

    return SuccessHandler("Top-up successful", 200, res, {
      walletBalance: wallet.balance,
      transaction,
    });
  } catch (error) {
    return ErrorHandler("Admin top-up failed", 500, res);
  }
};

const getWalletBalance = async (req, res) => {
  try {
    const userId = req.body.userId || req.user?._id; // fallback to authenticated user

    if (!userId) {
      return ErrorHandler("User ID is required", 400, res);
    }

    const wallet = await Wallet.findOne({ user: userId });

    if (!wallet) {
      return ErrorHandler("Wallet not found for this user", 404, res);
    }

    SuccessHandler(200, res, { balance: wallet.balance });
  } catch (error) {
    ErrorHandler(error.message, 500, res);
  }
};

const adminReleaseEscrow = async (req, res) => {
  try {
    const { depositId } = req.body;

    const escrow = await EscrowDeposit.findById(depositId);
    if (!escrow) {
      return ErrorHandler("Escrow deposit not found", 404, res);
    }

    if (escrow.escrowStatus === "RELEASED") {
      return ErrorHandler("Escrow already released", 400, res);
    }

    escrow.escrowStatus = "RELEASED";
    await escrow.save();

    SuccessHandler({ message: "Escrow marked as RELEASED" }, 200, res);
  } catch (error) {
    ErrorHandler(error.message, 500, req, res);
  }
};

//Wrappers
const requestPaymentRoute = async (req, res) => {
  try {
    const { amount, bookingId, workerId } = req.body;
    const userId = req.user._id;
    const result = await requestPayment({
      userId,
      amount,
      bookingId,
      workerId,
    });
    SuccessHandler("Payment Completed Successfully.", 201, res, result);
  } catch (error) {
    ErrorHandler(error.message, 500, res);
  }
};

const releaseFundsRoute = async (req, res) => {
  try {
    const result = await releaseFundsToWorker({
      escrowDepositId: req.body.escrowDepositId,
    });
    SuccessHandler(
      "Funds released to worker wallet successfully",
      200,
      res,
      result
    );
  } catch (error) {
    ErrorHandler(error.message, 500, res);
  }
};

module.exports = {
  refundClientFromEscrow,
  releaseFundsToWorker,
  requestDeposit,
  requestPayment,
  transferBetweenWallets,
  adminTopUpWallet,
  getWalletBalance,
  adminReleaseEscrow,
  requestPaymentRoute,
  releaseFundsRoute,
};
