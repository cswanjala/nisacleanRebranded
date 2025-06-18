const User = require("../models/User/user");
const SuccessHandler = require("../utils/SuccessHandler");
const ErrorHandler = require("../utils/ErrorHandler");
const { sendAdminNotification } = require("../utils/sendNotification");
const { uploadFilesOnAWS } = require("../utils/saveToServer");
const Review = require("../models/Bookings/review");
const Booking = require("../models/Bookings/booking");
const ServiceProvider = require("../models/Services/serviceProvider");
const Banner = require("../models/Banner");

const getAllUsers = async (req, res) => {
  try {
    const { role, isActive, search, page = 1, limit = 10 } = req.query;

    const query = {};

    if (role) query.role = role;
    if (isActive !== undefined) query.isActive = isActive === "true";

    if (search) {
      query.$or = [
        { name: new RegExp(search, "i") },
        { email: new RegExp(search, "i") },
      ];
    }

    const users = await User.find(query)
      .skip((page - 1) * limit)
      .limit(parseInt(limit))
      .sort({ createdAt: -1 });

    const total = await User.countDocuments(query);

    return SuccessHandler(
      "Users fetched successfully",

      200,
      res,
      {
        users,
        pagination: {
          total,
          page: parseInt(page),
          pages: Math.ceil(total / limit),
        },
      }
    );
  } catch (error) {
    console.error("Error fetching users:", error);
    return ErrorHandler("Failed to fetch users", 500, res);
  }
};

const getSingleUser = async (req, res) => {
  try {
    const { id } = req.params;
    const user = await User.findById(id);

    if (!user) {
      return ErrorHandler("User not found", 404, res);
    }

    return SuccessHandler(
      { message: "User fetched successfully", user },
      200,
      res
    );
  } catch (error) {
    console.error("Error fetching user:", error);
    return ErrorHandler("Failed to fetch user", 500, res);
  }
};

const createBanner = async (req, res) => {
  // #swagger.tags = ['admin']
  try {
    const { url } = req.body;
    if (!url) return ErrorHandler("Url is required", 400, req, res);
    let imageUrl = [""];
    if (req.files.image) {
      const image = req.files.image;
      imageUrl = await uploadFilesOnAWS([image]);
    }
    const banner = new Banner({
      image: imageUrl[0],
      url,
    });
    await banner.save();
    return SuccessHandler("Banner created successfully", 201, res);
  } catch (error) {
    return ErrorHandler(error.message, 500, req, res);
  }
};

const getBanners = async (req, res) => {
  // #swagger.tags = ['admin']
  try {
    const banners = await Banner.find();
    return SuccessHandler(banners, 200, res);
  } catch (error) {
    return ErrorHandler(error.message, 500, req, res);
  }
};

const deleteBanner = async (req, res) => {
  // #swagger.tags = ['admin']
  try {
    await Banner.findByIdAndDelete(req.params.id);
    return SuccessHandler("Banner deleted successfully", 200, res);
  } catch (error) {
    return ErrorHandler(error.message, 500, req, res);
  }
};

const me = async (req, res) => {
  // #swagger.tags = ['auth']
  try {
    let user = req.user;

    // Default response is the user
    let response = { ...user._doc };

    // For workers, enrich with ServiceProvider stats
    if (user.role === "worker") {
      const provider = await ServiceProvider.findOne({ user: user._id });

      if (!provider) {
        return ErrorHandler("Service Provider profile not found", 404, res);
      }

      // Compute success rate from Booking model
      const successRateAgg = await Booking.aggregate([
        {
          $match: {
            worker: user._id,
          },
        },
        {
          $group: {
            _id: null,
            totalJobs: { $sum: 1 },
            completedJobs: {
              $sum: {
                $cond: [{ $eq: ["$status", "completed"] }, 1, 0],
              },
            },
          },
        },
        {
          $project: {
            successRate: {
              $cond: [
                { $eq: ["$totalJobs", 0] },
                0,
                {
                  $multiply: [
                    { $divide: ["$completedJobs", "$totalJobs"] },
                    100,
                  ],
                },
              ],
            },
          },
        },
      ]);

      const avgRatingAgg = await Review.aggregate([
        {
          $match: {
            worker: mongoose.Types.ObjectId(user._id),
          },
        },
        {
          $group: {
            _id: null,
            avgRating: { $avg: "$rating" },
          },
        },
      ]);

      response = {
        ...response,
        serviceProfile: provider,
        successRate: successRateAgg[0]?.successRate || 0,
        rating: avgRatingAgg[0]?.avgRating || 0,
      };
    }

    return SuccessHandler("User Info Fetched", 200, res, response);
  } catch (error) {
    console.error("Error in /me:", error);
    return ErrorHandler("Failed to fetch profile", 500, res);
  }
};

const updateMe = async (req, res) => {
  // #swagger.tags = ['auth']
  try {
    const user = await User.findById(req.user.id);
    if (!user) {
      return ErrorHandler("User does not exist", 400, res);
    }

    // Handle profile picture upload
    if (req?.files?.image) {
      const image = req.files.image;
      const imageUrl = await uploadFilesOnAWS([image]);
      if (user.profilePic) {
        const filePath = path.join(__dirname, `../../${user.profilePic}`);
        // Optionally: fs.unlinkSync(filePath);
      }
      user.profilePic = imageUrl[0];
    }

    // Handle ID documents upload
    let idDocsUrl = [];
    if (req?.files?.idDocs) {
      const idDocs =
        req.files.idDocs.length > 1 ? req.files.idDocs : [req.files.idDocs];
      idDocsUrl = await uploadFilesOnAWS(idDocs);
      user.idDocs = idDocsUrl;
    }

    // Handle password change
    if (req.body.password) {
      if (!req.body.oldPassword) {
        return ErrorHandler("Please provide old password", 400, res);
      }
      const isOldCorrect = await user.comparePassword(req.body.oldPassword);
      if (!isOldCorrect) {
        return ErrorHandler("Old password is incorrect", 400, res);
      }

      const isSameAsOld = await user.comparePassword(req.body.password);
      if (isSameAsOld) {
        return ErrorHandler("New password cannot be the same as old", 400, res);
      }

      user.password = req.body.password; // hashed in pre-save hook
    }

    // Update user fields
    user.name = req.body.name || user.name;
    user.phone = req.body.phone || user.phone;
    user.idNumber = req.body.idNumber || user.idNumber;
    user.deviceToken = req.body.deviceToken || user.deviceToken;

    await user.save();

    // Notify admins if new documents uploaded
    if (idDocsUrl.length) {
      const allAdmins = await User.find({ role: "admin" });
      await Promise.all(
        allAdmins.map((admin) =>
          sendAdminNotification(
            admin._id,
            `${user.role} ${user.name} has uploaded their documents.`,
            "idDocs",
            user._id,
            "Documents Uploaded"
          )
        )
      );
    }

    return SuccessHandler(
      { message: "User updated successfully", user },
      200,
      res
    );
  } catch (error) {
    console.error("Update Me Error:", error);
    return ErrorHandler("Failed to update user", 500, res);
  }
};

module.exports = {
  getAllUsers,
  getSingleUser,
  createBanner,
  getBanners,
  deleteBanner,
  me,
  updateMe,
};
