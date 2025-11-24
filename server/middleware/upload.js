const multer = require("multer");
const path = require("path");
const fs = require("fs");

// ✅ Create uploads directories if they don't exist
const eventsDir = path.join(__dirname, "../uploads/events");
const validIdsDir = path.join(__dirname, "../uploads/valid_ids");
const profilesDir = path.join(__dirname, "../uploads/profiles");

if (!fs.existsSync(eventsDir)) {
	fs.mkdirSync(eventsDir, { recursive: true });
}
if (!fs.existsSync(validIdsDir)) {
	fs.mkdirSync(validIdsDir, { recursive: true });
}
if (!fs.existsSync(profilesDir)) {
	fs.mkdirSync(profilesDir, { recursive: true });
}

// ✅ Configure local file storage
const storage = multer.diskStorage({
	destination: function (req, file, cb) {
		let folder = eventsDir; // default
		if (file.fieldname === "valid_id") {
			folder = validIdsDir;
		} else if (file.fieldname === "image" && req.path.includes("profile")) {
			folder = profilesDir;
		}
		cb(null, folder);
	},
	filename: function (req, file, cb) {
		// Generate unique filename: timestamp-randomstring.ext
		const uniqueSuffix = Date.now() + "-" + Math.round(Math.random() * 1e9);
		const ext = path.extname(file.originalname);

		let prefix = "event-";
		if (file.fieldname === "valid_id") {
			prefix = "valid-id-";
		} else if (file.fieldname === "image" && req.path.includes("profile")) {
			prefix = "profile-";
		}

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
