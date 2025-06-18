// #swagger.tags = ['Revenue']
const EscrowDeposit = require("../models/Transactions/EscrowDeposit");
const Revenue = require("../models/Transactions/Revenue");
const User = require("../models/User/user");
const Booking = require("../models/Bookings/booking");

const SuccessHandler = require("../utils/SuccessHandler");
const ErrorHandler = require("../utils/ErrorHandler");

// Sync released deposits to revenue records
const getAndSyncRevenue = async (req, res) => {
  try {
    const deposits = await EscrowDeposit.find({
      status: "SUCCESS",
      escrowStatus: "RELEASED",
    })
      .populate("client", "name")
      .populate("worker", "name")
      .populate("bookingId", "service");

    const createdRevenues = [];

    for (const deposit of deposits) {
      const existing = await Revenue.findOne({ escrowDepositId: deposit._id });
      if (!existing) {
        const newRevenue = await Revenue.create({
          escrowDepositId: deposit._id,
          transactionId: deposit.transaction_id,
          amount: deposit.amount,
          revenue: deposit.revenue,
          client: {
            id: deposit.client._id,
            name: deposit.client.name,
          },
          worker: {
            id: deposit.worker._id,
            name: deposit.worker.name,
          },
          booking: {
            id: deposit.bookingId._id,
            name: deposit.bookingId.service,
          },
          date: deposit.updatedAt,
        });
        createdRevenues.push(newRevenue);
      }
    }

    const allRevenues = await Revenue.find().sort({ date: -1 });
    SuccessHandler("Created Report", 200, res, {
      created: createdRevenues.length,
      data: allRevenues,
    });
  } catch (error) {
    ErrorHandler(error.message, 500, req, res);
  }
};

// Get revenue records between two dates
const getRevenueByDateRange = async (req, res) => {
  try {
    const { start, end } = req.query;
    if (!start || !end) {
      return ErrorHandler(
        "Please provide both start and end dates",
        400,
        req,
        res
      );
    }

    const startDate = new Date(start);
    const endDate = new Date(end);
    endDate.setHours(23, 59, 59, 999); // Include full day

    const revenues = await Revenue.find({
      date: { $gte: startDate, $lte: endDate },
    }).sort({ date: -1 });

    SuccessHandler(revenues, 200, res);
  } catch (error) {
    ErrorHandler(error.message, 500, req, res);
  }
};

// Aggregate yearly revenue stats
const generateYearlyReport = async (req, res) => {
  try {
    const now = new Date();
    const currentYear = now.getFullYear();
    const currentMonth = now.getMonth();

    const startOfYear = new Date(currentYear, 0, 1);
    const endOfYear = new Date(currentYear, 11, 31, 23, 59, 59, 999);

    const allRevenues = await Revenue.find({
      date: { $gte: startOfYear, $lte: endOfYear },
    });

    const monthlyRevenue = Array(12).fill(0);
    const clientMap = new Map();
    const workerMap = new Map();
    const bookingMap = new Map();

    for (const rev of allRevenues) {
      const month = new Date(rev.date).getMonth();
      if (month <= currentMonth) {
        monthlyRevenue[month] += rev.revenue;

        // Aggregate by client
        if (!clientMap.has(rev.client.id)) {
          clientMap.set(rev.client.id, {
            name: rev.client.name,
            monthly: Array(12).fill(0),
            total: 0,
          });
        }
        const c = clientMap.get(rev.client.id);
        c.monthly[month] += rev.revenue;
        c.total += rev.revenue;

        // Aggregate by worker
        if (!workerMap.has(rev.worker.id)) {
          workerMap.set(rev.worker.id, {
            name: rev.worker.name,
            monthly: Array(12).fill(0),
            total: 0,
          });
        }
        const w = workerMap.get(rev.worker.id);
        w.monthly[month] += rev.revenue;
        w.total += rev.revenue;

        // Aggregate by booking service
        if (!bookingMap.has(rev.booking.id)) {
          bookingMap.set(rev.booking.id, {
            name: rev.booking.name,
            monthly: Array(12).fill(0),
            total: 0,
          });
        }
        const j = bookingMap.get(rev.booking.id);
        j.monthly[month] += rev.revenue;
        j.total += rev.revenue;
      }
    }

    let topClients = [...clientMap.values()]
      .sort((a, b) => b.total - a.total)
      .slice(0, 3);
    let topWorkers = [...workerMap.values()]
      .sort((a, b) => b.total - a.total)
      .slice(0, 3);
    let topBookings = [...bookingMap.values()]
      .sort((a, b) => b.total - a.total)
      .slice(0, 3);

    // Fallbacks
    if (topClients.length === 0) {
      const fallbackClients = await User.find({ role: "client" })
        .sort({ createdAt: -1 })
        .limit(3)
        .select("name");
      topClients = fallbackClients.map((u) => ({
        name: u.name,
        monthly: Array(12).fill(0),
        total: 0,
      }));
    }

    if (topWorkers.length === 0) {
      const fallbackWorkers = await User.find({ role: "worker" })
        .sort({ createdAt: -1 })
        .limit(3)
        .select("name");
      topWorkers = fallbackWorkers.map((u) => ({
        name: u.name,
        monthly: Array(12).fill(0),
        total: 0,
      }));
    }

    if (topBookings.length === 0) {
      const fallbackBookings = await Booking.find()
        .sort({ createdAt: -1 })
        .limit(3)
        .select("service");
      topBookings = fallbackBookings.map((j) => ({
        name: j.service,
        monthly: Array(12).fill(0),
        total: 0,
      }));
    }

    SuccessHandler("Generated Yearly Reports", 200, res, {
      monthlyRevenue,
      topClients,
      topWorkers,
      topBookings,
    });
  } catch (error) {
    ErrorHandler(error.message, 500, req, res);
  }
};

module.exports = {
  getAndSyncRevenue,
  getRevenueByDateRange,
  generateYearlyReport,
};
