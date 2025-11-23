module.exports = (sequelize, Sequelize) => {
	const Comment = sequelize.define(
		"comment",
		{
			comment_id: {
				type: Sequelize.INTEGER,
				autoIncrement: true,
				primaryKey: true,
				allowNull: false,
			},
			article_id: {
				type: Sequelize.INTEGER,
				allowNull: false,
			},
			user_id: {
				type: Sequelize.INTEGER,
				allowNull: false,
				references: {
					model: "users",
					key: "user_id",
				},
			},
			content: {
				type: Sequelize.TEXT,
				allowNull: false,
			},
			parent_id: {
				type: Sequelize.INTEGER,
				allowNull: true,
				references: {
					model: "comments",
					key: "comment_id",
				},
			},
		},
		{
			timestamps: true,
			tableName: "comments",
		}
	);
	return Comment;
};
