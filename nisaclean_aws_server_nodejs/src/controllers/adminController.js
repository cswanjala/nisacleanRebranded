const SuccessHandler = require("../utils/SuccessHandler");
const ErrorHandler = require("../utils/ErrorHandler");
const User = require("../models/User/user");
const { uploadFilesOnAWS } = require("../utils/saveToServer");
const Banner = require("../models/Banner");
const {
  sendNotification,
  sendAdminNotification,
} = require("../utils/sendNotification");
const Booking = require("../models/Bookings/booking");

const updateProviderStatus = async (req, res) => {
  try {
    const { providerId, status } = req.body;

    if (!providerId || !status) {
      return ErrorHandler("providerId and status are required.", 400, res);
    }

    const allowedStatuses = ["approved", "pending", "rejected", "disabled"];
    if (!allowedStatuses.includes(status)) {
      return ErrorHandler("Invalid status value provided.", 400, res);
    }

    const provider =
      await ServiceProvider.findById(providerId).populate("user");

    if (!provider) {
      return ErrorHandler("Service provider not found.", 404, res);
    }

    if (provider.user.role !== "worker") {
      return ErrorHandler("Linked user is not a service provider.", 400, res);
    }

    provider.adminApproval = status;
    await provider.save();

    return SuccessHandler(
      `Service Provider status has been updated to ${status}`,
      200,
      res,
      provider
    );
  } catch (error) {
    console.error("Admin service approval error:", error);
    return ErrorHandler("Failed to update provider status.", 500, res);
  }
};

const makeUserAdmin = async (req, res) => {
  // #swagger.tags = ['admin']
  try {
    const user = await User.findById(req.params.id);
    if (!user) {
      return ErrorHandler("User not found", 404, req, res);
    }

    if (user.role === "admin") {
      return ErrorHandler("User is already an admin", 400, req, res);
    }

    user.role = "admin";
    await user.save();

    await sendNotification(user, "You are now an Admin", "approval", user._id);

    return SuccessHandler("User is now an admin", 200, res);
  } catch (error) {
    return ErrorHandler(error.message, 500, req, res);
  }
};

const deleteUserById = async (req, res) => {
  try {
    const { id } = req.params;

    const deletedUser = await User.findByIdAndDelete(id);

    if (!deletedUser) {
      return ErrorHandler("User not found", 404, res);
    }

    // Also delete the linked service provider profile if the user was a worker
    if (deletedUser.role === "worker") {
      await ServiceProvider.findOneAndDelete({ user: deletedUser._id });
    }

    return SuccessHandler(
      "User and associated service (if any) deleted successfully.",
      200,
      res
    );
  } catch (error) {
    console.error("Delete user failed:", error);
    return ErrorHandler("Failed to delete user", 500, res);
  }
};

const generalStats = async (req, res) => {
  // #swagger.tags = ['admin']
  try {
    const totalJobs = await Booking.countDocuments();
    const totalWorkers = await User.countDocuments({
      role: "worker",
      adminApproval: "approved",
    });
    const totalClients = await User.countDocuments({ role: "client" });
    return SuccessHandler(
      {
        totalJobs,
        totalWorkers,
        totalClients,
      },
      200,
      res
    );
  } catch (error) {
    return ErrorHandler(error.message, 500, req, res);
  }
};

module.exports = {
  updateProviderStatus,
  makeUserAdmin,
  deleteUserById,
  generalStats,
};
