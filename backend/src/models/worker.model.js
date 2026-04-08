import mongoose from "mongoose";

const workerSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: true,
      trim: true,
    },
    serviceId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Service",
      required: true,
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
      required: true,
      min: 0,
    },
    location: {
      type: String,
      required: true,
      trim: true,
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
