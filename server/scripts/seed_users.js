const path = require("path");
require("dotenv").config({ path: path.resolve(__dirname, "../.env") });

const bcrypt = require("bcrypt");
const db = require("../models");

async function ensureDefaultField() {
	let field = await db.Field.findOne();
	if (!field) {
		field = await db.Field.create({
			name: "General Medicine",
			type: "medical",
			required: true,
		});
		console.log(
			`Created default field "${field.name}" with id ${field.field_id}`
		);
	}
	return field.field_id;
}

async function seed() {
	try {
		await db.sequelize.authenticate();
		const fieldId = await ensureDefaultField();

		const usersToSeed = [
			{
				email: "admin.dev@myriad.local",
				password: "Admin123",
				role: "admin",
				profileModel: db.Admin,
				profileData: {
					first_name: "Aubrey",
					middle_name: "Dev",
					last_name: "Admin",
					contact_number: "09170000001",
					gender: "Female",
					status: "enabled",
				},
			},
			{
				email: "doctor.dev@myriad.local",
				password: "Doctor123",
				role: "doctor",
				profileModel: db.Doctor,
				profileData: {
					first_name: "Derek",
					middle_name: "Dev",
					last_name: "Doctor",
					field_id: fieldId,
					contact_number: "09170000002",
					gender: "Male",
					valid_id: "DEV-DOCTOR-ID",
					status: "enabled",
				},
			},
			{
				email: "client.dev@myriad.local",
				password: "Client123",
				role: "client",
				profileModel: db.Client,
				profileData: {
					first_name: "Clara",
					middle_name: "Dev",
					last_name: "Client",
					field_id: fieldId,
					contact_number: "09170000003",
					gender: "Female",
					status: "enabled",
				},
			},
		];

		for (const seedUser of usersToSeed) {
			const existingUser = await db.User.findOne({
				where: { email: seedUser.email },
			});

			if (existingUser) {
				console.log(`Skipping ${seedUser.email} (already exists).`);
				continue;
			}

			const hashedPassword = await bcrypt.hash(seedUser.password, 10);
			const user = await db.User.create({
				email: seedUser.email,
				password: hashedPassword,
				role: seedUser.role,
				status: "enabled",
			});

			await seedUser.profileModel.create({
				...seedUser.profileData,
				user_id: user.user_id,
			});

			console.log(
				`Seeded ${seedUser.role} account: ${seedUser.email} / ${seedUser.password}`
			);
		}
	} catch (error) {
		console.error("Seeding failed:", error);
	} finally {
		await db.sequelize.close();
	}
}

seed();

