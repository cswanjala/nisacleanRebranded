const Report = require("../models/Reports/Reports");
const EscrowDeposit = require("../models/Transactions/EscrowDeposit");
const User = require("../models/User/user");
const SuccessHandler = require("../utils/SuccessHandler");
const ErrorHandler = require("../utils/ErrorHandler");
const Revenue = require("../models/Transactions/Revenue");

const mongoose = require("mongoose");

const {
  startOfDay,
  addDays,
  format,
  isSameMonth,
  differenceInDays,
} = require("date-fns");
const Booking = require("../models/Bookings/booking");
const ServiceProvider = require("../models/Services/serviceProvider");

const BATCH_SIZE = 10;
async function regenerateAllReports() {
  console.log("🧹 Clearing all existing reports...");
  await Report.deleteMany({});
  console.log("✅ Cleared all reports.");

  const firstBooking = await Booking.findOne().sort({ date: 1 }).select("date");
  const lastBooking = await Booking.findOne().sort({ date: -1 }).select("date");

  if (!firstBooking || !lastBooking) {
    console.log("⚠️ No bookings found.");
    return;
  }

  const startDate = startOfDay(firstBooking.date);
  const endDate = startOfDay(lastBooking.date);
  const totalDays = differenceInDays(endDate, startDate) + 1;

  console.log(
    `📆 Generating reports from ${format(startDate, "yyyy-MM-dd")} to ${format(endDate, "yyyy-MM-dd")} (${totalDays} days)`
  );

  let currentDate = new Date(startDate);
  let currentMonth = currentDate.getMonth();
  let reportsGenerated = 0;
  const startTime = Date.now();

  while (currentDate <= endDate) {
    const batchDates = [];

    // Prepare a batch of dates
    for (let i = 0; i < BATCH_SIZE && currentDate <= endDate; i++) {
      batchDates.push(new Date(currentDate));
      currentDate = addDays(currentDate, 1);
    }

    // Run in parallel
    const results = await Promise.allSettled(
      batchDates.map((date) => generateReportForDate(date))
    );

    // Count successes and handle errors
    results.forEach((res, i) => {
      if (res.status === "fulfilled") {
        reportsGenerated++;
      } else {
        console.error(
          `❌ Failed to generate report for ${format(batchDates[i], "yyyy-MM-dd")}:`,
          res.reason
        );
      }
    });

    // Log monthly progress
    const lastInBatch = batchDates[batchDates.length - 1];
    if (!isSameMonth(currentMonth, lastInBatch.getMonth())) {
      const elapsed = ((Date.now() - startTime) / 1000).toFixed(2);
      console.log(
        `📊 Finished month ${format(lastInBatch, "MMMM yyyy")} — Reports: ${reportsGenerated} — Time: ${elapsed}s`
      );
      currentMonth = lastInBatch.getMonth();
    }
  }

  const totalTime = ((Date.now() - startTime) / 1000).toFixed(2);
  console.log(
    `✅ All done! Total reports: ${reportsGenerated} in ${totalTime}s`
  );
}
async function generateReportForDate(dateInput) {
  const date = new Date(dateInput);
  const start = new Date(
    Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate())
  );
  const end = new Date(
    Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate() + 1)
  );

  // -------- BOOKINGS --------
  const bookings = await Booking.find({
    createdAt: { $gte: start, $lt: end },
  }).lean();
  const completedBookings = await Booking.find({
    status: "completed",
    updatedAt: { $gte: start, $lt: end },
  }).lean();
  const disputedBookings = bookings.filter((b) => b.status === "disputed");

  const totalBookingsCreated = bookings.length;
  const totalBookingsCompleted = completedBookings.length;
  const totalBookingsCancelled = bookings.filter(
    (b) => b.status === "cancelled"
  ).length;
  const disputedCount = disputedBookings.length;
  const resolvedDisputesCount = Math.floor(disputedCount * 0.5);

  const totalDuration = bookings.reduce(
    (acc, b) => acc + parseFloat(b.timeDuration || 0),
    0
  );
  const avgBookingDuration = totalBookingsCreated
    ? totalDuration / totalBookingsCreated
    : 0;

  const bookingsByType = {};
  const bookingsByStatus = {};
  for (const booking of bookings) {
    bookingsByType[booking.service] = (bookingsByType[booking.type] || 0) + 1;
    bookingsByStatus[booking.status] =
      (bookingsByStatus[booking.status] || 0) + 1;
  }

  // -------- USERS --------
  const newUsers = await User.countDocuments({
    createdAt: { $gte: start, $lt: end },
  });
  const newServiceProviders = await User.countDocuments({
    role: "worker",
    createdAt: { $gte: start, $lt: end },
  });

  const activeUserIds = [
    ...new Set(bookings.map((b) => b.user?.toString()).filter(Boolean)),
  ];
  const activeWorkerIds = [
    ...new Set(bookings.map((b) => b.worker?.toString()).filter(Boolean)),
  ];

  const activeUsers = activeUserIds.length;
  const activeServiceProviders = activeWorkerIds.length;

  // -------- REVENUE BY USER --------
  const revenues = await EscrowDeposit.find({
    updatedAt: { $gte: start, $lt: end },
    status: "SUCCESS",
    escrowStatus: "RELEASED",
  }).lean();

  const revenueByUser = {};
  for (const rev of revenues) {
    const clientId = rev.client?.toString();
    if (clientId) {
      revenueByUser[clientId] =
        (revenueByUser[clientId] || 0) + (rev.revenue || 0);
    }
  }

  const topClientIds = Object.entries(revenueByUser)
    .sort(([, a], [, b]) => b - a)
    .slice(0, 5)
    .map(([id]) => mongoose.Types.ObjectId(id));

  const topClientsUsers = await User.find(
    { _id: { $in: topClientIds } },
    { name: 1 }
  ).lean();
  const topClients = topClientsUsers.map((u) => ({
    userId: u._id.toString(),
    name: u.name,
    totalSpent: revenueByUser[u._id.toString()] || 0,
  }));

  const workerCompletedBookingsCount = {};
  for (const booking of completedBookings) {
    if (booking.worker) {
      const wid = booking.worker.toString();
      workerCompletedBookingsCount[wid] =
        (workerCompletedBookingsCount[wid] || 0) + 1;
    }
  }

  const topWorkerIds = Object.entries(workerCompletedBookingsCount)
    .sort(([, a], [, b]) => b - a)
    .slice(0, 5)
    .map(([id]) => mongoose.Types.ObjectId(id));

  const topWorkerUsers = await User.find(
    { _id: { $in: topWorkerIds } },
    { name: 1 }
  ).lean();
  const topWorkers = topWorkerUsers.map((u) => ({
    userId: u._id.toString(),
    name: u.name,
    bookingsCompleted: workerCompletedBookingsCount[u._id.toString()] || 0,
  }));
  // -------- LEADERBOARDS --------

  // Top services by booking count
  const topServices = Object.entries(bookingsByType)
    .sort(([, a], [, b]) => b - a)
    .slice(0, 5)
    .map(([service, bookingCount]) => ({ service, bookingCount }));

  // Count bookings per service provider
  const providerBookingCounts = {};
  for (const booking of bookings) {
    if (booking.worker) {
      const provider = await ServiceProvider.findOne({ user: booking.worker })
        .select("_id")
        .lean();
      if (provider) {
        const pid = provider._id.toString();
        providerBookingCounts[pid] = (providerBookingCounts[pid] || 0) + 1;
      }
    }
  }

  // Top 5 most booked providers
  const mostBookedProviderIds = Object.entries(providerBookingCounts)
    .sort(([, a], [, b]) => b - a)
    .slice(0, 5)
    .map(([id]) => mongoose.Types.ObjectId(id));

  // Fetch their user info
  const mostBookedProviders = await ServiceProvider.find({
    _id: { $in: mostBookedProviderIds },
  })
    .populate("user", "name")
    .lean();

  const mostBooked = mostBookedProviders.map((provider) => ({
    serviceProviderId: provider._id.toString(),
    name: provider.user?.name || "Unknown",
    bookings: providerBookingCounts[provider._id.toString()] || 0,
  }));

  // -------- GLOBAL STATS (NOT DATE-BASED) --------
  const totalUsers = await User.countDocuments({});
  const totalServiceProviders = await User.countDocuments({ role: "worker" });
  const totalBookings = await Booking.countDocuments({});
  const totalRevenue = await Revenue.aggregate([
    {
      $match: { status: "SUCCESS", escrowStatus: "RELEASED" },
    },
    {
      $group: { _id: null, total: { $sum: "$revenue" } },
    },
  ]);
  const totalRevenueAmount = totalRevenue[0]?.total || 0;
  // -------- FINAL REPORT STRUCTURE --------
  const reportData = {
    date: start,
    bookingStats: {
      totalCreated: totalBookingsCreated,
      totalCompleted: totalBookingsCompleted,
      totalCancelled: totalBookingsCancelled,
      averageDuration: avgBookingDuration,
      byType: bookingsByType,
      byStatus: bookingsByStatus,
      disputeStats: {
        totalDisputed: disputedCount,
        totalResolved: resolvedDisputesCount,
        resolutionRate: disputedCount
          ? Math.round((resolvedDisputesCount / disputedCount) * 100)
          : 0,
      },
    },
    userStats: {
      newRegistrations: {
        total: newUsers,
        serviceProviders: newServiceProviders,
      },
      activeToday: {
        users: activeUsers,
        serviceProviders: activeServiceProviders,
      },
      topClients,
      topWorkers: mostBooked, // renamed from topWorkers
    },
    serviceStats: {
      mostPopularServices: topServices,
      mostBookedWorkers: mostBooked, // renamed from mostBookedWorkers
      topRatedWorkers: [], // TODO: Add rating logic
    },
    globalStats: {
      totalUsers,
      totalServiceProviders,
      totalBookings,
      totalRevenue: totalRevenueAmount,
    },
    lastUpdated: new Date(),
  };

  const report = await Report.findOneAndUpdate({ date: start }, reportData, {
    new: true,
    upsert: true,
  });

  return report;
}

// Generate all missing daily reports from first record to yesterday
const generateMissingReports = async (req, res) => {
  try {
    const earliestJob = await Booking.findOne().sort({ createdAt: 1 }).limit(1);
    const earliestPayment = await EscrowDeposit.findOne()
      .sort({ createdAt: 1 })
      .limit(1);

    if (!earliestJob && !earliestPayment) {
      return SuccessHandler("No data available to generate reports", 200, res);
    }

    const earliestDate = new Date(
      Math.min(
        earliestJob?.createdAt?.getTime() || Infinity,
        earliestPayment?.createdAt?.getTime() || Infinity
      )
    );
    earliestDate.setHours(0, 0, 0, 0);

    const yesterday = new Date();
    yesterday.setHours(0, 0, 0, 0);
    yesterday.setDate(yesterday.getDate() - 1);

    const existingReports = await Report.find({
      period: "daily",
      date: { $gte: earliestDate, $lte: yesterday },
    }).select("date");

    const existingDates = new Set(
      existingReports.map((r) => r.date.toISOString().split("T")[0])
    );

    const reportsGenerated = [];

    for (
      let d = new Date(earliestDate);
      d <= yesterday;
      d.setDate(d.getDate() + 1)
    ) {
      const isoDate = d.toISOString().split("T")[0];
      if (!existingDates.has(isoDate)) {
        const report = await generateReportForDate(new Date(d));
        if (report) reportsGenerated.push(report);
      }
    }

    return SuccessHandler(
      {
        message: `Generated ${reportsGenerated.length} missing report(s)`,
        dates: reportsGenerated.map((r) => r.date),
      },
      200,
      res
    );
  } catch (error) {
    console.error("Error in generateMissingReports:", error);
    return ErrorHandler(error.message, 500, req, res);
  }
};

function getDateRangeFromPeriod(period) {
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  let startDate, endDate;

  switch (period.toLowerCase()) {
    case "daily":
      startDate = new Date(today);
      endDate = new Date(today);
      break;
    case "weekly":
      startDate = new Date(today);
      startDate.setDate(today.getDate() - 6);
      endDate = new Date(today);
      break;
    case "monthly":
      startDate = new Date(today.getFullYear(), today.getMonth(), 1);
      endDate = new Date(today);
      break;
    default:
      throw new Error("Invalid period: Use daily, weekly, or monthly.");
  }

  startDate.setHours(0, 0, 0, 0);
  endDate.setHours(23, 59, 59, 999);

  return { startDate, endDate };
}

const generateReportByPeriod = async (period) => {
  try {
    const { startDate, endDate } = getDateRangeFromPeriod(period);

    const reports = await Report.find({
      date: { $gte: startDate, $lte: endDate },
    }).sort({ date: 1 });

    console.log(`Generated ${period} report from ${startDate} to ${endDate}`);
    return reports;
  } catch (error) {
    console.error(`Error generating ${period} report:`, error);
    throw error;
  }
};

const generateReportByRange = async (req, res) => {
  try {
    let { startDate, endDate, period } = req.query;

    if (period && !startDate && !endDate) {
      const today = new Date();
      today.setHours(0, 0, 0, 0);

      switch (period.toLowerCase()) {
        case "daily":
          startDate = new Date(today);
          endDate = new Date(today);
          break;
        case "weekly":
          startDate = new Date(today);
          startDate.setDate(today.getDate() - 6); // last 7 days including today
          endDate = new Date(today);
          break;
        case "monthly":
          startDate = new Date(today.getFullYear(), today.getMonth(), 1); // first day of current month
          endDate = new Date(today);
          break;
        default:
          return ErrorHandler(
            "Invalid period value. Use daily, weekly, or monthly.",
            400,
            req,
            res
          );
      }
    } else {
      if (!startDate || !endDate) {
        return ErrorHandler(
          "startDate and endDate are required if period is not provided",
          400,
          req,
          res
        );
      }
      startDate = new Date(startDate);
      endDate = new Date(endDate);
    }

    // Normalize times to cover full days
    startDate.setHours(0, 0, 0, 0);
    endDate.setHours(23, 59, 59, 999);

    // Query the reports collection
    const reports = await Report.find({
      date: {
        $gte: startDate,
        $lte: endDate,
      },
    }).sort({ date: 1 });

    return SuccessHandler(reports, 200, res);
  } catch (error) {
    console.error("Error fetching reports by range:", error);
    return ErrorHandler(error.message, 500, req, res);
  }
};

module.exports = {
  regenerateAllReports,
  generateReportForDate,
  generateMissingReports,
  generateReportByPeriod,
  generateReportByRange,
};
