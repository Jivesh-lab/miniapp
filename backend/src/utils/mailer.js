import nodemailer from "nodemailer";

const buildTransporter = () => {
  const smtpHost = process.env.SMTP_HOST;
  const smtpPort = process.env.SMTP_PORT;
  const smtpUser = process.env.SMTP_USER;
  const smtpPass = process.env.SMTP_PASS;

  if (smtpHost && smtpPort && smtpUser && smtpPass) {
    return nodemailer.createTransport({
      host: smtpHost,
      port: Number(smtpPort),
      secure: String(smtpPort) === "465",
      auth: {
        user: smtpUser,
        pass: smtpPass,
      },
    });
  }

  const gmailUser = process.env.GMAIL_USER;
  const gmailAppPassword = process.env.GMAIL_APP_PASSWORD;

  if (gmailUser && gmailAppPassword) {
    // Using explicit Gmail SMTP settings tends to be more reliable than `service: "gmail"`.
    return nodemailer.createTransport({
      host: "smtp.gmail.com",
      port: 465,
      secure: true,
      auth: {
        user: gmailUser,
        pass: gmailAppPassword,
      },
    });
  }

  throw new Error(
    "Email is not configured. Set SMTP_HOST/SMTP_PORT/SMTP_USER/SMTP_PASS or GMAIL_USER/GMAIL_APP_PASSWORD."
  );
};

export const sendOtpEmail = async ({ to, otp }) => {
  const transporter = buildTransporter();

  const from = process.env.EMAIL_FROM || process.env.GMAIL_USER || process.env.SMTP_USER;

  if (!from) {
    throw new Error("EMAIL_FROM is not configured");
  }

  try {
    await transporter.sendMail({
      from,
      to,
      subject: "Your OTP Code",
      text: `Your OTP code is: ${otp}. It expires in 10 minutes.`,
    });
  } catch (error) {
    const message = String(error?.message || error);
    const code = error?.code || error?.responseCode;

    throw new Error(`Email send failed${code ? ` (${code})` : ""}: ${message}`);
  }
};
