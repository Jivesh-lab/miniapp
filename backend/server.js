import dotenv from "dotenv";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Always load backend/.env (even if node is started from another working directory).
dotenv.config({ path: path.join(__dirname, ".env") });

const { default: app } = await import("./src/app.js");
const { default: connectDB } = await import("./src/config/db.js");
const { initSocket } = await import("./src/socket.js");

let server;

process.on("uncaughtException", (error) => {
  console.error("Uncaught exception:", error);

  if (server) {
    server.close(() => {
      process.exit(1);
    });
    return;
  }

  process.exit(1);
});

process.on("unhandledRejection", (reason) => {
  console.error("Unhandled rejection:", reason);
});

const startServer = async () => {
  try {
    await connectDB();

    const port = process.env.PORT || 3000;
    const env = process.env.NODE_ENV || "development";
    
    server = app.listen(port, "0.0.0.0", () => {
      console.log(`✅ Server running on port ${port} (${env})`);
      console.log(`📍 Listening on 0.0.0.0:${port}`);
    });

    initSocket(server);

    server.on("error", (error) => {
      console.error("❌ Server error:", error);
    });
  } catch (error) {
    console.error("❌ Failed to start server:", error);
    process.exit(1);
  }
};

startServer();