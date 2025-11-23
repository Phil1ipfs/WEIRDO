const db = require("../models");
const Event = db.Event;
const EventInterest = db.EventInterest;
const Notification = db.Notification;
const User = db.User;
const sequelize = db.sequelize;
const EventRegister = db.EventRegister;

const jwt = require("jsonwebtoken");
const { Op, Sequelize } = require("sequelize");

require("dotenv").config();

exports.createEvent = async (req, res) => {
	try {
		const { title, date, time, description, location, status } = req.body;
		const image = req.file ? req.file.path : null;

		if (!title || !date || !time) {
			return res
				.status(400)
				.json({ message: "Title, date, and time are required." });
		}
		const newEvent = await Event.create({
			title,
			date,
			time,
			description,
			location,
			status: status || "upcoming",
			image,
		});

		// ✅ 2. Notify all users (new_event type)
		const users = await User.findAll({ attributes: ["user_id"] });
		if (users && users.length > 0) {
			const notifications = users.map((u) => ({
				user_id: u.user_id,
				type: "new_event",
				title: "New Event Posted 🎉",
				message: `A new event titled "${title}" has been posted!`,
				related_id: newEvent.event_id,
			}));

			await Notification.bulkCreate(notifications);
		}

		res.status(201).json({
			message: "Event created successfully and notifications sent!",
			event: newEvent,
		});
	} catch (error) {
		console.error("Error creating event:", error);
		res.status(500).json({ message: "Internal server error." });
	}
};

exports.deleteEvent = async (req, res) => {
	try {
		const { event_id } = req.params;

		if (!event_id) {
			return res.status(400).json({ message: "Event ID is required." });
		}

		// Find the event
		const event = await Event.findByPk(event_id);

		if (!event) {
			return res.status(404).json({ message: "Event not found." });
		}

		// Delete related EventInterest records (optional)
		await EventInterest.destroy({ where: { event_id } });

		// Delete related Notifications (optional)
		await Notification.destroy({
			where: { related_id: event_id, type: "new_event" },
		});

		// Delete the event itself
		await Event.destroy({ where: { event_id } });

		res.status(200).json({
			message: `Event "${event.title}" has been deleted successfully.`,
		});
	} catch (error) {
		console.error("Error deleting event:", error);
		res.status(500).json({ message: "Internal server error." });
	}
};

exports.getAllEvents = async (req, res) => {
	try {
		const token = req.headers["authorization"]?.split(" ")[1];
		let userId = null;

		// ✅ Decode user ID if token exists (optional for guests)
		if (token) {
			try {
				const decoded = jwt.verify(token, process.env.JWT_SECRET);
				userId = decoded.user_id;
			} catch {
				console.warn("⚠️ Invalid or expired token, proceeding as guest");
			}
		}

		console.log("User ID from token:", token); // Debugging line

		const { keyword, date, status } = req.query;

		// Build filter conditions
		const where = {};

		if (keyword) {
			const search = { [Op.iLike]: `%${keyword}%` };
			where[Op.or] = [
				{ title: search },
				{ description: search },
				{ location: search },
			];
		}

		if (date) {
			where.date = date; // YYYY-MM-DD
		}

		if (status && status.toLowerCase() !== "all") {
			where.status = status.toLowerCase();
		}

		const events = await Event.findAll({
			where,
			order: [["date", "DESC"]],
			include: [
				{
					model: EventRegister,
					as: "registrations",
					attributes: ["event_register_id", "user_id"],
				},
			],
		});

		const formatted = await Promise.all(
			events.map(async (event) => {
				const registeredCount = await EventRegister.count({
					where: { event_id: event.event_id },
				});

				// ✅ Check if current user is registered
				let isRegistered = false;
				if (userId) {
					isRegistered = event.registrations.some(
						(reg) => reg.user_id === userId
					);
				}

				return {
					event_id: event.event_id,
					title: event.title,
					date: new Date(event.date).toLocaleDateString("en-US", {
						month: "long",
						day: "numeric",
						year: "numeric",
					}),
					time: event.time,
					description: event.description,
					location: event.location,
					registered: registeredCount,
					status: capitalize(event.status),
					image: event.image,
					isRegistered, // ✅ Added field
				};
			})
		);

		res.status(200).json(formatted);
	} catch (error) {
		console.error("Error fetching events:", error);
		res.status(500).json({ message: "Internal server error." });
	}
};

exports.getRegisteredUsersForEvent = async (req, res) => {
	try {
		const { event_id } = req.params;

		if (!event_id) {
			return res.status(400).json({ message: "Event ID is required." });
		}

		const event = await Event.findByPk(event_id);
		if (!event) {
			return res.status(404).json({ message: "Event not found." });
		}

		const registrations = await EventRegister.findAll({
			where: { event_id },
			include: [
				{
					model: User,
					as: "user",
					attributes: ["user_id", "email", "role", "status", "profile_picture"],
					include: [
						{
							model: db.Doctor,
							as: "doctors",
							attributes: [
								"first_name",
								"last_name",
								"contact_number",
								"gender",
							],
						},
						{
							model: db.Client,
							as: "clients",
							attributes: [
								"first_name",
								"last_name",
								"contact_number",
								"gender",
							],
						},
						{
							model: db.Admin,
							as: "admins",
							attributes: [
								"first_name",
								"last_name",
								"contact_number",
								"gender",
							],
						},
					],
				},
			],
		});

		const formatted = registrations.map((r) => {
			const user = r.user;
			let profile = null;

			if (user.role === "doctor") profile = user.doctors;
			else if (user.role === "client") profile = user.clients;
			else if (user.role === "admin") profile = user.admins;
			console.log("User:", profile); // Debugging line

			const full_name = profile
				? `${profile.first_name} ${profile.last_name}`
				: "N/A";

			return {
				registration_id: r.event_register_id,
				user_id: user.user_id,
				email: user.email,
				role: user.role,
				status: user.status,
				full_name,
				profile_picture: user.profile_picture,
				profile,
			};
		});

		res.status(200).json({
			event: {
				event_id: event.event_id,
				title: event.title,
				date: event.date,
				time: event.time,
			},
			total_registered: formatted.length,
			users: formatted,
		});
	} catch (error) {
		console.error("Error fetching registered users:", error);
		res.status(500).json({
			message: "Internal server error.",
			error: error.message,
		});
	}
};

exports.updatePastEvents = async (req, res) => {
	try {
		const [result] = await sequelize.query(`
			UPDATE events
			SET status = 'completed'
			WHERE date < CURRENT_DATE
			  AND status = 'upcoming';
		`);

		res.status(200).json({
			message: "Past events updated successfully.",
			affectedRows: result.affectedRows || 0,
		});
	} catch (error) {
		console.error("Error updating past events:", error);
		res.status(500).json({
			message: "Failed to update past events.",
			error: error.message,
		});
	}
};

exports.getEventStats = async (req, res) => {
	try {
		const total = await Event.count();
		const upcoming = await Event.count({ where: { status: "upcoming" } });
		const completed = await Event.count({ where: { status: "completed" } });
		const cancelled = await Event.count({ where: { status: "cancelled" } });

		res.status(200).json({
			total,
			upcoming,
			completed,
			cancelled,
		});
	} catch (err) {
		res.status(500).json({ message: err.message });
	}
};

exports.getMonthlyEvents = async (req, res) => {
	try {
		const { year } = req.params; // ✅ use query param for consistency (?year=2025)

		if (!year) {
			return res
				.status(400)
				.json({ message: "Year is required (e.g., ?year=2025)" });
		}

		// 🔹 Query: Count events per month for the given year (PostgreSQL compatible)
		const results = await Event.findAll({
			attributes: [
				[Sequelize.literal("EXTRACT(MONTH FROM date)"), "month"],
				[Sequelize.fn("COUNT", Sequelize.col("event_id")), "count"],
			],
			where: Sequelize.where(Sequelize.literal("EXTRACT(YEAR FROM date)"), year),
			group: [Sequelize.literal("EXTRACT(MONTH FROM date)")],
			order: [[Sequelize.literal("EXTRACT(MONTH FROM date)"), "ASC"]],
		});

		// 🔹 Fill months without events with 0
		const monthlyData = Array.from({ length: 12 }, (_, i) => {
			const monthResult = results.find((r) => r.dataValues.month === i + 1);
			return {
				month: new Date(year, i).toLocaleString("default", { month: "short" }),
				count: monthResult ? parseInt(monthResult.dataValues.count, 10) : 0,
			};
		});

		// ✅ Return formatted response
		res.status(200).json({
			year,
			data: monthlyData,
		});
	} catch (error) {
		console.error("Error fetching monthly events:", error);
		res.status(500).json({ message: "Server error occurred" });
	}
};

exports.getUpcomingEventsThisMonth = async (req, res) => {
	try {
		const today = new Date();
		const currentYear = today.getFullYear();
		const currentMonth = today.getMonth() + 1; // JS months are 0-indexed

		// Get today's date in YYYY-MM-DD format
		const todayStr = today.toISOString().split("T")[0];
		
		// Get first and last day of current month
		const startOfMonth = new Date(currentYear, currentMonth - 1, 1);
		const endOfMonth = new Date(currentYear, currentMonth, 0); // last day of month

		// 🔹 Query: Get events scheduled for this month, still "upcoming", and on or after today
		const events = await Event.findAll({
			where: {
				date: {
					[Op.between]: [todayStr, endOfMonth.toISOString().split("T")[0]], // From today to end of month
				},
				status: "upcoming",
			},
			order: [["date", "ASC"]],
		});

		// Format the events for the frontend
		const formatted = events.map((event) => ({
			event_id: event.event_id,
			title: event.title,
			date: new Date(event.date).toLocaleDateString("en-US", {
				month: "long",
				day: "numeric",
				year: "numeric",
			}),
			time: event.time,
			description: event.description,
			location: event.location,
			status: event.status,
			image: event.image,
		}));

		res.status(200).json({
			currentMonth: new Date(currentYear, currentMonth - 1).toLocaleString(
				"default",
				{ month: "long" }
			),
			year: currentYear,
			count: formatted.length,
			events: formatted,
		});
	} catch (error) {
		console.error("Error fetching upcoming events this month:", error);
		res.status(500).json({ message: "Server error occurred" });
	}
};

exports.registerEvent = async (req, res) => {
	try {
		const token = req.headers["authorization"]?.split(" ")[1];
		if (!token) return res.status(401).json({ message: "No token provided." });

		const decoded = jwt.verify(token, process.env.JWT_SECRET);
		const userId = decoded.user_id;
		const { event_id } = req.body;

		if (!event_id) {
			return res.status(400).json({ message: "Event ID is required." });
		}

		// ✅ Check if event exists
		const event = await db.Event.findByPk(event_id);
		if (!event) {
			return res.status(404).json({ message: "Event not found." });
		}

		// ✅ Check if user already registered
		const existing = await db.EventRegister.findOne({
			where: { event_id, user_id: userId },
		});
		if (existing) {
			return res
				.status(400)
				.json({ message: "You have already registered for this event." });
		}

		// ✅ Register the user
		const registration = await db.EventRegister.create({
			event_id,
			user_id: userId,
		});

		// ✅ Optional: create a notification
		await db.Notification.create({
			user_id: userId,
			type: "event_registration",
			title: "Event Registration Confirmed",
			message: `You successfully registered for the event "${event.title}".`,
			related_id: event.event_id,
		});

		res.status(201).json({
			message: "You have successfully registered for the event!",
			registration,
		});
	} catch (error) {
		console.error("Error registering for event:", error);
		res.status(500).json({ message: "Internal server error.", error });
	}
};

exports.cancelRegistration = async (req, res) => {
	try {
		const token = req.headers["authorization"]?.split(" ")[1];
		if (!token) return res.status(401).json({ message: "No token provided." });

		const decoded = jwt.verify(token, process.env.JWT_SECRET);
		const userId = decoded.user_id;
		const { event_id } = req.body;

		if (!event_id) {
			return res.status(400).json({ message: "Event ID is required." });
		}

		// ✅ Check if registration exists
		const registration = await db.EventRegister.findOne({
			where: { event_id, user_id: userId },
		});

		if (!registration) {
			return res
				.status(404)
				.json({ message: "You are not registered for this event." });
		}

		// ✅ Delete registration
		await registration.destroy();

		// ✅ Optional: create a notification
		await db.Notification.create({
			user_id: userId,
			type: "event_cancellation",
			title: "Event Registration Cancelled",
			message: `You have cancelled your registration for the event.`,
			related_id: event_id,
		});

		res.status(200).json({ message: "Your registration has been cancelled." });
	} catch (error) {
		console.error("Error cancelling registration:", error);
		res.status(500).json({ message: "Internal server error.", error });
	}
};

function capitalize(str) {
	return str.charAt(0).toUpperCase() + str.slice(1);
}
