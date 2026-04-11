import mongoose from "mongoose";

const bookingSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    workerId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Worker",
      required: true,
    },
    date: {
      type: String,
      required: true,
      trim: true,
    },
    time: {
      type: String,
      required: true,
      trim: true,
    },
    rating: {
      type: Number,
      min: 1,
      max: 5,
    },
    review: {
      type: String,
      trim: true,
      maxlength: 500,
    },
    comment: {
      type: String,
      trim: true,
      maxlength: 500,
    },
    isRated: {
      type: Boolean,
      default: false,
    },
    address: {
      type: String,
      required: true,
      trim: true,
    },
    status: {
      type: String,
      enum: ["pending", "confirmed", "rejected", "completed", "cancelled", "in-progress"],
      default: "pending",
    },
  },
  {
    timestamps: true,
    versionKey: false,
  }
);

bookingSchema.index({ workerId: 1, date: 1, time: 1 }, { unique: true });
bookingSchema.index({ userId: 1 });
bookingSchema.index({ workerId: 1 });
bookingSchema.index({ status: 1, isRated: 1 });

export default mongoose.model("Booking", bookingSchema);
