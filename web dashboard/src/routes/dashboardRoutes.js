const express = require("express");
const dashboardController = require("../controllers/dashboardController");
const ensureAuthenticated = require("../middleware/authMiddleware");
const uploadSliderImage = require("../middleware/uploadMiddleware");

const router = express.Router();

router.get("/dashboard", ensureAuthenticated, dashboardController.showOverview);
router.get("/dashboard/users", ensureAuthenticated, dashboardController.showUsers);
router.get("/dashboard/verifications", ensureAuthenticated, dashboardController.showVerifications);
router.post(
  "/dashboard/verifications/practice-license/:userId",
  ensureAuthenticated,
  dashboardController.decidePracticeLicense,
);
router.post(
  "/dashboard/verifications/course/:userId/:courseId",
  ensureAuthenticated,
  dashboardController.decideAccreditedCourse,
);
router.get("/dashboard/jobs", ensureAuthenticated, dashboardController.showJobs);
router.post("/dashboard/jobs/:jobId/status", ensureAuthenticated, dashboardController.updateJobStatus);
router.post("/dashboard/jobs/:jobId/delete", ensureAuthenticated, dashboardController.deleteJob);
router.get("/dashboard/notifications", ensureAuthenticated, dashboardController.showNotifications);
router.post(
  "/dashboard/notifications/send",
  ensureAuthenticated,
  dashboardController.sendAppAnnouncement,
);
router.get("/dashboard/sliders", ensureAuthenticated, dashboardController.showSliders);
router.post(
  "/dashboard/sliders/add",
  ensureAuthenticated,
  uploadSliderImage.single("imageFile"),
  dashboardController.addSlider,
);
router.post("/dashboard/sliders/:sliderId/delete", ensureAuthenticated, dashboardController.deleteSlider);

module.exports = router;
