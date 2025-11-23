module.exports = (sequelize, Sequelize) => {
	const EventRegister = sequelize.define(
		"event_register",
		{
			event_register_id: {
				type: Sequelize.INTEGER,
				autoIncrement: true,
				primaryKey: true,
				allowNull: false,
			},
			event_id: {
				type: Sequelize.INTEGER,
				allowNull: false,
				references: {
					model: "events",
					key: "event_id",
				},
			},
			user_id: {
				type: Sequelize.INTEGER,
				allowNull: false,
				references: {
					model: "users",
					key: "user_id",
				},
			},
		},
		{
			timestamps: true,
			tableName: "event_register",
		}
	);

	return EventRegister;
};
