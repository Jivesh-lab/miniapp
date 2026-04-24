import mongoose from "mongoose";

const userSchema = new mongoose.Schema(
  {
    userId: {
      type: String,
      trim: true,
      unique: true,
      sparse: true,
      index: true,
    },
    name: {
      type: String,
      required: true,
      trim: true,
    },
    email: {
      type: String,
      required: true,
      trim: true,
      lowercase: true,
      unique: true,
    },
    phone: {
      type: String,
      required: true,
      trim: true,
      unique: true,
    },
    password: {
      type: String,
      trim: true,
      select: false,
    },
    role: {
      type: String,
      enum: ["user"],
      default: "user",
    },
    favoriteWorkers: {
      type: [
        {
          type: mongoose.Schema.Types.ObjectId,
          ref: "Worker",
        },
      ],
      default: [],
    },
    latitude: {
      type: Number,
      default: null,
      min: -90,
      max: 90,
      index: true,
    },
    longitude: {
      type: Number,
      default: null,
      min: -180,
      max: 180,
      index: true,
    },
    address: {
      type: String,
      default: null,
      trim: true,
    },
    lastLocationUpdate: {
      type: Date,
      default: null,
      index: true,
    },
  },
  {
    timestamps: true,
    versionKey: false,
  }
);

userSchema.index({ favoriteWorkers: 1 });
userSchema.index({ latitude: 1, longitude: 1 });

export default mongoose.model("User", userSchema);
