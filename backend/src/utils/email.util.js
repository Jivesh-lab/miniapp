import { sendOtpEmail as sendConfiguredOtpEmail } from "./mailer.js";

export const sendOtpEmail = async (to, otp) => {
  return sendConfiguredOtpEmail({ to, otp });
};
