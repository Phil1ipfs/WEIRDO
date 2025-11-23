const multer = require("multer");
const path = require("path");
const fs = require("fs");

// ✅ Create uploads directory if it doesn't exist
const uploadDir = path.join(__dirname, "../uploads/events");
if (!fs.existsSync(uploadDir)) {
	fs.mkdirSync(uploadDir, { recursive: true });
}

// ✅ Configure local file storage
const storage = multer.diskStorage({
	destination: function (req, file, cb) {
		cb(null, uploadDir);
	},
	filename: function (req, file, cb) {
		// Generate unique filename: timestamp-randomstring.ext
		const uniqueSuffix = Date.now() + "-" + Math.round(Math.random() * 1e9);
		const ext = path.extname(file.originalname);
		cb(null, "event-" + uniqueSuffix + ext);
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
