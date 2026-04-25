import { Server } from "socket.io";
import jwt from "jsonwebtoken";

const JWT_SECRET = process.env.JWT_SECRET || "dev_worker_jwt_secret";

let io;

export const initSocket = (server) => {
  io = new Server(server, {
    cors: {
      origin: "*",
      methods: ["GET", "POST"]
    }
  });

  io.use((socket, next) => {
    try {
      const token = socket.handshake.auth?.token;
      if (!token) {
        return next(new Error("Authentication error: No token provided"));
      }

      const decoded = jwt.verify(token, JWT_SECRET);
      socket.user = decoded; 
      // decoded contains { userId: "...", role: "..." }
      next();
    } catch (err) {
      return next(new Error("Authentication error: Invalid token"));
    }
  });

  io.on("connection", (socket) => {
    console.log(`User connected to socket: ${socket.user.userId} (${socket.user.role})`);
    
    // Join a private room with their user/worker ID
    socket.join(socket.user.userId);

    socket.on("disconnect", () => {
      console.log(`User disconnected: ${socket.user.userId}`);
    });
  });

  return io;
};

export const getIO = () => {
  if (!io) {
    throw new Error("Socket.io not initialized!");
  }
  return io;
};
