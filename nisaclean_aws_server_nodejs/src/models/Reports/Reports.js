const mongoose = require("mongoose");

const ReportSchema = new mongoose.Schema({
  date: { type: Date, required: true, index: true },

  revenue: [
    {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Revenue",
    },
  ],

  jobStats: {
    totalJobsCreated: { type: Number, default: 0 },
    totalJobsCompleted: { type: Number, default: 0 },
    totalJobsCancelled: { type: Number, default: 0 },
    avgJobDuration: { type: Number, default: 0 }, // in minutes
    jobsByType: {
      type: Map,
      of: Number,
      default: {},
    },
    jobsByStatus: {
      type: Map,
      of: Number,
      default: {},
    },
    disputedJobs: { type: Number, default: 0 },
    resolvedDisputes: { type: Number, default: 0 },
  },

  userStats: {
    newUsers: { type: Number, default: 0 },
    newServiceProviders: { type: Number, default: 0 },
    activeUsers: { type: Number, default: 0 },
    activeServiceProviders: { type: Number, default: 0 },
    topClients: [
      {
        userId: String,
        name: String,
        totalSpent: Number,
      },
    ],
    topWorkers: [
      {
        userId: String,
        name: String,
        jobsCompleted: Number,
      },
    ],
  },

  financeStats: {
    escrowDepositsToday: { type: Number, default: 0 },
    escrowReleasesToday: { type: Number, default: 0 },
    withdrawalRequests: { type: Number, default: 0 },
    successfulWithdrawals: { type: Number, default: 0 },
    failedTransactions: { type: Number, default: 0 },
  },

  leaderboards: {
    topServices: [
      {
        serviceType: String,
        jobCount: Number,
      },
    ],
    topRatedWorkers: [
      {
        userId: String,
        name: String,
        rating: Number,
      },
    ],
    mostBookedWorkers: [
      {
        userId: String,
        name: String,
        bookings: Number,
      },
    ],
  },

  createdAt: { type: Date, default: Date.now },
  lastUpdated: { type: Date, default: Date.now },
});

const Report = mongoose.model("Report", ReportSchema);
module.exports = Report;
