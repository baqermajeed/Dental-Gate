const express = require("express");
const dashboardController = require("../controllers/dashboardController");
const ensureAuthenticated = require("../middleware/authMiddleware");
const uploadSliderImage = require("../middleware/uploadMiddleware");

const router = express.Router();

router.get("/dashboard", ensureAuthenticated, dashboardController.showDashboard);
router.post(
  "/dashboard/sliders",
  ensureAuthenticated,
  uploadSliderImage.single("imageFile"),
  dashboardController.addSlider,
);
router.post(
  "/dashboard/notifications",
  ensureAuthenticated,
  dashboardController.sendAppAnnouncement,
);

module.exports = router;
