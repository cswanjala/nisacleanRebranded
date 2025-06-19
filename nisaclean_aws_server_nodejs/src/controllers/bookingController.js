const SuccessHandler = require("../utils/SuccessHandler");
const ErrorHandler = require("../utils/ErrorHandler");
const User = require("../models/User/user");
const Wallet = require("../models/Transactions/WalletSchema");
const {
  sendNotification,
  sendAdminNotification,
} = require("../utils/sendNotification");
const Booking = require("../models/Bookings/booking");
const { requestPayment } = require("./transactionsController");
const ServiceProvider = require("../models/Services/serviceProvider");

const assignServiceProviders = async (location, service) => {
  if (
    !location ||
    !Array.isArray(location.coordinates) ||
    location.coordinates.length !== 2
  ) {
    throw new Error(
      "Location must be provided as { coordinates: [longitude, latitude] }"
    );
  }

  if (!service || typeof service !== "string") {
    throw new Error("A valid service name must be provided");
  }

  // Get 5 closest matching workers
  const closestWorkers = await User.find({
    role: "worker",
    isActive: true,
    availability: true, // Only those marked as available
    location: {
      $near: {
        $geometry: {
          type: "Point",
          coordinates: location.coordinates,
        },
        $maxDistance: 50000, // 50km
      },
    },
    services: { $in: [service] },
  })
    .limit(5)
    .select("_id name profilePic rating availability");

  if (!closestWorkers.length) return null;

  // Pick the one with the highest rating
  const topRated = closestWorkers.reduce((prev, curr) =>
    curr.rating > prev.rating ? curr : prev
  );

  return topRated;
};

const createBooking = async (req, res) => {
  try {
    const {
      service,
      date,
      time,
      location,
      notes,
      bookingType,
      selectedProvider,
    } = req.body;

    const user = req.user;
    if (!user) return ErrorHandler("Not logged in", 401, res);
    const parsedLocation =
      typeof location === "string" ? JSON.parse(location) : location;

    //if (req.user.adminApproval === false) return ErrorHandler("Account not approved.")

    const bookingData = {
      service,
      date,
      time,
      location: parsedLocation,
      notes,
      user: user._id,
    };

    if (bookingType === "client assigned" && selectedProvider) {
      bookingData.worker = selectedProvider;

      const worker = await User.findById(selectedProvider);
      if (worker?.deviceToken) {
        await sendNotification(
          {
            _id: worker._id,
            deviceToken: worker.deviceToken,
          },
          `New booking for ${service} posted by ${req.user.name}`,
          "booking",
          "/booking/" + bookingData._id
        );
      }
    }
    if (bookingType === "system assigned") {
      const suggestedProvider = await assignServiceProviders(
        parsedLocation,
        service
      );
      if (suggestedProvider?.deviceToken) {
        await sendNotification(
          {
            _id: suggestedProvider._id,
            deviceToken: suggestedProvider.deviceToken,
          },
          `New booking for ${service} posted by ${req.user.name}`,
          "booking",
          "/booking/" + bookingData._id
        );
      }
      bookingData.worker = suggestedProvider;
    }

    const booking = await Booking.create(bookingData);
    SuccessHandler(
      {
        message: "Booking created successfully",
        booking,
      },
      201,
      res
    );
  } catch (error) {
    console.log("Booking creation failed:", error);
    ErrorHandler("Failed to create booking", 500, res);
  }
};

const confirmBudget = async (req, res) => {
  try {
    const { bookingId, budget } = req.body;
    const worker = req.user;

    if (!worker || worker.role !== "worker") {
      return ErrorHandler(
        res,
        403,
        "Only service providers can confirm budget"
      );
    }

    const booking = await Booking.findById(bookingId).populate("user");
    if (!booking) {
      return ErrorHandler("Booking not found", 404, res);
    }

    if (booking.worker.toString() !== worker._id.toString()) {
      return ErrorHandler("You are not assigned to this booking", 403, res);
    }

    if (booking.status !== "pending") {
      return ErrorHandler(`Booking is already ${booking.status}`, 400, res);
    }

    const user = booking.user;
    const wallet = await Wallet.findOne({ user: user._id });

    if (!wallet) {
      return ErrorHandler("User does not have a wallet", 400, res);
    }

    booking.amount = budget;

    if (wallet.balance >= budget) {
      // Sufficient balance – proceed
      booking.status = "inprogress";
      booking.bookingStartingTime = new Date().toISOString();
      await booking.save();

      // Notify worker to begin work
      if (worker.deviceToken) {
        await sendNotification(
          {
            _id: worker._id,
            deviceToken: worker.deviceToken,
          },
          `Client has sufficient funds for the ${booking.service} booking. You can begin work.`,
          "booking",
          "/booking/" + booking._id
        );
      }

      return SuccessHandler(
        "User has sufficient funds. Booking is now in progress.",
        200,
        res,
        booking
      );
    } else {
      // Insufficient balance – ask user to top up
      const shortfall = budget - wallet.balance;

      booking.status = "confirmation";
      await booking.save();

      // Notify user
      if (user.deviceToken) {
        await sendNotification(
          {
            _id: user._id,
            deviceToken: user.deviceToken,
          },
          `Top up your wallet with Ksh ${shortfall} to continue your ${booking.service} booking.`,
          "booking",
          "/booking/" + booking._id
        );
      }

      return SuccessHandler(
        `User needs to top up Ksh ${shortfall} to proceed.`,

        200,
        res,
        {
          booking,
          requiredTopUp: shortfall,
        }
      );
    }
  } catch (error) {
    console.error("Error confirming budget:", error);
    return ErrorHandler("Failed to confirm budget", 500, res);
  }
};

const startBooking = async (req, res) => {
  try {
    const { bookingId } = req.body;
    const client = req.user;

    if (!client || client.role !== "client") {
      return ErrorHandler("Only clients can start bookings", 403, res);
    }

    const booking = await Booking.findById(bookingId).populate("worker");
    if (!booking) {
      return ErrorHandler("Booking not found", 404, res);
    }

    if (!booking.user || booking.user.toString() !== client._id.toString()) {
      return ErrorHandler("This booking does not belong to you", 403, res);
    }

    if (booking.status !== "confirmation") {
      return ErrorHandler(
        `Booking must be in 'awaiting_payment_confirmation' status to start. Currently: ${booking.status}`,
        400,
        res
      );
    }

    const wallet = await Wallet.findOne({ user: client._id });
    if (!wallet) {
      return ErrorHandler("You do not have a wallet", 400, res);
    }

    if (wallet.balance < booking.budget) {
      const shortfall = booking.budget - wallet.balance;
      return ErrorHandler(
        `Insufficient funds. Please top up Ksh ${shortfall} to proceed.`,
        400,
        res
      );
    }

    // All checks passed: mark booking as in progress
    booking.status = "inprogress";
    booking.bookingStartingTime = new Date().toISOString();
    await booking.save();

    if (booking.worker?.deviceToken) {
      await sendNotification(
        {
          _id: booking.worker._id,
          deviceToken: booking.worker.deviceToken,
        },
        `Client has paid. You can now begin the ${booking.service} booking.`,
        "booking",
        "/booking/" + booking._id
      );
    }

    return SuccessHandler(
      "Booking started successfully. Worker has been notified.",

      200,
      res,
      {
        booking,
      }
    );
  } catch (error) {
    console.error("Error in startBooking:", error);
    return ErrorHandler(
      "Something went wrong while starting the booking",
      500,
      res
    );
  }
};

const markBookingAsComplete = async (req, res) => {
  try {
    const { id } = req.body;
    const user = req.user;

    if (!user || user.role !== "worker") {
      return ErrorHandler(
        res,
        403,
        "Only service providers can mark bookings as complete"
      );
    }

    const booking = await Booking.findById(id).populate("user");

    if (!booking) {
      return ErrorHandler("Booking not found", 404, res);
    }

    if (!booking.worker || booking.worker.toString() !== user._id.toString()) {
      return ErrorHandler("You are not assigned to this booking", 403, res);
    }

    if (booking.status !== "inprogress") {
      return ErrorHandler(
        `Booking is currently ${booking.status}, not in progress`,
        400,
        res
      );
    }

    booking.status = "completed";
    await booking.save();

    await ServiceProvider.findOneAndUpdate(
      { user: user._id },
      { $addToSet: { bookings: booking._id } }, // ensures no duplicates
      { new: true }
    );

    // requesting for payment
    const paymentResult = await requestPayment({
      userId: booking.user._id,
      amount: booking.amount,
      bookingId: booking._id,
      workerId: user._id,
    });

    // Notify the client
    const client = booking.user;
    if (client?.deviceToken) {
      await sendNotification(
        {
          _id: client._id,
          deviceToken: client.deviceToken,
        },
        `Your booking for ${booking.service} has been marked as completed by ${user.name}`,
        "booking",
        `/booking/${booking._id}`
      );
    }

    return SuccessHandler(
      "Booking marked as completed, payment processed, client notified",

      200,
      res,
      {
        booking,
        payment: paymentResult,
      }
    );
  } catch (error) {
    console.error("Error marking booking as complete:", error);
    return ErrorHandler(
      "Something went wrong while completing the booking",
      500,
      res
    );
  }
};

const markBookingAsClosed = async (req, res) => {
  try {
    const { id } = req.body; // bookingId
    const user = req.user;

    if (!user || user.role !== "client") {
      return ErrorHandler("Only clients can close bookings.", 403, res);
    }

    const booking = await Booking.findById(id);
    if (!booking) {
      return ErrorHandler("Booking not found.", 404, res);
    }

    if (booking.user.toString() !== user._id.toString()) {
      return ErrorHandler(
        "You are not authorized to close this booking.",
        403,
        res
      );
    }

    if (booking.status !== "completed") {
      return ErrorHandler(
        `Booking must be completed before closing.`,
        400,
        res
      );
    }

    const escrow = await EscrowDeposit.findOne({
      bookingId: booking._id,
      client: user._id,
      status: "SUCCESS",
      escrowStatus: "HELD",
    });

    if (!escrow) {
      return ErrorHandler("Escrow not found or already released.", 404, res);
    }

    // Mark escrow as RELEASED
    escrow.escrowStatus = "RELEASED";
    await escrow.save();

    // Release funds to the worker
    const paymentResult = await releaseFundsToWorker({
      escrowDepositId: escrow._id,
    });

    booking.bookingEndTime = new Date();
    const duration =
      new Date(booking.bookingEndTime) - new Date(booking.bookingStartingTime);
    booking.serviceTime = Math.ceil(duration / (1000 * 60));

    // Update booking status to CLOSED
    booking.status = "closed";
    await booking.save();

    return SuccessHandler(
      "Booking marked as closed and funds released to worker.",

      200,
      res,
      {
        booking,
        payment: paymentResult,
      }
    );
  } catch (error) {
    console.error("Error marking booking as closed:", error);
    return ErrorHandler(
      "Something went wrong while closing the booking.",
      500,
      res
    );
  }
};

const cancelBooking = async (req, res) => {
  try {
    const { id } = req.body;
    const user = req.user;

    const booking = await Booking.findById(id);
    if (!booking) return ErrorHandler("Booking not found", 404, res);

    const isClient = booking.user.toString() === user._id.toString();
    const isWorker = booking.worker?.toString() === user._id.toString();

    if (!isClient && !isWorker) {
      return ErrorHandler(
        "You are not authorized to cancel this booking",
        403,
        res
      );
    }

    if (booking.status === "cancelled" || booking.status === "closed") {
      return ErrorHandler("Booking is already cancelled or closed", 400, res);
    }

    booking.status = "cancelled";
    booking.bookingEndTime = new Date();
    await booking.save();

    return SuccessHandler("Booking cancelled", 200, res, booking);
  } catch (error) {
    console.error("Error cancelling booking:", error);
    return ErrorHandler("Failed to cancel booking", 500, res);
  }
};

const deleteBooking = async (req, res) => {
  try {
    const { id } = req.body;
    const user = req.user;

    const booking = await Booking.findById(id);
    if (!booking) return ErrorHandler("Booking not found", 404, res);

    if (booking.user.toString() !== user._id.toString()) {
      return ErrorHandler("Only the booking owner can delete it", 403, res);
    }

    if (booking.status !== "closed") {
      return ErrorHandler("Only closed bookings can be deleted", 400, res);
    }

    await booking.deleteOne();

    return SuccessHandler(
      "Booking deleted successfully",

      200,
      res
    );
  } catch (error) {
    console.error("Error deleting booking:", error);
    return ErrorHandler("Failed to delete booking", 500, res);
  }
};

const createBookingDispute = async (req, res) => {
  try {
    const { id } = req.body;
    const { reason, details } = req.body;
    const user = req.user;

    const booking = await Booking.findById(id);
    if (!booking) return ErrorHandler("Booking not found", 404, res);

    if (
      booking.user.toString() !== user._id.toString() &&
      booking.worker?.toString() !== user._id.toString()
    ) {
      return ErrorHandler(
        "You are not authorized to dispute this booking",
        403,
        res
      );
    }

    if (booking.status !== "completed") {
      return ErrorHandler(
        "Disputes can only be raised on completed bookings",
        400,
        res
      );
    }

    booking.status = "disputed";
    booking.disputeDetails = {
      raisedBy: user._id,
      reason,
      details,
      date: new Date(),
    };
    await booking.save();

    return SuccessHandler("Booking marked as disputed", 200, res, booking);
  } catch (error) {
    console.error("Error creating dispute:", error);
    return ErrorHandler("Failed to create dispute", 500, res);
  }
};

const resolveBookingDispute = async (req, res) => {
  try {
    const { id } = req.body;
    const admin = req.user;

    if (admin.role !== "admin") {
      return ErrorHandler("Only admins can resolve disputes", 403, res);
    }

    const booking = await Booking.findById(id);
    if (!booking) return ErrorHandler("Booking not found", 404, res);

    if (booking.status !== "disputed") {
      return ErrorHandler("Booking is not in a disputed state", 400, res);
    }

    booking.status = "resolved";
    booking.disputeResolvedAt = new Date();
    await booking.save();

    // // Optionally close the booking
    // req.body.id = id; // forward param
    // await markBookingAsClosed(req, res);
  } catch (error) {
    console.error("Error resolving dispute:", error);
    return ErrorHandler("Failed to resolve booking dispute", 500, res);
  }
};

const submitReview = async (req, res) => {
  try {
    const { bookingId } = req.params;
    const { rating, review, images } = req.body;
    const user = req.user;

    if (!user || user.role !== "client") {
      return ErrorHandler("Only clients can submit reviews", 403, res);
    }

    const booking = await Booking.findById(bookingId);
    if (!booking) {
      return ErrorHandler("Booking not found", 404, res);
    }

    if (booking.user.toString() !== user._id.toString()) {
      return ErrorHandler("This booking does not belong to you", 403, res);
    }

    if (booking.status !== "closed") {
      return ErrorHandler(
        "Booking must be closed to submit a review",
        400,
        res
      );
    }

    if (booking.review) {
      return ErrorHandler(
        "Review has already been submitted for this booking",
        400,
        res
      );
    }

    const serviceProvider = await ServiceProvider.findOne({
      user: booking.worker,
    });
    if (!serviceProvider) {
      return ErrorHandler("Service provider not found", 404, res);
    }

    // Create review
    const newReview = await Review.create({
      booking: booking._id,
      user: user._id,
      serviceProvider: serviceProvider._id,
      rating,
      review,
      images,
    });

    // Update booking with review reference
    booking.review = newReview._id;
    await booking.save();

    return SuccessHandler(
      "Review submitted successfully",

      201,
      res,
      {
        review: newReview,
      }
    );
  } catch (error) {
    console.error("Error submitting review:", error);
    return ErrorHandler("Failed to submit review", 500, res);
  }
};

// Booking Stats and Getters.
const getBookings = async (req, res) => {
  try {
    const {
      status,
      service,
      dateFrom,
      dateTo,
      search,
      page = 1,
      limit = 10,
    } = req.query;

    const query = {};

    if (status) query.status = status;
    if (service) query.service = service;

    if (dateFrom || dateTo) {
      query.date = {};
      if (dateFrom) query.date.$gte = new Date(dateFrom);
      if (dateTo) query.date.$lte = new Date(dateTo);
    }

    const searchRegex = search ? new RegExp(search, "i") : null;

    const aggregatePipeline = [
      { $match: query },
      {
        $lookup: {
          from: "users",
          localField: "user",
          foreignField: "_id",
          as: "user",
        },
      },
      { $unwind: "$user" },
      {
        $lookup: {
          from: "users",
          localField: "worker",
          foreignField: "_id",
          as: "worker",
        },
      },
      { $unwind: { path: "$worker", preserveNullAndEmptyArrays: true } },
    ];

    if (searchRegex) {
      aggregatePipeline.push({
        $match: {
          $or: [
            { "user.name": searchRegex },
            { "worker.name": searchRegex },
            { service: searchRegex },
          ],
        },
      });
    }

    const totalPipeline = [...aggregatePipeline, { $count: "total" }];

    aggregatePipeline.push(
      { $sort: { createdAt: -1 } },
      { $skip: (parseInt(page) - 1) * parseInt(limit) },
      { $limit: parseInt(limit) }
    );

    const bookings = await Booking.aggregate(aggregatePipeline);
    const totalResults = await Booking.aggregate(totalPipeline);
    const total = totalResults[0]?.total || 0;

    return SuccessHandler(
      "Bookings fetched successfully",

      200,
      res,
      {
        bookings,
        pagination: {
          total,
          page: parseInt(page),
          pages: Math.ceil(total / limit),
        },
      }
    );
  } catch (error) {
    console.error("Error fetching bookings:", error);
    return ErrorHandler("Failed to fetch bookings", 500, res);
  }
};

const getBookingbyId = async (req, res) => {
  try {
    const { id } = req.body;
    const booking = await Booking.findById(id)
      .populate("user", "name email")
      .populate("worker", "name email");

    if (!booking) {
      return ErrorHandler("Booking not found", 404, res);
    }

    return SuccessHandler("Booking fetched successfully", 200, res, booking);
  } catch (error) {
    console.error("Error fetching booking:", error);
    return ErrorHandler("Failed to fetch booking", 500, res);
  }
};

// Get available service providers for a service and location
const getAvailableProviders = async (req, res) => {
  try {
    const { service, lng, lat } = req.query;
    if (!service || !lng || !lat) {
      return ErrorHandler("service, lng, and lat are required", 400, res);
    }
    const location = {
      type: "Point",
      coordinates: [parseFloat(lng), parseFloat(lat)],
    };
    const closestWorkers = await User.find({
      role: "worker",
      isActive: true,
      availability: true,
      location: {
        $near: {
          $geometry: {
            type: "Point",
            coordinates: location.coordinates,
          },
          $maxDistance: 50000, // 50km
        },
      },
      services: { $in: [service] },
    })
      .limit(5)
      .select("_id name profilePic rating availability");
    return SuccessHandler(
      "Available providers fetched successfully",
      200,
      res,
      closestWorkers
    );
  } catch (error) {
    console.error("Error fetching available providers:", error);
    return ErrorHandler("Failed to fetch available providers", 500, res);
  }
};

module.exports = {
  createBooking,
  confirmBudget,
  startBooking,
  markBookingAsComplete,
  markBookingAsClosed,
  cancelBooking,
  deleteBooking,
  createBookingDispute,
  resolveBookingDispute,
  submitReview,

  getBookings,
  getBookingbyId,
  getAvailableProviders,
};
