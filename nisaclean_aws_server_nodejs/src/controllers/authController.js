const User = require("../models/User/user");
const { sendMail } = require("../utils/sendMail");
const SuccessHandler = require("../utils/SuccessHandler");
const ErrorHandler = require("../utils/ErrorHandler");
const {
  uploadFilesOnAWS,
  deleteImageFromAWS,
} = require("../utils/saveToServer");
const path = require("path");
const {
  sendNotification,
  sendAdminNotification,
} = require("../utils/sendNotification");
const { default: mongoose } = require("mongoose");
const Review = require("../models/Bookings/review");
const Wallet = require("../models/Transactions/WalletSchema");

//register
const register = async (req, res) => {
  // #swagger.tags = ['auth']
  try {
    const { name, email, phone, password, role, location } = req.body;

    const user = await User.findOne({ email });
    if (user && user.isActive) {
      return ErrorHandler("User already exists", 400, req, res);
    }
    if (user && !user.isActive) {
      user.isActive = true;
      user.adminApproval = "pending";
      await user.save();
      return SuccessHandler("User created successfully", 200, res);
    }
    const newUserData = {
      name,
      email,
      password,
      role,
      phone,
    };
    if (location && location.coordinates) {
      newUserData.location = {
        type: "Point",
        coordinates: location.coordinates,
      };
    }

    const newUser = await User.create(newUserData);
    SuccessHandler("User created successfully", 200, res);
    if (req.body.deviceToken) {
      newUser.deviceToken = req.body.deviceToken;
      await newUser.save();
      await sendNotification(
        {
          _id: newUser._id,
          deviceToken: req.body.deviceToken,
        },
        "Welcome to the app",
        "register",
        "/home"
      );
    }

    const allAdmins = await User.find({ role: "admin" });
    Promise.all(
      allAdmins.map(
        async (admin) =>
          await sendAdminNotification(
            admin._id,
            `New ${newUser.role}, ${newUser.name} has registered`,
            "register",
            newUser.email,
            "New Registration"
          )
      )
    );

    // create wallet for user
    await Wallet.create({
      user: newUser._id,
      balance: 0,
      transactions: [],
    });
  } catch (error) {
    return ErrorHandler(error.message, 500, req, res);
  }
};

const requestEmailToken = async (req, res) => {
  // #swagger.tags = ['auth']

  try {
    const { email } = req.body;
    if (!email) {
      return ErrorHandler("Email is required", 400, req, res);
    }
    const user = await User.findOne({ email });
    if (!user) {
      return ErrorHandler("User does not exist", 400, req, res);
    }
    const verificationToken = Math.floor(100000 + Math.random() * 900000); // 6-digit code
    const tokenExpires = new Date(Date.now() + 10 * 60 * 1000); // 10 mins

    user.emailVerificationToken = verificationToken;
    user.emailVerificationTokenExpires = tokenExpires;
    await user.save();

    await sendMail(email, verificationToken);
    return SuccessHandler(
      `Email verification token sent to ${email}`,
      200,
      res
    );
  } catch (error) {
    return ErrorHandler(error.message, 500, req, res);
  }
};

//verify email token
const verifyEmail = async (req, res) => {
  // #swagger.tags = ['auth']

  try {
    const { email, code } = req.body;

    if (!email || !code) {
      return ErrorHandler("Email and code are required", 400, req, res);
    }
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(400).json({
        success: false,
        message: "User does not exist",
      });
    }
    if (
      user.emailVerificationToken !== Number(code) ||
      user.emailVerificationTokenExpires < Date.now()
    ) {
      return ErrorHandler("Invalid or expired token", 400, req, res);
    }
    user.emailVerified = true;
    user.emailVerificationToken = null;
    user.emailVerificationTokenExpires = null;

    const jwtToken = user.getJWTToken();
    await user.save();
    return SuccessHandler(
      "Email verified successfully",

      200,
      res,
      { message: "Email verified successfully", token: jwtToken }
    );
  } catch (err) {
    return ErrorHandler(err.message, 500, req, res);
  }
};

//login
const login = async (req, res) => {
  // #swagger.tags = ['auth']

  try {
    console.log(req.body);
    const { identifier, password } = req.body;

    console.log(identifier, password);
    if (!identifier || !password) {
      return ErrorHandler("Provide and Email/Phone or Password", 400, req, res);
    }

    const isEmail = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(identifier);
    const isPhone = /^\+?[0-9]{7,15}$/.test(identifier);

    console.log(isEmail, isPhone);

    if (!isEmail && !isPhone) {
      return ErrorHandler("Invalid Phone or Email Format", 400, req, res);
    }

    const user = await User.findOne(
      isEmail ? { email: identifier } : { phone: identifier }
    ).select("+password");

    if (!user) {
      return ErrorHandler(`User does not exist ${req.body}`, 400, req, res);
    }
    const isMatch = await user.comparePassword(password);
    if (!isMatch) {
      return ErrorHandler("Invalid credentials", 400, req, res);
    }
    // if (!user.emailVerified) {
    //   return ErrorHandler("Email not verified", 400, req, res);
    // }
    if (!user.isActive) {
      return ErrorHandler("Account deleted.", 400, req, res);
    }
    jwtToken = user.getJWTToken();
    delete user.password;

    console.log(jwtToken);

    SuccessHandler("Logged in successfully", 200, res, {
      token: jwtToken,
      role: user.role,
    });

    if (req.body.deviceToken) {
      user.deviceToken = req.body.deviceToken;
      await user.save();
    }
  } catch (error) {
    return ErrorHandler(error.message, 500, res);
  }
};

//logout
const logout = async (req, res) => {
  // #swagger.tags = ['auth']

  try {
    req.user = null;
    return SuccessHandler("Logged out successfully", 200, res);
  } catch (error) {
    return ErrorHandler(error.message, 500, req, res);
  }
};

//forgot password
const forgotPassword = async (req, res) => {
  // #swagger.tags = ['auth']
  try {
    const { email } = req.body;

    const user = await User.findOne({ email });
    if (!user) {
      return ErrorHandler("User does not exist", 400, req, res);
    }

    const passwordResetToken = Math.floor(100000 + Math.random() * 900000);
    const passwordResetTokenExpires = new Date(Date.now() + 60 * 60 * 1000); // 60 mins

    user.passwordResetToken = passwordResetToken;
    user.passwordResetTokenExpires = passwordResetTokenExpires;
    await user.save();

    await sendMail(email, passwordResetToken); // Using EmailJS
    console.log(`Reset token ${passwordResetToken} has been sent to ${email}`);

    return SuccessHandler(`Password reset token sent to ${email}`, 200, res);
  } catch (error) {
    return ErrorHandler(error.message, 500, req, res);
  }
};

// verify token
const verifyResetToken = async (req, res) => {
  // #swagger.tags = ['auth']
  try {
    const { email, passwordResetToken } = req.body;

    const user = await User.findOne({ email });
    if (!user) {
      return ErrorHandler("User does not exist", 400, req, res);
    }

    const isTokenValid =
      user.passwordResetToken === Number(passwordResetToken) &&
      user.passwordResetTokenExpires > Date.now();

    if (!isTokenValid) {
      return ErrorHandler("Invalid or expired token", 400, req, res);
    }

    return SuccessHandler("Token verified successfully", 200, res);
  } catch (error) {
    return ErrorHandler(error.message, 500, req, res);
  }
};

//reset password
const resetPassword = async (req, res) => {
  // #swagger.tags = ['auth']
  try {
    const { email, passwordResetToken, password } = req.body;

    const user = await User.findOne({ email }).select("+password");
    if (!user) {
      return ErrorHandler("User does not exist", 400, req, res);
    }

    const isTokenValid =
      user.passwordResetToken === Number(passwordResetToken) &&
      user.passwordResetTokenExpires > Date.now();

    if (!isTokenValid) {
      return ErrorHandler("Invalid or expired token", 400, req, res);
    }

    user.password = password;
    user.passwordResetToken = null;
    user.passwordResetTokenExpires = null;

    await user.save();

    return SuccessHandler("Password reset successfully", 200, res);
  } catch (error) {
    return ErrorHandler(error.message, 500, req, res);
  }
};

//update password
const updatePassword = async (req, res) => {
  // #swagger.tags = ['auth']

  try {
    const { currentPassword, newPassword } = req.body;
    // if (
    //   !newPassword.match(
    //     /(?=[A-Za-z0-9@#$%^&+!=]+$)^(?=.*[a-z])(?=.*[A-Z])(?=.*[0-9])(?=.*[@#$%^&+!=])(?=.{8,}).*$/
    //   )
    // ) {
    //   return ErrorHandler(
    //     "Password must contain at least 8 characters, 1 uppercase, 1 lowercase, 1 number and 1 special character",
    //     400,
    //     req,
    //     res
    //   );
    // }
    const user = await User.findById(req.user.id).select("+password");
    const isMatch = await user.comparePassword(currentPassword);
    if (!isMatch) {
      return ErrorHandler("Invalid credentials", 400, req, res);
    }
    const samePasswords = await user.comparePassword(newPassword);
    if (samePasswords) {
      return ErrorHandler(
        "New password cannot be same as old password",
        400,
        req,
        res
      );
    }
    user.password = newPassword;
    await user.save();
    return SuccessHandler("Password updated successfully", 200, res);
  } catch (error) {
    return ErrorHandler(error.message, 500, req, res);
  }
};

const deleteUserAccount = async (req, res) => {
  // #swagger.tags = ['auth']
  try {
    const user = await User.findById(req.user._id);
    if (!user) {
      return ErrorHandler("User not found", 400, req, res);
    }
    user.isActive = false;
    await user.save();
    return SuccessHandler("Account deleted successfully", 200, res);
  } catch (error) {
    return ErrorHandler(error.message, 500, req, res);
  }
};

module.exports = {
  register,
  requestEmailToken,
  verifyEmail,
  login,
  logout,
  forgotPassword,
  verifyResetToken,
  resetPassword,
  updatePassword,
  deleteUserAccount,
};
