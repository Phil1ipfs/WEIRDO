const express = require("express");
const router = express.Router();
const adminController = require("../controllers/admin.controllers.js");

// Client approval routes - multiple paths for compatibility
router.put("/approve/:user_id", adminController.approveClient);
router.put("/approve-client/:user_id", adminController.approveClient);
router.put("/clients/:user_id/approve", adminController.approveClient);

// Doctor approval routes
router.put("/approve-doctor/:user_id", adminController.approveDoctor);
router.put("/doctors/:user_id/approve", adminController.approveDoctor);

router.put("/profile", adminController.updateAdminProfile);
router.get("/profile", adminController.getAdminProfile);

module.exports = router;
