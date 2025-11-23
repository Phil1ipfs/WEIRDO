const path = require("path");
require("dotenv").config({ path: path.resolve(__dirname, "../.env") });

const bcrypt = require("bcrypt");
const db = require("../models");

async function seedAllData() {
	try {
		await db.sequelize.authenticate();
		console.log("✅ Database connected successfully");

		// 1. Seed Fields
		console.log("\n📋 Seeding Fields...");
		const fields = await db.Field.bulkCreate([
			{ name: "General Medicine", type: "medical", required: true },
			{ name: "Pediatrics", type: "medical", required: false },
			{ name: "Cardiology", type: "medical", required: false },
			{ name: "Psychiatry", type: "medical", required: false },
			{ name: "Dermatology", type: "medical", required: false },
		], { ignoreDuplicates: true });
		console.log(`✅ Created ${fields.length} fields`);

		// 2. Seed Users (Admin, Doctor, Client)
		console.log("\n👥 Seeding Users...");
		const hashedPassword = await bcrypt.hash("Admin123", 10);

		const adminUser = await db.User.create({
			email: "admin.dev@myriad.local",
			password: hashedPassword,
			role: "admin",
			status: "enabled",
		});
		await db.Admin.create({
			user_id: adminUser.user_id,
			first_name: "Aubrey",
			middle_name: "Dev",
			last_name: "Admin",
			contact_number: "09170000001",
			gender: "Female",
			status: "enabled",
		});
		console.log("✅ Created admin: admin.dev@myriad.local / Admin123");

		const doctorPassword = await bcrypt.hash("Doctor123", 10);
		const doctorUser = await db.User.create({
			email: "doctor.dev@myriad.local",
			password: doctorPassword,
			role: "doctor",
			status: "enabled",
		});
		await db.Doctor.create({
			user_id: doctorUser.user_id,
			first_name: "Derek",
			middle_name: "Dev",
			last_name: "Doctor",
			field_id: fields[0].field_id,
			contact_number: "09170000002",
			gender: "Male",
			valid_id: "DEV-DOCTOR-ID",
			status: "enabled",
		});
		console.log("✅ Created doctor: doctor.dev@myriad.local / Doctor123");

		const clientPassword = await bcrypt.hash("Client123", 10);
		const clientUser = await db.User.create({
			email: "client.dev@myriad.local",
			password: clientPassword,
			role: "client",
			status: "enabled",
		});
		await db.Client.create({
			user_id: clientUser.user_id,
			first_name: "Clara",
			middle_name: "Dev",
			last_name: "Client",
			field_id: fields[0].field_id,
			contact_number: "09170000003",
			gender: "Female",
			status: "enabled",
		});
		console.log("✅ Created client: client.dev@myriad.local / Client123");

		// Also create min.dev@myriad.local
		const minPassword = await bcrypt.hash("Admin123", 10);
		const minUser = await db.User.create({
			email: "min.dev@myriad.local",
			password: minPassword,
			role: "admin",
			status: "enabled",
		});
		await db.Admin.create({
			user_id: minUser.user_id,
			first_name: "Min",
			middle_name: "D",
			last_name: "Myriad",
			contact_number: "09171234567",
			gender: "Male",
			status: "enabled",
		});
		console.log("✅ Created admin: min.dev@myriad.local / Admin123");

		// 3. Seed Events
		console.log("\n📅 Seeding Events...");
		const events = await db.Event.bulkCreate([
			{
				title: "Mental Health Awareness Webinar",
				date: new Date("2025-12-01"),
				time: "14:00",
				description: "Join us for an insightful webinar on mental health awareness and coping strategies.",
				location: "Online via Zoom",
				status: "upcoming",
			},
			{
				title: "Community Health Fair",
				date: new Date("2025-11-30"),
				time: "09:00",
				description: "Free health screenings and consultations for the community.",
				location: "City Hall, Main Auditorium",
				status: "upcoming",
			},
			{
				title: "Stress Management Workshop",
				date: new Date("2025-11-28"),
				time: "15:00",
				description: "Learn practical techniques for managing stress in daily life.",
				location: "Wellness Center, Room 101",
				status: "upcoming",
			},
		]);
		console.log(`✅ Created ${events.length} events`);

		// 4. Seed Articles
		console.log("\n📰 Seeding Articles...");
		const articles = await db.Article.bulkCreate([
			{
				title: "Understanding Anxiety Disorders",
				slug: "understanding-anxiety-disorders",
				content: "Anxiety disorders are among the most common mental health conditions...",
				excerpt: "A comprehensive guide to understanding and managing anxiety.",
				status: "published",
				user_id: doctorUser.user_id,
				likes_count: 5,
			},
			{
				title: "The Importance of Mental Health",
				slug: "importance-of-mental-health",
				content: "Mental health is just as important as physical health...",
				excerpt: "Why mental health matters and how to maintain it.",
				status: "published",
				user_id: doctorUser.user_id,
				likes_count: 8,
			},
			{
				title: "Coping with Depression",
				slug: "coping-with-depression",
				content: "Depression is a serious mental health condition that affects millions...",
				excerpt: "Strategies and resources for coping with depression.",
				status: "published",
				user_id: adminUser.user_id,
				likes_count: 3,
			},
		]);
		console.log(`✅ Created ${articles.length} articles`);

		// 5. Seed Doctor Availability
		console.log("\n🕐 Seeding Doctor Availability...");
		const doctor = await db.Doctor.findOne({ where: { user_id: doctorUser.user_id } });
		const availabilities = await db.DoctorAvailability.bulkCreate([
			{
				doctor_id: doctor.doctor_id,
				date: new Date("2025-11-25"),
				start_time: "09:00:00",
				end_time: "12:00:00",
				status: "available",
			},
			{
				doctor_id: doctor.doctor_id,
				date: new Date("2025-11-26"),
				start_time: "14:00:00",
				end_time: "17:00:00",
				status: "available",
			},
			{
				doctor_id: doctor.doctor_id,
				date: new Date("2025-11-27"),
				start_time: "10:00:00",
				end_time: "15:00:00",
				status: "available",
			},
		]);
		console.log(`✅ Created ${availabilities.length} doctor availabilities`);

		// 6. Seed Appointments
		console.log("\n📋 Seeding Appointments...");
		const appointments = await db.Appointment.bulkCreate([
			{
				doctor_id: doctor.doctor_id,
				user_id: clientUser.user_id,
				date: new Date("2025-11-25"),
				availability_id: availabilities[0].availability_id,
				remarks: "Initial consultation",
				status: "Pending",
			},
		]);
		console.log(`✅ Created ${appointments.length} appointments`);

		// 7. Seed Event Registrations
		console.log("\n📝 Seeding Event Registrations...");
		await db.EventRegister.bulkCreate([
			{ event_id: events[0].event_id, user_id: clientUser.user_id },
			{ event_id: events[1].event_id, user_id: clientUser.user_id },
		]);
		console.log("✅ Created event registrations");

		// 8. Seed Likes
		console.log("\n❤️ Seeding Article Likes...");
		await db.Like.bulkCreate([
			{ article_id: articles[0].article_id, user_id: clientUser.user_id },
			{ article_id: articles[1].article_id, user_id: clientUser.user_id },
			{ article_id: articles[1].article_id, user_id: adminUser.user_id },
		]);
		console.log("✅ Created article likes");

		// 9. Seed Comments
		console.log("\n💬 Seeding Comments...");
		await db.Comment.bulkCreate([
			{
				article_id: articles[0].article_id,
				user_id: clientUser.user_id,
				content: "This article was very helpful, thank you!",
			},
			{
				article_id: articles[1].article_id,
				user_id: adminUser.user_id,
				content: "Great insights on mental health importance.",
			},
		]);
		console.log("✅ Created comments");

		console.log("\n🎉 Database seeding completed successfully!");
		console.log("\n📝 Test Accounts:");
		console.log("   Admin:  admin.dev@myriad.local / Admin123");
		console.log("   Admin:  min.dev@myriad.local / Admin123");
		console.log("   Doctor: doctor.dev@myriad.local / Doctor123");
		console.log("   Client: client.dev@myriad.local / Client123");

	} catch (error) {
		console.error("❌ Seeding failed:", error);
	} finally {
		await db.sequelize.close();
	}
}

seedAllData();
