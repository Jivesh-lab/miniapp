import express from 'express';
import cors from 'cors';
import workerRoutes from "./routes/worker.routes.js";

const app = express();

app.use(cors());
app.use(express.json());

app.use("/api/workers", workerRoutes);

app.get('/', (req, res) => {
  res.send('API is running...');
});

export default app;