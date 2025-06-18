const mongoose = require("mongoose");
const Schema = mongoose.Schema;

const walletTransactionSchema = new Schema(
  {
    wallet: {
      type: Schema.Types.ObjectId,
      ref: "Wallet",
      required: true,
    },
    user: {
      type: Schema.Types.ObjectId,
      ref: "user",
      required: true,
    },
    amount: {
      type: Number,
      required: true,
    },
    type: {
      type: String,
      enum: ["credit", "debit"],
      required: true,
    },
    source: {
      type: String,
      enum: ["deposit", "payment", "payout", "refund", "revenue", "withdrawal"],
      required: true,
    },
    booking: {
      type: Schema.Types.ObjectId,
      ref: "booking",
    },
    linkedTransaction: {
      type: Schema.Types.ObjectId,
      ref: "Transaction",
    },
    notes: String,
    metadata: Schema.Types.Mixed,
  },
  { timestamps: true }
);

walletTransactionSchema.index({ user: 1, createdAt: -1 });

const WalletTransaction = mongoose.model(
  "WalletTransaction",
  walletTransactionSchema
);

module.exports = WalletTransaction;
