const app = require("./app");
const dotenv = require("dotenv");
const connectDB = require("./config/db");
const http = require("http");
const socket = require("socket.io");
const { addUser, removeUser } = require("./functions/socketFunctions");

dotenv.config({ path: "./src/config/config.env" }); //load env vars

//global vars
global.io; 
global.onlineUsers = [];

//server setup
const PORT = process.env.PORT || 8000;

var server = http.createServer(app);
server.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
  connectDB();
});

const allowOrigins = [
  "https://nisaclean.com",
  "http://localhost:3000",  // for development
  "http://localhost:3001",
  "http://localhost:5000",
    "http://localhost:5173"
];
//socket.io
// In index.js, make consistent with your CORS:
global.io = socket(server, {
  cors: {
    origin: allowOrigins,  // Use the same origins array
    methods: ["GET", "POST"],
    credentials: true
  }
});

global.io.on("connection", (socket) => {
  console.log("connected to socket", socket.id);
  global.io.to(socket.id).emit("reconnect", socket.id);
  socket.on("join", (userId) => {
    addUser(userId, socket.id);
  });
  socket.on("logout", () => {
    removeUser(socket.id);
  });
  socket.on("disconnect", () => {
    removeUser(socket.id);
    console.log("user disconnected", socket.id);
  });
});
