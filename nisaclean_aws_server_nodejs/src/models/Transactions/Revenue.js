const mongoose = require("mongoose");
const Schema = mongoose.Schema;

const revenueSchema = new Schema(
  {
    escrowDepositId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "escrowDeposit",
      required: true,
      unique: true,
    },
    transactionId: {
      type: String,
      required: true,
      unique: true,
    },
    amount: {
      type: Number,
      required: true,
      min: 0,
    },
    revenue: {
      type: Number,
      required: true,
      min: 0,
    },
    client: {
      id: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "user",
        required: true,
      },
      name: {
        type: String,
        required: true,
      },
    },
    worker: {
      id: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "user",
        required: true,
      },
      name: {
        type: String,
        required: true,
      },
    },
    booking: {
      id: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "booking",
        required: true,
      },
      name: {
        type: String,
        required: true,
      },
    },
    date: {
      type: Date,
      required: true,
    },
    processed: {
      type: Boolean,
      default: false,
      index: true, // For faster queries
    },
    processingAttempts: {
      type: Number,
      default: 0,
    },
    lastProcessingError: {
      type: String,
    },
  },
  {
    timestamps: true,
  }
);

revenueSchema.index({ "client.id": 1 });
revenueSchema.index({ "worker.id": 1 });
revenueSchema.index({ processed: 1 });

const Revenue = mongoose.model("Revenue", revenueSchema);

module.exports = Revenue;
