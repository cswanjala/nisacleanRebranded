// src/utils/validateEnv.js

function validateEnv() {
  const requiredVars = ["PORT", "MONGO_URI"];
  const missing = requiredVars.filter((v) => !process.env[v]);

  if (missing.length > 0) {
    console.error(
      `❌ Missing required environment variables: ${missing.join(", ")}`
    );
    process.exit(1);
  }
}

module.exports = { validateEnv };
