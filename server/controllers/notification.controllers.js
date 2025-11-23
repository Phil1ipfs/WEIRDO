const jwt = require("jsonwebtoken");
const db = require("../models");
const Notification = db.Notification;
require("dotenv").config();

exports.getNotificationsByToken = async (req, res) => {
	try {
		const authHeader = req.headers.authorization;

		if (!authHeader || !authHeader.startsWith("Bearer ")) {
			return res.status(401).json({
				success: false,
				message: "Authorization header missing or invalid",
			});
		}

		const token = authHeader.split(" ")[1];

		const decoded = jwt.verify(token, process.env.JWT_SECRET);
		const user_id = decoded.user_id;

		if (!user_id) {
			return res
				.status(401)
				.json({ success: false, message: "Invalid token or user not found" });
		}

		// 📬 Fetch notifications for this user
		const notifications = await Notification.findAll({
			where: { user_id },
			order: [["created_at", "DESC"]],
		});

		return res.status(200).json({
			success: true,
			user_id,
			count: notifications.length,
			notifications,
		});
	} catch (error) {
		console.error("Error fetching notifications:", error);
		return res.status(500).json({
			success: false,
			message: "Error fetching notifications",
			error: error.message,
		});
	}
};
