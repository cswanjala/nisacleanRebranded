const mongoose = require("mongoose");
const Schema = mongoose.Schema;

const serviceProviderSchema = new Schema({
  user: {
    type: Schema.Types.ObjectId,
    ref: "User",
    required: true,
    unique: true,
  },

  services: {
    type: [String],
    enum: [
      "cleaning",
      "laundry",
      "gardening",
      "plumbing",
      "electrical",
      "painting",
      "carpet cleaning",
      "window cleaning",
      "disinfection",
      "moving",
    ],
    default: [],
  },

  description: {
    type: String,
  },

  rating: {
    type: Number,
    default: 0,
  },

  acceptedBookings: {
    type: Number,
    default: 0,
  },

  isAvailable: {
    type: Boolean,
    default: true,
  },

  adminApproval: {
    type: String,
    enum: ["pending", "approved", "rejected", "disabled"],
    default: "pending",
  },

  idNumber: {
    type: String,
  },

  idDocs: {
    type: [String], // Store image URLs or file paths
  },

  bookings: [
    {
      type: Schema.Types.ObjectId,
      ref: "Booking",
    },
  ],

  createdAt: {
    type: Date,
    default: Date.now,
  },
});

const ServiceProvider = mongoose.model(
  "ServiceProvider",
  serviceProviderSchema
);
module.exports = ServiceProvider;
