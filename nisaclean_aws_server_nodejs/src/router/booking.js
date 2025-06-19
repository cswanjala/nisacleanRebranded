const express = require("express");
const booking = require("../controllers/bookingController");
const {
  isAuthenticated,
  isAdmin,
  isWorker,
  isClient,
} = require("../middleware/auth");
const router = express.Router();

router.route("/create").post(isAuthenticated, isClient, booking.createBooking);
router
  .route("/confirm-budget")
  .post(isAuthenticated, isWorker, booking.confirmBudget);
router.route("/start").post(isAuthenticated, isClient, booking.startBooking);
router
  .route("/complete")
  .post(isAuthenticated, isWorker, booking.markBookingAsComplete);
router
  .route("/close")
  .post(isAuthenticated, isClient, booking.markBookingAsClosed);

router.route("/cancel").post(isAuthenticated, booking.cancelBooking);
router.route("/delete").post(isAuthenticated, isClient, booking.deleteBooking);
router
  .route("/create-dispute")
  .post(isAuthenticated, isClient, booking.createBookingDispute);
router
  .route("/resolve-dispute")
  .post(isAuthenticated, isAdmin, booking.resolveBookingDispute);

router
  .route("/get-bookings")
  .get(isAuthenticated, isAdmin, booking.getBookings);
router.route("/get-booking-byId").get(isAuthenticated, booking.getBookingbyId);

router.route("/available-providers").get(isAuthenticated, booking.getAvailableProviders);

module.exports = router;
