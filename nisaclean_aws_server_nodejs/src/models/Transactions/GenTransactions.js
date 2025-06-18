const mongoose = require("mongoose");
const Schema = mongoose.Schema;

const transactionSchema = new Schema(
  {
    amount: {
      type: Number,
      required: true,
    },
    direction: {
      type: String,
      enum: ["credit", "debit"],
      required: true,
    },
    type: {
      type: String,
      enum: ["deposit", "payout", "payment", "revenue", "refund", "escrow"],
      required: true,
    },
    status: {
      type: String,
      enum: ["pending", "success", "failed", "cancelled"],
      default: "pending",
    },
    paidBy: {
      type: Schema.Types.ObjectId,
      ref: "user",
    },
    paidTo: {
      type: Schema.Types.ObjectId,
      ref: "user",
    },
    booking: {
      type: Schema.Types.ObjectId,
      ref: "booking",
    },
    revenueRecord: {
      type: Schema.Types.ObjectId,
      ref: "Revenue",
    },
    escrow: {
      type: Boolean,
      default: false,
    },
    metadata: Schema.Types.Mixed,
    referenceId: {
      type: String,
      unique: true,
      sparse: true,
    },
    notes: String,
  },
  { timestamps: true }
);

transactionSchema.index({ type: 1, createdAt: -1 });

const Transaction = mongoose.model("Transaction", transactionSchema);
module.exports = Transaction;
