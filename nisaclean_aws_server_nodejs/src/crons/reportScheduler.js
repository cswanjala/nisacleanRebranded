// src/crons/reportScheduler.js
const cron = require("node-cron");
const { generateReportByPeriod } = require("../controllers/reportsController");

// Daily report at 2 AM
cron.schedule("0 2 * * *", async () => {
  console.log("Running Daily Report at 2AM...");
  await generateReportByPeriod("daily");
});

// Weekly report on Thursday at 12 PM
cron.schedule("10 12 * * 4", async () => {
  console.log("Running Weekly Report on Thursday 12PM...");
  await generateReportByPeriod("weekly");
});

// Monthly report on the 1st of the month at 2 AM
cron.schedule("0 2 1 * *", async () => {
  console.log("Running Monthly Report on 1st of Month at 2AM...");
  await generateReportByPeriod("monthly");
});
