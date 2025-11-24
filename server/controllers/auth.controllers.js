const bcrypt = require("bcrypt");
const db = require("../models");
const jwt = require("jsonwebtoken");
const { Op } = require("sequelize");

const User = db.User;
const Doctor = db.Doctor;
const Client = db.Client;
const Admin = db.Admin;
const Field = db.Field;
const OTP = db.OTP;

// Password validation helper function
function validatePassword(password) {
	if (!password || password.length < 6) {
		return "Password must be at least 6 characters";
	}
	// Check if alphanumeric only (letters and numbers, no special characters)
	if (!/^[a-zA-Z0-9]+$/.test(password)) {
		return "Password must contain only letters and numbers";
	}
	// Check for at least one uppercase letter
	if (!/[A-Z]/.test(password)) {
		return "Password must contain at least one uppercase letter";
	}
	// Check for at least one lowercase letter
	if (!/[a-z]/.test(password)) {
		return "Password must contain at least one lowercase letter";
	}
	// Check for at least one number
	if (!/[0-9]/.test(password)) {
		return "Password must contain at least one number";
	}
	return null; // Password is valid
}

exports.registerDoctor = async (req, res) => {
	const t = await db.sequelize.transaction();
	try {
		const {
			first_name,
			middle_name,
			gender,
			last_name,
			field_id,
			contact_number,
			valid_id,
			id_number,
			email,
			password,
		} = req.body;

		// Get uploaded file path if exists
		const validIdImagePath = req.file ? req.file.filename : null;

		// Validate password
		const passwordError = validatePassword(password);
		if (passwordError) {
			await t.rollback();
			return res.status(400).json({
				message: passwordError,
			});
		}

		// Check if a user with the email already exists
		const existingUser = await User.findOne({
			where: { email },
			transaction: t,
		});

		if (existingUser) {
			await t.rollback();
			return res
				.status(400)
				.json({ message: "User with this email already exists." });
		}

		// Hash the password
		const hashedPassword = await bcrypt.hash(password, 10);

		// Create the user with doctor role and pending status
		const user = await User.create(
			{
				email,
				password: hashedPassword,
				role: "doctor",
				status: "pending",
			},
			{ transaction: t }
		);

		// Create the doctor profile linked to the user
		const doctor = await Doctor.create(
			{
				first_name,
				middle_name,
				last_name,
				field_id,
				contact_number,
				valid_id: validIdImagePath || valid_id, // Use uploaded image path if available, otherwise use text field
				id_number,
				gender,
				user_id: user.user_id,
				status: "pending", // Set to pending until admin approves
			},
			{ transaction: t }
		);

		await t.commit();

		return res.status(201).json({
			message: "Doctor registered successfully.",
			user,
			doctor,
		});
	} catch (error) {
		await t.rollback();
		console.error("Error registering doctor:", error);
		return res.status(500).json({
			message: "An error occurred while registering the doctor.",
			error: error.message,
		});
	}
};

exports.registerClient = async (req, res) => {
	const t = await db.sequelize.transaction();

	try {
		const {
			first_name,
			middle_name,
			last_name,
			field_id,
			contact_number,
			gender,
			email,
			password,
		} = req.body;

		// Validate password
		const passwordError = validatePassword(password);
		if (passwordError) {
			await t.rollback();
			return res.status(400).json({
				message: passwordError,
			});
		}

		// Check if user already exists with the same email
		const existingUser = await User.findOne({
			where: { email },
			transaction: t,
		});

		if (existingUser) {
			await t.rollback();
			return res.status(400).json({
				message: "User with this email already exists.",
			});
		}

		// Hash the password
		const hashedPassword = await bcrypt.hash(password, 10);

		// Create the user record
		const user = await User.create(
			{
				email,
				password: hashedPassword,
				role: "client",
				status: "pending", // Default for new client users
			},
			{ transaction: t }
		);

		// Create the client record linked to the user
		const client = await Client.create(
			{
				first_name,
				middle_name,
				last_name,
				field_id,
				gender,
				contact_number,
				user_id: user.user_id,
				status: "enabled", // Optional; your model uses default
			},
			{ transaction: t }
		);

		await t.commit();

		return res.status(201).json({
			message: "Client registered successfully.",
			user,
			client,
		});
	} catch (error) {
		await t.rollback();
		console.error("Error registering client:", error);
		return res.status(500).json({
			message: "An error occurred while registering the client.",
			error: error.message,
		});
	}
};

exports.login = async (req, res) => {
	try {
		const { email, password } = req.body; //receive email and password from front

		const user = await User.findOne({ where: { email } });
		if (!user) {
			return res.status(401).json({ message: "Invalid email or password" });
		}

		const isMatch = await bcrypt.compare(password, user.password);
		if (!isMatch) {
			return res.status(401).json({ message: "Invalid email or password" });
		}

		// Check if user is a doctor and if their account is pending
		if (user.role === "doctor") {
			const doctor = await Doctor.findOne({ where: { user_id: user.user_id } });
			if (doctor && doctor.status === "pending") {
				return res.status(403).json({
					message: "Your account is pending admin approval. Please wait for approval.",
				});
			}
			if (doctor && doctor.status === "disabled") {
				return res.status(403).json({
					message: "Your account has been disabled. Please contact support.",
				});
			}
		}

		// Hash the role (bcrypt is async and one-way)
		const hashedRole = await bcrypt.hash(user.role, 10);

		const payload = {
			user_id: user.user_id,
			role: hashedRole,
		};

		const token = jwt.sign(payload, process.env.JWT_SECRET, {
			expiresIn: "15h",
		});

		return res.status(200).json({
			status: "SUCCESS",
			token,
		});
	} catch (error) {
		console.error("Login error:", error);
		return res.status(500).json({
			message: "An error occurred during login.",
			error: error.message,
		});
	}
};

exports.verifyToken = async (req, res) => {
	try {
		const client_tab = [
			"home",
			"events",
			"articles",
			"consultation",
			"profile",
		];

		const doctor_tab = [
			"home",
			"events",
			"articles",
			"availability",
			"consultation",
			"profile",
			// "patients",
		];

		const admin_tab = [
			"home",
			"events",
			"articles",
			"messages",
			// "patients",
			"doctors",
			"clients",
			"profile",
		];

		const token = req.body.token;

		let encryptedRole;

		if (!token) {
			return res
				.status(401)
				.json({ message: "Authorization token missing or malformed." });
		}

		const decoded = jwt.verify(token, process.env.JWT_SECRET);

		//role is bcrypted, so we need to compare it and return the tabs accordingly
		let tabs;
		if (bcrypt.compareSync("client", decoded.role)) {
			tabs = client_tab;
			encryptedRole = "grace";
		}
		if (bcrypt.compareSync("doctor", decoded.role)) {
			tabs = doctor_tab;
			encryptedRole = "janna"; // Placeholder, adjust as needed
		}
		if (bcrypt.compareSync("admin", decoded.role)) {
			tabs = admin_tab;
			encryptedRole = "gwyneth"; // Placeholder, adjust as needed
		}

		return res.status(200).json({
			message: "Token is valid.",
			tabs,
			role: encryptedRole,
		});
	} catch (error) {
		return res.status(401).json({
			message: "Token is invalid or expired.",
			error: error.message,
		});
	}
};

exports.registerAdmin = async (req, res) => {
	const t = await db.sequelize.transaction();
	try {
		const {
			first_name,
			middle_name,
			last_name,
			contact_number,
			email,
			password,
			secret_key,
		} = req.body;

		// ✅ Check secret key
		if (secret_key !== process.env.ADMIN_SECRET) {
			return res.status(401).json({
				message: "Invalid admin secret key. Registration denied.",
			});
		}

		// ✅ Check for existing email
		const existingUser = await User.findOne({
			where: { email },
			transaction: t,
		});

		if (existingUser) {
			await t.rollback();
			return res.status(400).json({
				message: "User with this email already exists.",
			});
		}

		const hashedPassword = await bcrypt.hash(password, 10);

		const user = await User.create(
			{
				email,
				password: hashedPassword,
				role: "admin",
				status: "enabled",
			},
			{ transaction: t }
		);

		const admin = await Admin.create(
			{
				first_name,
				middle_name,
				last_name,
				contact_number,
				user_id: user.user_id,
				status: "enabled",
			},
			{ transaction: t }
		);

		await t.commit();

		return res.status(201).json({
			message: "Admin registered successfully.",
			user,
			admin,
		});
	} catch (error) {
		await t.rollback();
		console.error("Error registering admin:", error);
		return res.status(500).json({
			message: "An error occurred while registering the admin.",
			error: error.message,
		});
	}
};

exports.getProfile = async (req, res) => {
	try {
		const token = req.headers.authorization?.split(" ")[1]; // Expect "Bearer <token>"

		if (!token) {
			return res.status(401).json({ message: "Authorization token missing." });
		}

		// Decode token
		const decoded = jwt.verify(token, process.env.JWT_SECRET);

		const user = await User.findByPk(decoded.user_id);
		if (!user) {
			return res.status(404).json({ message: "User not found." });
		}
		let profile;
		// Use the actual role from the database instead of comparing hashed role from token
		if (user.role === "doctor") {
			profile = await Doctor.findOne({
				where: { user_id: user.user_id },
				include: [{ model: Field, as: "field" }],
			});
		} else if (user.role === "client") {
			profile = await Client.findOne({ where: { user_id: user.user_id } });
		} else {
			profile = await Admin.findOne({ where: { user_id: user.user_id } });
		}

		if (!profile) {
			return res.status(404).json({ message: "Profile not found." });
		}

		// Ensure null values are converted to empty strings for Flutter compatibility
		const profileData = profile.toJSON ? profile.toJSON() : profile;
		
		// Handle nested field object if present
		if (profileData.field && typeof profileData.field === 'object') {
			Object.keys(profileData.field).forEach(key => {
				if (profileData.field[key] === null) {
					profileData.field[key] = "";
				}
			});
		}
		
		// Convert null string fields to empty strings (keep IDs as null if needed)
		const nullableStringFields = ['middle_name', 'valid_id', 'contact_number', 'gender', 'first_name', 'last_name'];
		nullableStringFields.forEach(field => {
			if (profileData[field] === null || profileData[field] === undefined) {
				profileData[field] = "";
			}
		});
		
		return res.status(200).json({
			message: "Profile retrieved successfully",
			role: user.role || "",
			profile: profileData,
			email: user.email || "",
			profile_picture: user.profile_picture || "",
		});
	} catch (error) {
		console.error("Error getting profile:", error);
		return res.status(500).json({
			message: "An error occurred while fetching profile.",
			error: error.message,
		});
	}
};

exports.sendOtp = async (req, res) => {
	try {
		const token = req.headers.authorization?.split(" ")[1];
		if (!token) return res.status(401).json({ message: "Token missing" });

		const decoded = jwt.verify(token, process.env.JWT_SECRET);
		const user = await User.findByPk(decoded.user_id);
		if (!user) return res.status(404).json({ message: "User not found" });

		// Generate simple 6-digit OTP
		const code = Math.floor(100000 + Math.random() * 900000).toString();

		// Store it in DB
		await OTP.create({
			user_id: user.user_id,
			code,
		});

		// (Optional) Send via email or just return it for testing
		return res.status(200).json({
			message: "OTP sent successfully",
			email: user.email,
			code, // remove this in production
		});
	} catch (error) {
		console.error("Error sending OTP:", error);
		return res.status(500).json({ message: "Failed to send OTP" });
	}
};

//get all users where doctor and client is the only roles
exports.getUsersWithRoles = async (req, res) => {
	try {
		const users = await User.findAll({
			where: {
				role: {
					[Op.or]: ["doctor", "client"],
				},
			},
			attributes: ["user_id", "email", "role", "profile_picture"],
		});

		res.json(users);
	} catch (error) {
		console.error("Error fetching users:", error);
		res.status(500).json({ message: "Failed to fetch users" });
	}
};

exports.verifyOtp = async (req, res) => {
	try {
		const token = req.headers.authorization?.split(" ")[1];
		if (!token) return res.status(401).json({ message: "Token missing" });

		const decoded = jwt.verify(token, process.env.JWT_SECRET);
		const { code } = req.body;

		const otp = await OTP.findOne({
			where: { user_id: decoded.user_id, code, status: "unused" },
			order: [["createdAt", "DESC"]],
		});

		if (!otp) {
			return res.status(400).json({ message: "Invalid OTP" });
		}

		await otp.destroy(); // delete OTP after use
		return res.status(200).json({ message: "OTP verified successfully" });
	} catch (error) {
		console.error("Error verifying OTP:", error);
		return res.status(500).json({ message: "Failed to verify OTP" });
	}
};

exports.changePassword = async (req, res) => {
	try {
		const token = req.headers.authorization?.split(" ")[1];
		if (!token) return res.status(401).json({ message: "Token missing" });

		const decoded = jwt.verify(token, process.env.JWT_SECRET);
		const { newPassword } = req.body;

		const hashed = await bcrypt.hash(newPassword, 10);
		await User.update(
			{ password: hashed },
			{ where: { user_id: decoded.user_id } }
		);

		return res.status(200).json({ message: "Password changed successfully" });
	} catch (error) {
		console.error("Error changing password:", error);
		return res.status(500).json({ message: "Failed to change password" });
	}
};

exports.forgotPassword = async (req, res) => {
	try {
		const { email } = req.body;
		console.log("Forgot password request for:", email);
		console.log("Request body:", req.body);
		
		if (!email) {
			return res.status(400).json({ message: "Email is required" });
		}

		// Check if JWT_SECRET is set
		if (!process.env.JWT_SECRET) {
			console.error("JWT_SECRET is not set in environment variables");
			return res.status(500).json({ 
				message: "Server configuration error. Please contact administrator." 
			});
		}

		console.log("Looking up user in database...");
		const user = await User.findOne({ where: { email } });
		
		if (!user) {
			console.log("User not found:", email);
			return res.status(404).json({ message: "User not found" });
		}

		console.log("User found, generating reset token...");
		// Generate a temporary reset token (valid for 15 minutes)
		const resetToken = jwt.sign(
			{ user_id: user.user_id, email: user.email },
			process.env.JWT_SECRET,
			{ expiresIn: "15m" }
		);

		console.log("Reset token generated successfully");
		return res.status(200).json({
			message: "Reset token generated. You can now change your password.",
			resetToken,
		});
	} catch (error) {
		console.error("Error in forgot password:", error);
		console.error("Error name:", error.name);
		console.error("Error message:", error.message);
		console.error("Error stack:", error.stack);
		// Always show error details in development (when NODE_ENV is not production)
		const isDevelopment = process.env.NODE_ENV !== "production";
		return res.status(500).json({ 
			message: "Failed to process request",
			error: isDevelopment ? error.message : "Internal server error",
			...(isDevelopment && { stack: error.stack })
		});
	}
};

exports.resetPassword = async (req, res) => {
	try {
		const { email, resetToken, newPassword } = req.body;
		
		if (!email || !resetToken || !newPassword) {
			return res.status(400).json({ 
				message: "Email, reset token, and new password are required" 
			});
		}

		// Validate password
		const passwordError = validatePassword(newPassword);
		if (passwordError) {
			return res.status(400).json({ message: passwordError });
		}

		// Verify the reset token
		let decoded;
		try {
			decoded = jwt.verify(resetToken, process.env.JWT_SECRET);
		} catch (error) {
			return res.status(401).json({ message: "Invalid or expired reset token" });
		}

		// Verify email matches the token
		const user = await User.findOne({ where: { email, user_id: decoded.user_id } });
		if (!user) {
			return res.status(404).json({ message: "User not found or email mismatch" });
		}

		// Hash and update password
		const hashed = await bcrypt.hash(newPassword, 10);
		await User.update(
			{ password: hashed },
			{ where: { user_id: user.user_id } }
		);

		return res.status(200).json({ message: "Password reset successful" });
	} catch (error) {
		console.error("Error resetting password:", error);
		return res.status(500).json({ message: "Failed to reset password" });
	}
};

exports.changeProfilePicture = async (req, res) => {
	try {
		const token = req.headers.authorization?.split(" ")[1];
		if (!token) return res.status(401).json({ message: "Token missing" });

		if (!req.file) {
			return res.status(400).json({ message: "No file uploaded" });
		}

		const decoded = jwt.verify(token, process.env.JWT_SECRET);

		// Convert file path to URL format
		// req.file.filename is like "profile-123456789.jpg"
		// We want to save "/uploads/profiles/profile-123456789.jpg" to access via static server
		const profile_picture = `/uploads/profiles/${req.file.filename}`;

		await User.update(
			{ profile_picture },
			{ where: { user_id: decoded.user_id } }
		);

		return res
			.status(200)
			.json({
				message: "Profile picture updated successfully",
				profile_picture,
			});
	} catch (error) {
		console.error("Error changing profile picture:", error);
		return res
			.status(500)
			.json({ message: "Failed to change profile picture" });
	}
};

// Get all pending doctors for admin approval
exports.getPendingDoctors = async (req, res) => {
	try {
		const pendingDoctors = await Doctor.findAll({
			where: { status: "pending" },
			include: [
				{
					model: User,
					as: "user",
					attributes: ["email", "user_id"],
				},
				{
					model: Field,
					as: "field",
					attributes: ["name"],
				},
			],
			order: [["createdAt", "DESC"]],
		});

		return res.status(200).json({
			message: "Pending doctors retrieved successfully",
			doctors: pendingDoctors,
		});
	} catch (error) {
		console.error("Error getting pending doctors:", error);
		return res.status(500).json({
			message: "Failed to get pending doctors",
			error: error.message,
		});
	}
};

// Approve a doctor account
exports.approveDoctor = async (req, res) => {
	const t = await db.sequelize.transaction();
	try {
		const { doctor_id } = req.params;

		const doctor = await Doctor.findByPk(doctor_id, { transaction: t });

		if (!doctor) {
			await t.rollback();
			return res.status(404).json({ message: "Doctor not found" });
		}

		// Update doctor status to enabled
		await doctor.update({ status: "enabled" }, { transaction: t });

		// Update user status to enabled
		await User.update(
			{ status: "enabled" },
			{ where: { user_id: doctor.user_id }, transaction: t }
		);

		await t.commit();

		return res.status(200).json({
			message: "Doctor approved successfully",
			doctor,
		});
	} catch (error) {
		await t.rollback();
		console.error("Error approving doctor:", error);
		return res.status(500).json({
			message: "Failed to approve doctor",
			error: error.message,
		});
	}
};

// Reject a doctor account
exports.rejectDoctor = async (req, res) => {
	const t = await db.sequelize.transaction();
	try {
		const { doctor_id } = req.params;

		const doctor = await Doctor.findByPk(doctor_id, { transaction: t });

		if (!doctor) {
			await t.rollback();
			return res.status(404).json({ message: "Doctor not found" });
		}

		// Update doctor status to disabled
		await doctor.update({ status: "disabled" }, { transaction: t });

		// Update user status to disabled
		await User.update(
			{ status: "disabled" },
			{ where: { user_id: doctor.user_id }, transaction: t }
		);

		await t.commit();

		return res.status(200).json({
			message: "Doctor rejected successfully",
			doctor,
		});
	} catch (error) {
		await t.rollback();
		console.error("Error rejecting doctor:", error);
		return res.status(500).json({
			message: "Failed to reject doctor",
			error: error.message,
		});
	}
};
