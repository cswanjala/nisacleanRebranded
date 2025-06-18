const mongoose = require("mongoose");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const dotenv = require("dotenv");
const validator = require("validator");

dotenv.config({ path: ".././src/config/config.env" });

const Schema = mongoose.Schema;

const userSchema = new Schema({
  name: {
    type: String,
    required: true,
  },

  email: {
    type: String,
    required: true,
    unique: true,
    validate(value) {
      if (!validator.isEmail(value)) {
        throw new Error("Invalid Email");
      }
    },
  },

  profilePic: {
    type: String,
  },

  password: {
    type: String,
    required: true,
  },

  role: {
    type: String,
    enum: ["worker", "admin", "client"],
    required: true,
  },

  phone: {
    type: String,
  },

  createdAt: {
    type: Date,
    default: Date.now,
  },

  location: {
    type: {
      type: String,
      enum: ["Point"],
      default: "Point",
    },
    coordinates: {
      type: [Number],
      required: false,
    },
  },

  passwordResetToken: {
    type: Number,
  },

  passwordResetTokenExpires: {
    type: Date,
  },

  isActive: {
    type: Boolean,
    default: true,
  },

  deviceToken: {
    type: String,
  },

  withdrawal: {
    type: Boolean,
    default: false,
  },
});

// Index for geolocation
userSchema.index({ location: "2dsphere" });

// Hash password before save
userSchema.pre("save", async function (next) {
  if (!this.isModified("password")) return next();
  const salt = await bcrypt.genSalt(10);
  this.password = await bcrypt.hash(this.password, salt);
  next();
});

// JWT token method
userSchema.methods.getJWTToken = function () {
  return jwt.sign({ _id: this._id }, process.env.JWT_SECRET);
};

// Compare entered password with hashed password
userSchema.methods.comparePassword = async function (enteredPassword) {
  return await bcrypt.compare(enteredPassword, this.password);
};

const User = mongoose.model("User", userSchema);
module.exports = User;
