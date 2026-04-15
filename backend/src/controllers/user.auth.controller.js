import { login, registerUser as registerUserUnified } from "./auth.controller.js";

export const registerUser = registerUserUnified;

export const loginUser = (req, res) => {
  req.body = {
    ...(req.body ?? {}),
    role: "user",
  };

  return login(req, res);
};
