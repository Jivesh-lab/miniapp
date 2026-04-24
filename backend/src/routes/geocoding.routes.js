import express from "express";
import { getCity } from "../controllers/geocoding.controller.js";

const router = express.Router();

router.post("/get-city", getCity);

export default router;