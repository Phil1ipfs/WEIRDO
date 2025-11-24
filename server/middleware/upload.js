const multer = require("multer");
const path = require("path");
const fs = require("fs");

// ✅ Create uploads directories if they don't exist
const uploadsBase = path.join(__dirname, "../uploads");
const eventsDir = path.join(uploadsBase, "events");
const validIdsDir = path.join(uploadsBase, "valid_ids");
const profilesDir = path.join(uploadsBase, "profiles");

[eventsDir, validIdsDir, profilesDir].forEach(dir => {
	if (!fs.existsSync(dir)) {
		fs.mkdirSync(dir, { recursive: true });
	}
});

// ✅ Configure local file storage
const storage = multer.diskStorage({
	destination: function (req, file, cb) {
		// Route to different folders based on field name
		let folder = eventsDir; // default
		if (file.fieldname === "valid_id") {
			folder = validIdsDir;
		} else if (file.fieldname === "profile_picture" || file.fieldname === "image") {
			// Check if it's a profile upload or event upload
			if (req.path && req.path.includes("profile")) {
				folder = profilesDir;
			} else {
				folder = eventsDir;
			}
		}
		cb(null, folder);
	},
	filename: function (req, file, cb) {
		// Generate unique filename: timestamp-randomstring.ext
		const uniqueSuffix = Date.now() + "-" + Math.round(Math.random() * 1e9);
		const ext = path.extname(file.originalname);
		const prefix = file.fieldname === "valid_id" ? "valid-id-" : file.fieldname === "image" ? "event-" : "profile-";
		cb(null, prefix + uniqueSuffix + ext);
	},
});

// ✅ File filter to accept only images
const fileFilter = (req, file, cb) => {
	const allowedTypes = ["image/jpeg", "image/jpg", "image/png"];
	const allowedExtensions = [".jpg", ".jpeg", ".png"];

	const ext = path.extname(file.originalname).toLowerCase();

	// Accept if either MIME type or extension is valid
	if (allowedTypes.includes(file.mimetype) || allowedExtensions.includes(ext)) {
		cb(null, true);
	} else {
		cb(new Error("Only JPG, JPEG, and PNG images are allowed"), false);
	}
};

const upload = multer({
	storage: storage,
	fileFilter: fileFilter,
	limits: { fileSize: 5 * 1024 * 1024 }, // 5MB limit
});

module.exports = upload;
