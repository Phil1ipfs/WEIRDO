const path = require("path");
require("dotenv").config({ path: path.resolve(__dirname, "../.env") });
const { Sequelize } = require("sequelize");

// Direct database connection using .env values
const sequelize = new Sequelize(
	process.env.DB_NAME || "postgres",
	process.env.DB_USER || "postgres",
	process.env.DB_PASSWORD || "Karldarn25!",
	{
		host: process.env.DB_HOST || "db.mxfuvioxlsnegqbczsjm.supabase.co",
		port: process.env.DB_PORT || 5432,
		dialect: "postgres",
		dialectOptions: {
			ssl: {
				require: true,
				rejectUnauthorized: false,
			},
		},
		logging: false,
	}
);

async function checkAccounts() {
	try {
		await sequelize.authenticate();
		console.log("✅ Database connected successfully\n");

		// Query users table directly
		const [users] = await sequelize.query(
			`SELECT user_id, email, role, status, "createdAt", "updatedAt" 
			 FROM users 
			 ORDER BY "createdAt" ASC`
		);

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
			let profileQuery = "";
			if (user.role === "admin") {
				profileQuery = `SELECT first_name, middle_name, last_name, contact_number 
								FROM admins WHERE user_id = ${user.user_id}`;
			} else if (user.role === "doctor") {
				profileQuery = `SELECT first_name, middle_name, last_name, contact_number, 
								valid_id, id_number, field_id 
								FROM doctors WHERE user_id = ${user.user_id}`;
			} else if (user.role === "client") {
				profileQuery = `SELECT first_name, middle_name, last_name, contact_number 
								FROM clients WHERE user_id = ${user.user_id}`;
			}

			if (profileQuery) {
				const [profiles] = await sequelize.query(profileQuery);
				if (profiles.length > 0) {
					profile = profiles[0];
					const parts = [
						profile.first_name,
						profile.middle_name,
						profile.last_name,
					].filter(Boolean);
					fullName = user.role === "doctor" ? `Dr. ${parts.join(" ")}` : parts.join(" ");
				}
			}

			console.log(`\n👤 User ID: ${user.user_id}`);
			console.log(`   Email: ${user.email}`);
			console.log(`   Role: ${user.role.toUpperCase()}`);
			console.log(`   Status: ${user.status.toUpperCase()}`);
			console.log(`   Name: ${fullName}`);

			if (profile) {
				console.log(`   Contact: ${profile.contact_number || "N/A"}`);
				if (user.role === "doctor") {
					console.log(`   Valid ID: ${profile.valid_id ? "✅ Uploaded" : "❌ Not uploaded"}`);
					console.log(`   ID Number: ${profile.id_number || "N/A"}`);
					if (profile.field_id) {
						const [fields] = await sequelize.query(
							`SELECT name FROM fields WHERE field_id = ${profile.field_id}`
						);
						console.log(`   Specialty: ${fields.length > 0 ? fields[0].name : "N/A"}`);
					}
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
		console.error("❌ Error checking accounts:");
		console.error("   Message:", error.message);
		console.error("   Code:", error.code);
		console.error("   Full error:", error);
	} finally {
		await sequelize.close();
	}
}

checkAccounts();

