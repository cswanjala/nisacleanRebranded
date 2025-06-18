const mongoose = require("mongoose");
const Schema = mongoose.Schema;

const escrowDepositSchema = new Schema(
  {
    transaction_id: {
      type: String,
      required: true,
      unique: true,
      index: true,
    },
    amount: {
      type: Number,
      required: true,
      min: [1, "Amount must be at least 1"],
    },
    revenue: {
      type: Number,
      required: true,
    },
    status: {
      type: String,
      enum: ["PENDING", "SUCCESS", "FAILED", "CANCELLED"],
      default: "PENDING",
    },
    fundsSent: {
      type: Boolean,
      default: false,
    },
    refunded: {
      type: Boolean,
      default: false,
    },
    client: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "user",
      required: true,
      index: true,
    },
    worker: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "user",
      required: true,
      index: true,
    },
    bookingId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "booking",
      required: true,
      index: true,
    },
    escrowStatus: {
      type: String,
      enum: ["HELD", "RELEASED", "REFUNDED", "DISPUTED"],
      default: "HELD",
    },
    releasedAt: Date,
    refundedAt: Date,
    notes: String,

    // Dispute handling
    disputeDetails: {
      isDisputed: {
        type: Boolean,
        default: false,
      },
      disputeReason: String,
      disputeDate: Date,
      resolvedDate: Date,
      resolution: {
        type: String,
        enum: ["RELEASED_TO_WORKER", "REFUNDED_TO_CLIENT", "PARTIAL_REFUND"],
      },
    },

    // Security and audit fields
    ipAddress: String,
    userAgent: String,
    lastStatusChange: {
      type: Date,
      default: Date.now,
    },
    statusHistory: [
      {
        status: String,
        escrowStatus: String,
        timestamp: Date,
        reason: String,
      },
    ],

    // Timeout handling
    expiresAt: {
      type: Date,
      required: true,
      default: () => new Date(Date.now() + 24 * 60 * 60 * 1000), // 24 hours
    },
    retryCount: {
      type: Number,
      default: 0,
    },
    maxRetries: {
      type: Number,
      default: 3,
    },
  },
  {
    timestamps: true,
  }
);

// Indexes for performance
escrowDepositSchema.index({ createdAt: -1 });
escrowDepositSchema.index({ status: 1, escrowStatus: 1 });
escrowDepositSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });

// Pre-save middleware to track status changes
escrowDepositSchema.pre("save", function (next) {
  if (this.isModified("status") || this.isModified("escrowStatus")) {
    this.statusHistory.push({
      status: this.status,
      escrowStatus: this.escrowStatus,
      timestamp: new Date(),
    });
    this.lastStatusChange = new Date();
  }
  next();
});

// Helpers
escrowDepositSchema.methods.isExpired = function () {
  return new Date() > this.expiresAt;
};

escrowDepositSchema.methods.canRetry = function () {
  return this.retryCount < this.maxRetries;
};

const EscrowDeposit = mongoose.model("EscrowDeposit", escrowDepositSchema);
module.exports = EscrowDeposit;
