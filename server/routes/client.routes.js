const express = require("express");
const router = express.Router();

// Import the controller
const controller = require("../controllers/client.controllers.js");
const adminController = require("../controllers/admin.controllers.js");

router.get("/all", controller.getAllClients);
router.put("/profile", controller.updateProfile);
router.get("/dashboard", controller.getClientDashboard);
// Admin route for approving clients (accessible via /api/clients/approve/:user_id)
router.put("/approve/:user_id", adminController.approveClient);

module.exports = router;
