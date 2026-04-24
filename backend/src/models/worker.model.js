import mongoose from "mongoose";

const workerSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: true,
      trim: true,
    },
    phone: {
      type: String,
      required: true,
      trim: true,
      unique: true,
    },
    password: {
      type: String,
      required: true,
      select: false,
    },
    serviceId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Service",
      default: null,
    },
    rating: {
      type: Number,
      default: 0,
      min: 0,
      max: 5,
    },
    ratingCount: {
      type: Number,
      default: 0,
      min: 0,
    },
    ratingSum: {
      type: Number,
      default: 0,
      min: 0,
    },
    price: {
      type: Number,
      min: 0,
      default: 0,
    },
    location: {
      type: String,
      trim: true,
      default: "",
    },
    skills: {
      type: [String],
      default: [],
    },
    reviews: {
      type: [
        {
          userId: {
            type: String,
            required: true,
            trim: true,
          },
          comment: {
            type: String,
            trim: true,
            default: "",
            maxlength: 500,
          },
          rating: {
            type: Number,
            required: true,
            min: 1,
            max: 5,
          },
          createdAt: {
            type: Date,
            default: Date.now,
          },
        },
      ],
      default: [],
    },
    availableSlots: {
      type: [
        {
          date: {
            type: String,
            required: true,
            trim: true,
          },
          timeSlots: {
            type: [String],
            default: [],
          },
        },
      ],
      default: [],
    },
    latitude: {
      type: Number,
      default: null,
      index: true,
    },
    longitude: {
      type: Number,
      default: null,
      index: true,
    },
    isOnline: {
      type: Boolean,
      default: false,
      index: true,
    },
    lastLocationUpdate: {
      type: Date,
      default: null,
    },
    role: {
      type: String,
      default: "worker",
      enum: ["worker"],
    },
  },
  {
    timestamps: true,
    versionKey: false,
  }
);

workerSchema.index({ serviceId: 1 });
workerSchema.index({ rating: -1 });
workerSchema.index({ price: 1 });

export default mongoose.model("Worker", workerSchema);
