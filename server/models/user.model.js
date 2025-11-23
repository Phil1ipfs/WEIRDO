module.exports = (sequelize, Sequelize) => {
	const User = sequelize.define(
		"user",
		{
			user_id: {
				type: Sequelize.INTEGER,
				autoIncrement: true,
				primaryKey: true,
				allowNull: false,
			},
			email: {
				type: Sequelize.STRING,
				allowNull: false,
			},
			password: {
				type: Sequelize.STRING,
				allowNull: false,
			},
			status: {
				type: Sequelize.STRING,
				allowNull: false,
				defaultValue: "pending",
				validate: {
					isIn: [["enabled", "disabled", "pending"]],
				},
			},
			role: {
				type: Sequelize.STRING,
				allowNull: false,
				defaultValue: "client",
				validate: {
					isIn: [["admin", "doctor", "client"]],
				},
			},
			profile_picture: {
				type: Sequelize.STRING,
				allowNull: true,
			},
		},
		{
			timestamps: true,
			tableName: "users",
		}
	);
	return User;
};
