import { getCityFromCoordinates, validateLatLng } from "../services/geocoding.service.js";

export async function getCity(req, res) {
  try {
    const { lat, lng } = req.body;

    const validationError = validateLatLng(lat, lng);
    if (validationError) {
      return res.status(400).json({
        success: false,
        city: "Unknown",
        message: validationError,
      });
    }

    const city = await getCityFromCoordinates(lat, lng);

    return res.status(200).json({
      success: true,
      city: city || "Unknown",
    });
  } catch (error) {
    console.error("Reverse geocoding failed:", error);
    return res.status(200).json({
      success: false,
      city: "Unknown",
    });
  }
}