const jwt = require("jsonwebtoken");
const { User, Admin, Client, Doctor } = require("../models");
require("dotenv").config();

exports.updateAdminProfile = async (req, res) => {
	try {
		const token = req.headers.authorization?.split(" ")[1]; // Expect "Bearer <token>"

		if (!token) {
			return res.status(401).json({ message: "Authorization token missing." });
		}

		// Decode token
		const decoded = jwt.verify(token, process.env.JWT_SECRET);
		const userId = decoded.user_id;

		const { email, first_name, middle_name, last_name, contact_number } =
			req.body;

		// Update User email
		await User.update({ email }, { where: { user_id: userId } });

		// Find Admin profile
		const admin = await Admin.findOne({ where: { user_id: userId } });
		if (!admin) return res.status(404).json({ message: "Admin not found" });

		// Update Admin profile
		await admin.update({
			first_name,
			middle_name,
			last_name,
			contact_number,
		});

		res.json({ message: "Admin profile updated successfully" });
	} catch (err) {
		console.error("Error updating admin profile:", err);
		res.status(500).json({ message: "Server error" });
	}
};

exports.getAdminProfile = async (req, res) => {
	try {
		const token = req.headers.authorization?.split(" ")[1]; // Expect "Bearer <token>"

		if (!token) {
			return res.status(401).json({ message: "Authorization token missing." });
		}

		const admin = await Admin.findOne();

		if (!admin) {
			return res.status(404).json({ message: "Admin profile not found." });
		}

		res.json({ admin });
	} catch (err) {
		console.error("Error fetching admin profile:", err);
		res.status(500).json({ message: "Server error" });
	}
};

exports.approveClient = async (req, res) => {
	try {
		const token = req.headers.authorization?.split(" ")[1];
		if (!token) {
			return res.status(401).json({ message: "Authorization token missing." });
		}

		// Verify admin token
		const decoded = jwt.verify(token, process.env.JWT_SECRET);
		const adminUser = await User.findOne({
			where: { user_id: decoded.user_id, role: "admin" },
		});

		if (!adminUser) {
			return res.status(403).json({ message: "Unauthorized. Admin access required." });
		}

		const { user_id } = req.params;

		// Find the client user
		const clientUser = await User.findByPk(user_id);
		
		if (!clientUser || clientUser.role !== "client") {
			return res.status(404).json({ message: "Client not found." });
		}

		// Check if already approved
		if (clientUser.status === "enabled") {
			return res.status(400).json({ message: "Client is already approved." });
		}

		// Update user status to enabled
		await User.update(
			{ status: "enabled" },
			{ where: { user_id } }
		);

		// Update client status to enabled
		await Client.update(
			{ status: "enabled" },
			{ where: { user_id } }
		);

		res.json({
			success: true,
			message: "Client approved successfully.",
		});
	} catch (err) {
		console.error("Error approving client:", err);
		res.status(500).json({ message: "Server error", error: err.message });
	}
};

exports.approveDoctor = async (req, res) => {
	try {
		const token = req.headers.authorization?.split(" ")[1];
		if (!token) {
			return res.status(401).json({ message: "Authorization token missing." });
		}

		// Verify admin token
		const decoded = jwt.verify(token, process.env.JWT_SECRET);
		const adminUser = await User.findOne({
			where: { user_id: decoded.user_id, role: "admin" },
		});

		if (!adminUser) {
			return res.status(403).json({ message: "Unauthorized. Admin access required." });
		}

		const { user_id } = req.params;

		// Find the doctor user
		const doctorUser = await User.findByPk(user_id);
		
		if (!doctorUser || doctorUser.role !== "doctor") {
			return res.status(404).json({ message: "Doctor not found." });
		}

		// Check if already approved
		if (doctorUser.status === "enabled") {
			return res.status(400).json({ message: "Doctor is already approved." });
		}

		// Update user status to enabled
		await User.update(
			{ status: "enabled" },
			{ where: { user_id } }
		);

		// Update doctor status to enabled
		await Doctor.update(
			{ status: "enabled" },
			{ where: { user_id } }
		);

		res.json({
			success: true,
			message: "Doctor approved successfully.",
		});
	} catch (err) {
		console.error("Error approving doctor:", err);
		res.status(500).json({ message: "Server error", error: err.message });
	}
};
