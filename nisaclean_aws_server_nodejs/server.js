// server.js

const http = require("http");
const app = require("./src/app"); // your Express app
const mongoose = require("mongoose");
const dotenv = require("dotenv");
const { validateEnv } = require("./src/utils/validateEnv");

dotenv.config();

// --- Global Error Handlers ---

process.on("uncaughtException", (err) => {
  console.error("💥 UNCAUGHT EXCEPTION 💥", err);
  process.exit(1); // Always crash so PM2/Docker can restart cleanly
});

process.on("unhandledRejection", (reason, promise) => {
  console.error("💥 UNHANDLED REJECTION 💥", reason);
  process.exit(1);
});

// --- Validate Required Environment Variables ---
validateEnv();

// --- Connect to MongoDB ---
mongoose
  .connect(process.env.MONGO_URI)
  .then(() => console.log("✅ DB connected"))
  .catch((err) => {
    console.error("❌ MongoDB connection error:", err);
    process.exit(1);
  });

// --- Start Server ---
const PORT = process.env.PORT || 8000;

const server = http.createServer(app);

server.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
});
