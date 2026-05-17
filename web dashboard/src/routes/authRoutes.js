const express = require("express");
const authController = require("../controllers/authController");

const router = express.Router();

router.get("/", (req, res) => {
  if (req.session.user) {
    return res.redirect("/dashboard");
  }
  return res.redirect("/login");
});
router.get("/login", authController.showLoginPage);
router.post("/login/request-otp", authController.requestOtp);
router.post("/login/verify-otp", authController.verifyOtp);
router.post("/logout", authController.logout);

module.exports = router;
