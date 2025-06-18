const mongoose = require("mongoose");
const Schema = mongoose.Schema;

const bookingSchema = new Schema(
  {
    service: {
      type: String,
      required: true,
    },
    date: {
      type: String,
      required: true,
    },
    time: {
      type: String,
      required: true,
    },
    location: {
      address: {
        type: String,
        required: true,
      },
      coordinates: {
        type: [Number], // [longitude, latitude]
        required: true,
      },
    },
    notes: {
      type: String,
      required: true,
    },
    user: {
      type: Schema.Types.ObjectId,
      ref: "user",
    },
    worker: {
      type: Schema.Types.ObjectId,
      ref: "user",
    },
    status: {
      type: String,
      enum: [
        "pending",
        "confirmation",
        "inprogress",
        "completed",
        "cancelled",
        "disputed",
        "resolved",
        "closed",
      ],
      default: "pending",
    },
    amount: {
      type: Number,
    },
    review: {
      type: Schema.Types.ObjectId,
      ref: "Review",
    },
    disputeDetails: {
      reason: { type: String },
      raisedBy: { type: Schema.Types.ObjectId, ref: "user" },
      description: { type: String },
      resolved: { type: Boolean, default: false },
      resolvedAt: { type: Date },
    },
    serviceTime: {
      type: Number, // in minutes
    },
    bookingStartingTime: {
      type: Date,
    },
    bookingEndTime: {
      type: Date,
    },
  },
  { timestamps: true }
);

const Booking = mongoose.model("booking", bookingSchema);
module.exports = Booking;
