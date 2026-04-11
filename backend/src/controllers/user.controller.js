import User from "../models/user.model.js";
import Worker from "../models/worker.model.js";

const findUserByIdentifier = async (identifier) => {
  const byCustomId = await User.findOne({ userId: identifier });
  if (byCustomId) return byCustomId;

  if (identifier && identifier.match(/^[0-9a-fA-F]{24}$/)) {
    return User.findById(identifier);
  }

  return null;
};

const ensureAuthenticatedUser = async (req, res, identifier) => {
  const authUserId = String(req.user?.id ?? "").trim();

  if (!authUserId) {
    return { error: res.status(401).json({ success: false, message: "Unauthorized" }) };
  }

  const authUser = await findUserByIdentifier(authUserId);

  if (!authUser) {
    return { error: res.status(401).json({ success: false, message: "Unauthorized" }) };
  }

  const targetUser = await findUserByIdentifier(String(identifier ?? "").trim());

  if (!targetUser) {
    return { error: res.status(404).json({ success: false, message: "User not found" }) };
  }

  if (String(authUser._id) !== String(targetUser._id)) {
    return { error: res.status(403).json({ success: false, message: "Forbidden" }) };
  }

  return { user: targetUser };
};

export const createUser = async (req, res) => {
  try {
    const authUserId = String(req.user?.id ?? "").trim();
    if (!authUserId) {
      return res.status(401).json({
        success: false,
        message: "Unauthorized",
      });
    }

    const { userId, name, email, phone } = req.body;

    if (!name || !email || !phone) {
      return res.status(400).json({
        success: false,
        message: "name, email, and phone are required",
      });
    }

    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return res.status(400).json({
        success: false,
        message: "Invalid email format",
      });
    }

    const phoneRegex = /^[0-9]{10,15}$/;
    if (!phoneRegex.test(String(phone))) {
      return res.status(400).json({
        success: false,
        message: "Invalid phone format",
      });
    }

    const existingUser = await User.findOne({ email: email.toLowerCase() }).lean();
    if (existingUser) {
      return res.status(400).json({
        success: false,
        message: "User with this email already exists",
      });
    }

    const user = await User.create({ userId, name, email, phone });

    return res.status(201).json({
      success: true,
      message: "User created successfully",
      data: user,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to create user",
      error: error.message,
    });
  }
};

export const getUserProfile = async (req, res) => {
  try {
    const userId = String(req.user?.id ?? "").trim();

    if (!userId) {
      return res.status(401).json({
        success: false,
        message: "Unauthorized",
      });
    }

    const user = await findUserByIdentifier(userId);

    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      });
    }

    const profile = await User.findById(user._id)
      .populate("favoriteWorkers", "name rating price location")
      .lean();

    return res.status(200).json({
      success: true,
      data: profile,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to fetch user profile",
      error: error.message,
    });
  }
};

export const getUserById = async (req, res) => {
  try {
    const { id } = req.params;

    const access = await ensureAuthenticatedUser(req, res, id);
    if (access.error) {
      return access.error;
    }

    if (!id) {
      return res.status(400).json({
        success: false,
        message: "User id is required",
      });
    }

    const userDoc = access.user;
    const user = userDoc ? userDoc.toObject() : null;

    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      });
    }

    return res.status(200).json({
      success: true,
      data: user,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to fetch user",
      error: error.message,
    });
  }
};

export const updateUser = async (req, res) => {
  try {
    const { id } = req.params;
    const { name, phone } = req.body;

    const access = await ensureAuthenticatedUser(req, res, id);
    if (access.error) {
      return access.error;
    }

    const existing = access.user;

    if (!existing) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      });
    }

    const user = await User.findByIdAndUpdate(
      existing._id,
      { name, phone },
      { new: true, runValidators: true }
    ).lean();

    return res.status(200).json({
      success: true,
      message: "User updated successfully",
      data: user,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to update user",
      error: error.message,
    });
  }
};

export const getFavoriteWorkers = async (req, res) => {
  try {
    const { userId } = req.params;

    const access = await ensureAuthenticatedUser(req, res, userId);
    if (access.error) {
      return access.error;
    }

    const user = await User.findById(access.user._id)
      .populate("favoriteWorkers", "name rating price location")
      .lean();

    return res.status(200).json({
      success: true,
      count: user.favoriteWorkers.length,
      data: user.favoriteWorkers,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to fetch favorites",
      error: error.message,
    });
  }
};

export const addFavoriteWorker = async (req, res) => {
  try {
    const { userId, workerId } = req.body;

    if (!userId || !workerId) {
      return res.status(400).json({
        success: false,
        message: "userId and workerId are required",
      });
    }

    const worker = await Worker.findById(workerId).lean();
    if (!worker) {
      return res.status(404).json({
        success: false,
        message: "Worker not found",
      });
    }

    const access = await ensureAuthenticatedUser(req, res, userId);
    if (access.error) {
      return access.error;
    }

    const user = access.user;

    const exists = user.favoriteWorkers.some((id) => id.toString() === workerId);

    if (exists) {
      user.favoriteWorkers = user.favoriteWorkers.filter(
        (id) => id.toString() !== workerId
      );
    } else {
      user.favoriteWorkers.push(workerId);
    }

    await user.save();

    return res.status(200).json({
      success: true,
      message: exists ? "Favorite removed" : "Favorite added",
      isFavorite: !exists,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to toggle favorite",
      error: error.message,
    });
  }
};
