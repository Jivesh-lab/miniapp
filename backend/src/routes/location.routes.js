import express from 'express';
import { authMiddleware } from '../middleware/auth.middleware.js';
import User from '../models/user.model.js';

// Create router
const router = express.Router();

/**
 * POST /api/users/update-location
 * Update user's current location (latitude, longitude)
 * 
 * Request:
 * {
 *   "latitude": 19.0176,
 *   "longitude": 73.0197
 * }
 * 
 * Response:
 * {
 *   "success": true,
 *   "message": "Location updated successfully",
 *   "data": {
 *     "userId": "user_id",
 *     "latitude": 19.0176,
 *     "longitude": 73.0197,
 *     "address": "Kalamboli",
 *     "lastLocationUpdate": "2026-04-23T10:30:00Z"
 *   }
 * }
 */
export const updateUserLocation = async (req, res) => {
  try {
    const { latitude, longitude } = req.body;
    const userId = req.user.id; // From auth middleware

    // Validate latitude and longitude
    if (latitude === undefined || longitude === undefined) {
      return res.status(400).json({
        success: false,
        message: 'Latitude and longitude are required',
      });
    }

    // Validate latitude range (-90 to 90)
    if (typeof latitude !== 'number' || latitude < -90 || latitude > 90) {
      return res.status(400).json({
        success: false,
        message: 'Invalid latitude. Must be between -90 and 90',
      });
    }

    // Validate longitude range (-180 to 180)
    if (typeof longitude !== 'number' || longitude < -180 || longitude > 180) {
      return res.status(400).json({
        success: false,
        message: 'Invalid longitude. Must be between -180 and 180',
      });
    }

    // Update user's location in database
    const updatedUser = await User.findByIdAndUpdate(
      userId,
      {
        latitude,
        longitude,
        lastLocationUpdate: new Date(),
      },
      { returnDocument: 'after', runValidators: true },
    );

    if (!updatedUser) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    // Return success response
    return res.status(200).json({
      success: true,
      message: 'Location updated successfully',
      data: {
        userId: updatedUser._id,
        latitude: updatedUser.latitude,
        longitude: updatedUser.longitude,
        address: updatedUser.address || 'Not set',
        lastLocationUpdate: updatedUser.lastLocationUpdate,
      },
    });
  } catch (error) {
    console.error('Error updating location:', error);
    return res.status(500).json({
      success: false,
      message: 'Error updating location',
    });
  }
};

/**
 * POST /api/users/update-profile
 * Update user profile including location and address
 * 
 * Request:
 * {
 *   "latitude": 19.0176,
 *   "longitude": 73.0197,
 *   "address": "Kalamboli, Mumbai"
 * }
 */
export const updateUserProfile = async (req, res) => {
  try {
    const { latitude, longitude, address } = req.body;
    const userId = req.user.id;

    // Build update object (only include fields that are provided)
    const updateData = {};

    if (latitude !== undefined && longitude !== undefined) {
      // Validate coordinates
      if (
        typeof latitude !== 'number' ||
        latitude < -90 ||
        latitude > 90 ||
        typeof longitude !== 'number' ||
        longitude < -180 ||
        longitude > 180
      ) {
        return res.status(400).json({
          success: false,
          message: 'Invalid coordinates',
        });
      }

      updateData.latitude = latitude;
      updateData.longitude = longitude;
      updateData.lastLocationUpdate = new Date();
    }

    if (address) {
      updateData.address = address;
    }

    // Update user
    const updatedUser = await User.findByIdAndUpdate(userId, updateData, {
      returnDocument: 'after',
      runValidators: true,
    });

    if (!updatedUser) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    return res.status(200).json({
      success: true,
      message: 'Profile updated successfully',
      data: updatedUser,
    });
  } catch (error) {
    console.error('Error updating profile:', error);
    return res.status(500).json({
      success: false,
      message: 'Error updating profile',
    });
  }
};

/**
 * GET /api/users/location
 * Get current user's location
 * 
 * Response:
 * {
 *   "success": true,
 *   "data": {
 *     "latitude": 19.0176,
 *     "longitude": 73.0197,
 *     "address": "Kalamboli",
 *     "lastLocationUpdate": "2026-04-23T10:30:00Z"
 *   }
 * }
 */
export const getUserLocation = async (req, res) => {
  try {
    const userId = req.user.id;

    const user = await User.findById(userId).select(
      'latitude longitude address lastLocationUpdate',
    );

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    if (!user.latitude || !user.longitude) {
      return res.status(200).json({
        success: true,
        message: 'User has no location set',
        data: null,
      });
    }

    return res.status(200).json({
      success: true,
      data: {
        latitude: user.latitude,
        longitude: user.longitude,
        address: user.address || 'Not set',
        lastLocationUpdate: user.lastLocationUpdate,
      },
    });
  } catch (error) {
    console.error('Error getting user location:', error);
    return res.status(500).json({
      success: false,
      message: 'Error fetching location',
    });
  }
};

/**
 * GET /api/users/nearby
 * Get nearby users (workers) based on user's location
 * 
 * Query Parameters:
 * - radius: Search radius in kilometers (default: 10)
 * - serviceId: Filter by service (optional)
 * 
 * Response:
 * {
 *   "success": true,
 *   "data": [
 *     {
 *       "_id": "user_id",
 *       "name": "John Doe",
 *       "latitude": 19.02,
 *       "longitude": 73.02,
 *       "distance": 2.5,
 *       "address": "Kalamboli"
 *     }
 *   ]
 * }
 */
export const getNearbyUsers = async (req, res) => {
  try {
    const userId = req.user.id;
    const { radius = 10 } = req.query;

    // Get current user's location
    const currentUser = await User.findById(userId).select(
      'latitude longitude',
    );

    if (!currentUser || !currentUser.latitude || !currentUser.longitude) {
      return res.status(400).json({
        success: false,
        message: 'User location not set',
      });
    }

    // Find all users with location
    const allUsers = await User.find({
      _id: { $ne: userId }, // Exclude current user
      latitude: { $exists: true, $ne: null },
      longitude: { $exists: true, $ne: null },
    }).select('_id name latitude longitude address');

    // Calculate distance using Haversine formula
    const nearbyUsers = allUsers
      .map((user) => ({
        ...user.toObject(),
        distance: calculateDistance(
          currentUser.latitude,
          currentUser.longitude,
          user.latitude,
          user.longitude,
        ),
      }))
      .filter((user) => user.distance <= radius) // Filter by radius
      .sort((a, b) => a.distance - b.distance); // Sort by distance

    return res.status(200).json({
      success: true,
      message: `Found ${nearbyUsers.length} nearby users`,
      data: nearbyUsers,
    });
  } catch (error) {
    console.error('Error getting nearby users:', error);
    return res.status(500).json({
      success: false,
      message: 'Error fetching nearby users',
    });
  }
};

/**
 * Haversine formula to calculate distance between two coordinates
 * Returns distance in kilometers
 * 
 * Formula:
 * a = sin²(Δlat/2) + cos(lat1) * cos(lat2) * sin²(Δlong/2)
 * c = 2 * atan2(√a, √(1−a))
 * d = R * c
 * where R is earth's radius (6,371 km)
 */
function calculateDistance(lat1, lon1, lat2, lon2) {
  const R = 6371; // Earth's radius in kilometers
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lon2 - lon1) * Math.PI) / 180;

  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);

  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  const distance = R * c; // Distance in km

  return Math.round(distance * 10) / 10; // Round to 1 decimal place
}

// Export router with all routes
router.post('/update-location', authMiddleware, updateUserLocation);
router.post('/update-profile', authMiddleware, updateUserProfile);
router.get('/location', authMiddleware, getUserLocation);
router.get('/nearby', authMiddleware, getNearbyUsers);

export default router;
