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
          user: {
            type: String,
            required: true,
            trim: true,
          },
          comment: {
            type: String,
            required: true,
            trim: true,
          },
          rating: {
            type: Number,
            required: true,
            min: 1,
            max: 5,
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
