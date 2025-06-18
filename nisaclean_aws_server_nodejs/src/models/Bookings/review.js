const mongoose = require("mongoose");
const schema = mongoose.Schema;

const reviewSchema = new schema(
  {
    booking: {
      type: schema.Types.ObjectId,
      ref: "Booking",
      required: true,
    },
    user: {
      type: schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    serviceProvider: {
      type: schema.Types.ObjectId,
      ref: "serviceProvider",
      required: true,
    },
    rating: {
      type: Number,
      required: true,
    },
    review: {
      type: String,
      required: true,
    },
    images: {
      type: [String],
    },
  },
  { timestamps: true }
);

const Review = mongoose.model("Review", reviewSchema);
module.exports = Review;
