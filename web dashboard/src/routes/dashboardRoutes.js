const express = require("express");
const dashboardController = require("../controllers/dashboardController");
const ensureAuthenticated = require("../middleware/authMiddleware");
const checkAdminApiMiddleware = require("../middleware/checkAdminApiMiddleware");
const uploadSliderImage = require("../middleware/uploadMiddleware");

const router = express.Router();
const dashboardGuard = [ensureAuthenticated, checkAdminApiMiddleware];

router.get("/dashboard", dashboardGuard, dashboardController.showOverview);
router.get("/dashboard/users", dashboardGuard, dashboardController.showUsers);
router.get("/dashboard/verifications", dashboardGuard, dashboardController.showVerifications);
router.post(
  "/dashboard/verifications/practice-license/:userId",
  ...dashboardGuard,
  dashboardController.decidePracticeLicense,
);
router.post(
  "/dashboard/verifications/course/:userId/:courseId",
  ...dashboardGuard,
  dashboardController.decideAccreditedCourse,
);
router.get("/dashboard/jobs", dashboardGuard, dashboardController.showJobs);
router.post("/dashboard/jobs/:jobId/status", dashboardGuard, dashboardController.updateJobStatus);
router.post("/dashboard/jobs/:jobId/delete", dashboardGuard, dashboardController.deleteJob);
router.get("/dashboard/notifications", dashboardGuard, dashboardController.showNotifications);
router.post(
  "/dashboard/notifications/send",
  ...dashboardGuard,
  dashboardController.sendAppAnnouncement,
);
router.get("/dashboard/sliders", dashboardGuard, dashboardController.showSliders);
router.post(
  "/dashboard/sliders/add",
  ...dashboardGuard,
  uploadSliderImage.single("imageFile"),
  dashboardController.addSlider,
);
router.post("/dashboard/sliders/:sliderId/delete", ...dashboardGuard, dashboardController.deleteSlider);

module.exports = router;
