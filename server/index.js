const express = require("express");
const app = express();
require("dotenv").config();
const cors = require("cors");
const dns = require("dns");

// Configure DNS to use Google DNS for better resolution
dns.setServers(["8.8.8.8", "8.8.4.4", "1.1.1.1"]);
// Force IPv4 first (though Supabase may only have IPv6)
process.env.NODE_OPTIONS = process.env.NODE_OPTIONS ? 
	`${process.env.NODE_OPTIONS} --dns-result-order=ipv4first` : 
	"--dns-result-order=ipv4first";

const PORT = process.env.PORT;
const db = require("./models/index.js");

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// ✅ Serve uploaded images as static files
app.use('/uploads', express.static('uploads'));

db.sequelize
	.sync({ alter: true })
	.then(() => {
		console.log("Database connected successfully.");
	})
	.catch((err) => {
		console.error("Unable to connect to the database:", err);
	});

app.get("/api", (req, res) => {
	console.log(req.method, req.url);
	res.send("Welcome to the Myriad Server!");
});

app.use("/api/auth", require("./routes/auth.routes.js"));
app.use("/api/dropdown", require("./routes/dropdown.routes.js"));
app.use("/api/events", require("./routes/event.routes.js"));
app.use("/api/articles", require("./routes/article.routes.js"));
app.use("/api/doctors", require("./routes/doctor.routes.js"));
app.use("/api/appointments", require("./routes/appointment.routes.js"));
app.use("/api/messages", require("./routes/message.routes"));
app.use("/api/clients", require("./routes/client.routes.js"));
app.use("/api/admins", require("./routes/admin.routes.js"));
app.use("/api/dashboard", require("./routes/dashboard.routes.js"));
app.use("/api/notifications", require("./routes/notification.routes.js"));

// ✅ Global error handler - catches all errors and returns JSON instead of HTML
app.use((err, req, res, next) => {
	console.error("❌ Error:", err);
	res.status(err.status || 500).json({
		message: err.message || "Internal server error",
		error: process.env.NODE_ENV === 'development' ? err.stack : undefined
	});
});

app.listen(PORT, '0.0.0.0', () => {
	console.log(`Server is running on port ${PORT}`);
	console.log(`Accessible from emulator at http://10.0.2.2:${PORT}`);
});
