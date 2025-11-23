const path = require("path");
require("dotenv").config({ path: path.resolve(__dirname, "../.env") });

// Force production database connection with explicit env vars
process.env.NODE_ENV = "production";
process.env.DB_HOST = process.env.DB_HOST || "db.mxfuvioxlsnegqbczsjm.supabase.co";
process.env.DB_PORT = process.env.DB_PORT || "5432";
process.env.DB_NAME = process.env.DB_NAME || "postgres";
process.env.DB_USER = process.env.DB_USER || "postgres";
process.env.DB_PASSWORD = process.env.DB_PASSWORD || "Karldarn25!";
process.env.DB_SSL = process.env.DB_SSL || "true";

const db = require("../models");

async function checkAccounts() {
	try {
		await db.sequelize.authenticate();
		console.log("✅ Database connected successfully\n");

		// Get all users
		const users = await db.User.findAll({
			order: [["createdAt", "ASC"]],
		});

		if (users.length === 0) {
			console.log("❌ No accounts found in the database.");
			return;
		}

		console.log(`📊 Found ${users.length} account(s) in the database:\n`);
		console.log("=".repeat(80));

		for (const user of users) {
			let profile = null;
			let fullName = "N/A";

			// Get profile based on role
			switch (user.role) {
				case "admin":
					profile = await db.Admin.findOne({
						where: { user_id: user.user_id },
					});
					if (profile) {
						fullName = `${profile.first_name} ${profile.middle_name || ""} ${profile.last_name}`.trim();
					}
					break;
				case "doctor":
					profile = await db.Doctor.findOne({
						where: { user_id: user.user_id },
					});
					if (profile) {
						fullName = `Dr. ${profile.first_name} ${profile.middle_name || ""} ${profile.last_name}`.trim();
					}
					break;
				case "client":
					profile = await db.Client.findOne({
						where: { user_id: user.user_id },
					});
					if (profile) {
						fullName = `${profile.first_name} ${profile.middle_name || ""} ${profile.last_name}`.trim();
					}
					break;
			}

			console.log(`\n👤 User ID: ${user.user_id}`);
			console.log(`   Email: ${user.email}`);
			console.log(`   Role: ${user.role.toUpperCase()}`);
			console.log(`   Status: ${user.status.toUpperCase()}`);
			console.log(`   Name: ${fullName}`);

			if (profile) {
				if (user.role === "doctor") {
					console.log(`   Contact: ${profile.contact_number || "N/A"}`);
					console.log(`   Valid ID: ${profile.valid_id ? "✅ Uploaded" : "❌ Not uploaded"}`);
					console.log(`   ID Number: ${profile.id_number || "N/A"}`);
					const field = await db.Field.findByPk(profile.field_id);
					console.log(`   Specialty: ${field ? field.name : "N/A"}`);
				} else if (user.role === "client") {
					console.log(`   Contact: ${profile.contact_number || "N/A"}`);
				} else if (user.role === "admin") {
					console.log(`   Contact: ${profile.contact_number || "N/A"}`);
				}
			}

			console.log(`   Created: ${user.createdAt}`);
			console.log(`   Updated: ${user.updatedAt}`);
			console.log("-".repeat(80));
		}

		// Summary
		const adminCount = users.filter((u) => u.role === "admin").length;
		const doctorCount = users.filter((u) => u.role === "doctor").length;
		const clientCount = users.filter((u) => u.role === "client").length;
		const enabledCount = users.filter((u) => u.status === "enabled").length;
		const pendingCount = users.filter((u) => u.status === "pending").length;
		const disabledCount = users.filter((u) => u.status === "disabled").length;

		console.log(`\n📈 Summary:`);
		console.log(`   Total Accounts: ${users.length}`);
		console.log(`   - Admins: ${adminCount}`);
		console.log(`   - Doctors: ${doctorCount}`);
		console.log(`   - Clients: ${clientCount}`);
		console.log(`\n   Status Breakdown:`);
		console.log(`   - Enabled: ${enabledCount}`);
		console.log(`   - Pending: ${pendingCount}`);
		console.log(`   - Disabled: ${disabledCount}`);
	} catch (error) {
		console.error("❌ Error checking accounts:", error);
	} finally {
		await db.sequelize.close();
	}
}

checkAccounts();

