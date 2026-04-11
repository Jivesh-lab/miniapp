import mongoose from "mongoose";

const blacklistSchema = new mongoose.Schema(
  {
    token: {
      type: String,
      required: true,
      unique: true,
      index: true,
    },
    expiresAt: {
      type: Date,
      required: true,
    },
  },
  {
    timestamps: true,
    versionKey: false,
  }
);

blacklistSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });

export default mongoose.model("Blacklist", blacklistSchema);