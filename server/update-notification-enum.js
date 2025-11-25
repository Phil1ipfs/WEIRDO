// Script to add new notification types to the enum
const { sequelize } = require("./models");

async function updateNotificationEnum() {
	try {
		console.log("🔄 Updating notification enum types...");

		// Add new enum values (IF NOT EXISTS requires PostgreSQL 9.1+)
		await sequelize.query(`
			DO $$
			BEGIN
				IF NOT EXISTS (
					SELECT 1 FROM pg_enum
					WHERE enumlabel = 'event_registration'
					AND enumtypid = (
						SELECT oid FROM pg_type WHERE typname = 'enum_notifications_type'
					)
				) THEN
					ALTER TYPE enum_notifications_type ADD VALUE 'event_registration';
				END IF;

				IF NOT EXISTS (
					SELECT 1 FROM pg_enum
					WHERE enumlabel = 'event_cancellation'
					AND enumtypid = (
						SELECT oid FROM pg_type WHERE typname = 'enum_notifications_type'
					)
				) THEN
					ALTER TYPE enum_notifications_type ADD VALUE 'event_cancellation';
				END IF;
			END $$;
		`);

		console.log("✅ Notification enum updated successfully!");
		process.exit(0);
	} catch (error) {
		console.error("❌ Error updating notification enum:", error);
		process.exit(1);
	}
}

updateNotificationEnum();
