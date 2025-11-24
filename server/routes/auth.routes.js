const express = require("express");
const router = express.Router();

// Import the controller
const authController = require("../controllers/auth.controllers.js");
const upload = require("../middleware/upload");
// Define the route for creating a doctor (with valid ID upload)
router.post("/doctors", upload.single("valid_id"), authController.registerDoctor);
router.post("/clients", authController.registerClient);
router.post("/admins", authController.registerAdmin);
router.post("/login", authController.login);
router.post("/verify", authController.verifyToken);
router.get("/profile", authController.getProfile);
router.post("/send-otp", authController.sendOtp);
router.get("/users/with-roles", authController.getUsersWithRoles);
router.post("/verify-otp", authController.verifyOtp);
router.put("/change-password", authController.changePassword);
router.put(
	"/change-profile-picture",
	upload.single("image"),
	authController.changeProfilePicture
);
router.post("/forgot-password", authController.forgotPassword);
router.put("/reset-password", authController.resetPassword);

// Admin routes for managing pending doctors
router.get("/pending-doctors", authController.getPendingDoctors);
router.put("/approve-doctor/:doctorId", authController.approveDoctor);
router.put("/reject-doctor/:doctorId", authController.rejectDoctor);

module.exports = router;
