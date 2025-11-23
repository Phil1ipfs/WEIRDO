const jwt = require("jsonwebtoken");
const db = require("../models");
const { Sequelize } = require("sequelize");

const moment = require("moment-timezone");
const Article = db.Article;
const Like = db.Like;
const Comment = db.Comment;
const Notification = db.Notification;
const User = db.User;
require("dotenv").config();

exports.createArticle = async (req, res) => {
	try {
		const { title, slug, content, excerpt, status, token, link } = req.body;

		if (!token) {
			return res.status(400).json({ message: "Token is required" });
		}

		// Decode the token to get the user_id
		const decoded = jwt.verify(token, process.env.JWT_SECRET);
		const user_id = decoded.user_id;

		const image = req.file ? req.file.path : null;

		const article = await Article.create({
			title,
			slug,
			content,
			excerpt,
			status,
			user_id,
			link,
			cover_image: image,
		});

		// ✅ Notify all users about the new article (except the author)
		const users = await User.findAll({
			where: { user_id: { [Sequelize.Op.ne]: user_id } },
		});

		for (const user of users) {
			await Notification.create({
				user_id: user.user_id,
				type: "new_article",
				title: "New Article Published!",
				message: `A new article titled "${article.title}" has been posted.`,
				related_id: article.article_id,
			});
		}

		// ✅ Convert article timestamps from UTC to Philippine time for response
		const articleData = article.toJSON();
		if (articleData.createdAt) {
			articleData.createdAt = moment(articleData.createdAt)
				.tz("Asia/Manila")
				.format("YYYY-MM-DD HH:mm:ss");
		}
		if (articleData.updatedAt) {
			articleData.updatedAt = moment(articleData.updatedAt)
				.tz("Asia/Manila")
				.format("YYYY-MM-DD HH:mm:ss");
		}

		return res.status(201).json({
			message: "Article created successfully",
			article: articleData,
		});
	} catch (error) {
		console.error("Error creating article:", error);
		return res.status(500).json({
			message: "Failed to create article",
			error: error.message,
		});
	}
};

exports.getAllSlugs = async (req, res) => {
	try {
		const articles = await Article.findAll({
			attributes: ["slug", "article_id"],
		});
		const slugs = articles.map((article) => ({
			slug: article.slug,
			article_id: article.article_id,
		}));
		return res.status(200).json(slugs);
	} catch (error) {
		console.error("Error fetching article slugs:", error);
		return res.status(500).json({
			message: "Failed to fetch article slugs",
			error: error.message,
		});
	}
};

exports.deleteArticle = async (req, res) => {
	const { article_id } = req.params;

	if (!article_id) {
		return res.status(400).json({ message: "Article ID is required." });
	}

	try {
		const article = await Article.findByPk(article_id);
		if (!article) {
			return res.status(404).json({ message: "Article not found." });
		}

		// Optional: delete related likes, comments, notifications
		await Like.destroy({ where: { article_id } });
		await Comment.destroy({ where: { article_id } });
		await Notification.destroy({
			where: {
				related_id: article_id,
				type: ["new_article", "like", "comment"],
			},
		});

		// Delete the article itself
		await article.destroy();

		return res.status(200).json({ message: "Article deleted successfully." });
	} catch (error) {
		console.error("Error deleting article:", error);
		return res
			.status(500)
			.json({ message: "Failed to delete article.", error: error.message });
	}
};

exports.getAllArticlesWithCounts = async (req, res) => {
	try {
		console.log("Fetching articles with counts", req.query);
		const searchQuery = req.query.q || "";
		const articles = await Article.findAll({
			where: {
				[Sequelize.Op.or]: [
					Sequelize.where(Sequelize.fn("LOWER", Sequelize.col("title")), {
						[Sequelize.Op.like]: `%${searchQuery.toLowerCase()}%`,
					}),
					Sequelize.where(Sequelize.fn("LOWER", Sequelize.col("content")), {
						[Sequelize.Op.like]: `%${searchQuery.toLowerCase()}%`,
					}),
				],
			},
			attributes: {
				include: [
					[
						Sequelize.literal(`(
							SELECT COUNT(*) FROM comments AS comment
							WHERE comment.article_id = article.article_id
						)`),
						"comment_count",
					],
					[
						Sequelize.literal(`(
							SELECT COUNT(*) FROM likes AS like_tbl
							WHERE like_tbl.article_id = article.article_id
						)`),
						"like_count",
					],
				],
			},
			order: [["createdAt", "DESC"]],
		});

		// ✅ Convert article timestamps from UTC to Philippine time
		const articlesWithPHTimes = articles.map((article) => {
			const articleData = article.toJSON();
			if (articleData.createdAt) {
				articleData.createdAt = moment(articleData.createdAt)
					.tz("Asia/Manila")
					.format("YYYY-MM-DD HH:mm:ss");
			}
			if (articleData.updatedAt) {
				articleData.updatedAt = moment(articleData.updatedAt)
					.tz("Asia/Manila")
					.format("YYYY-MM-DD HH:mm:ss");
			}
			return articleData;
		});

		res.status(200).json(articlesWithPHTimes);
	} catch (err) {
		console.error("Error fetching articles with counts:", err);
		res.status(500).json({ message: "Server error", error: err.message });
	}
};

exports.toggleLike = async (req, res) => {
	const token = req.headers.authorization;
	const { article_id } = req.body;

	if (!token || !article_id) {
		return res
			.status(400)
			.json({ message: "Token and article_id are required" });
	}

	try {
		const decoded = jwt.verify(token, process.env.JWT_SECRET);
		const user_id = decoded.user_id;

		if (!user_id) {
			return res
				.status(400)
				.json({ message: "Invalid token: user_id not found" });
		}

		// Check if like already exists
		const existingLike = await Like.findOne({ where: { user_id, article_id } });
		const article = await Article.findByPk(article_id, {
			include: [{ model: User, as: "author" }],
		});

		if (!article) {
			return res.status(404).json({ message: "Article not found" });
		}

		if (existingLike) {
			// Unlike
			await existingLike.destroy();
			return res
				.status(200)
				.json({ liked: false, message: "Unliked successfully" });
		} else {
			// Like
			await Like.create({ user_id, article_id });

			// ✅ Notify article owner (except if the same user)
			if (article.author.user_id !== user_id) {
				await Notification.create({
					user_id: article.author.user_id,
					type: "like",
					title: "Your article got a like!",
					message: `Someone liked your article "${article.title}".`,
					related_id: article_id,
				});
			}

			return res
				.status(200)
				.json({ liked: true, message: "Liked successfully" });
		}
	} catch (error) {
		console.error("Error toggling like:", error);
		return res
			.status(500)
			.json({ message: "Server error", error: error.message });
	}
};

exports.getAllArticlesWithCountsByUser = async (req, res) => {
	const token = req.headers.authorization;

	if (!token) {
		return res
			.status(400)
			.json({ message: "Token is required in the headers" });
	}

	try {
		const decoded = jwt.verify(token, process.env.JWT_SECRET);
		const user_id = decoded.user_id;

		if (!user_id) {
			return res
				.status(400)
				.json({ message: "Invalid token: user_id not found" });
		}

		const searchQuery = req.query.q || "";
		const slugQuery = req.query.slug || "";

		let whereClause = {};

		if (slugQuery) {
			// ✅ Search ONLY by slug if ?slug= is provided
			whereClause = Sequelize.where(
				Sequelize.fn("LOWER", Sequelize.col("slug")),
				"LIKE",
				`%${slugQuery.toLowerCase()}%`
			);
		} else if (searchQuery) {
			// ✅ General search across title, content, excerpt, slug
			whereClause = {
				[Sequelize.Op.or]: [
					Sequelize.where(
						Sequelize.fn("LOWER", Sequelize.col("title")),
						"LIKE",
						`%${searchQuery.toLowerCase()}%`
					),
					Sequelize.where(
						Sequelize.fn("LOWER", Sequelize.col("content")),
						"LIKE",
						`%${searchQuery.toLowerCase()}%`
					),
					Sequelize.where(
						Sequelize.fn("LOWER", Sequelize.col("excerpt")),
						"LIKE",
						`%${searchQuery.toLowerCase()}%`
					),
					Sequelize.where(
						Sequelize.fn("LOWER", Sequelize.col("slug")),
						"LIKE",
						`%${searchQuery.toLowerCase()}%`
					),
				],
			};
		}

		const articles = await Article.findAll({
			where: whereClause,
			attributes: {
				include: [
					[
						Sequelize.literal(`(
              SELECT COUNT(*) FROM comments AS comment
              WHERE comment.article_id = article.article_id
            )`),
						"comment_count",
					],
					[
						Sequelize.literal(`(
              SELECT COUNT(*) FROM likes AS like_tbl
              WHERE like_tbl.article_id = article.article_id
            )`),
						"like_count",
					],
					[
						Sequelize.literal(`(
              SELECT COUNT(*) FROM likes AS like_tbl
              WHERE like_tbl.article_id = article.article_id
              AND like_tbl.user_id = ${user_id}
            ) > 0`),
						"user_liked",
					],
				],
			},
			order: [["createdAt", "DESC"]],
		});

		// ✅ Convert article timestamps from UTC to Philippine time
		const articlesWithPHTimes = articles.map((article) => {
			const articleData = article.toJSON();
			if (articleData.createdAt) {
				articleData.createdAt = moment(articleData.createdAt)
					.tz("Asia/Manila")
					.format("YYYY-MM-DD HH:mm:ss");
			}
			if (articleData.updatedAt) {
				articleData.updatedAt = moment(articleData.updatedAt)
					.tz("Asia/Manila")
					.format("YYYY-MM-DD HH:mm:ss");
			}
			return articleData;
		});

		res.status(200).json(articlesWithPHTimes);
	} catch (err) {
		console.error("Error decoding token or fetching articles:", err);
		res.status(500).json({ message: "Server error", error: err.message });
	}
};

// exports.getAllArticlesWithCountsByUser = async (req, res) => {
// 	const token = req.headers.authorization;

// 	if (!token) {
// 		return res
// 			.status(400)
// 			.json({ message: "Token is required in the headers" });
// 	}

// 	try {
// 		const decoded = jwt.verify(token, process.env.JWT_SECRET);
// 		const user_id = decoded.user_id;

// 		if (!user_id) {
// 			return res
// 				.status(400)
// 				.json({ message: "Invalid token: user_id not found" });
// 		}

// 		const searchQuery = req.query.q || "";

// 		const articles = await Article.findAll({
// 			where: searchQuery
// 				? {
// 						[Sequelize.Op.or]: [
// 							Sequelize.where(
// 								Sequelize.fn("LOWER", Sequelize.col("title")),
// 								"LIKE",
// 								`%${searchQuery.toLowerCase()}%`
// 							),
// 							Sequelize.where(
// 								Sequelize.fn("LOWER", Sequelize.col("content")),
// 								"LIKE",
// 								`%${searchQuery.toLowerCase()}%`
// 							),
// 							Sequelize.where(
// 								Sequelize.fn("LOWER", Sequelize.col("excerpt")),
// 								"LIKE",
// 								`%${searchQuery.toLowerCase()}%`
// 							),
// 						],
// 				  }
// 				: {},
// 			attributes: {
// 				include: [
// 					[
// 						Sequelize.literal(`(
//               SELECT COUNT(*) FROM comments AS comment
//               WHERE comment.article_id = article.article_id
//             )`),
// 						"comment_count",
// 					],
// 					[
// 						Sequelize.literal(`(
//               SELECT COUNT(*) FROM likes AS like_tbl
//               WHERE like_tbl.article_id = article.article_id
//             )`),
// 						"like_count",
// 					],
// 					[
// 						Sequelize.literal(`(
//               SELECT COUNT(*) FROM likes AS like_tbl
//               WHERE like_tbl.article_id = article.article_id
//               AND like_tbl.user_id = ${user_id}
//             ) > 0`),
// 						"user_liked",
// 					],
// 				],
// 			},
// 			order: [["createdAt", "DESC"]],
// 		});

// 		res.status(200).json(articles);
// 	} catch (err) {
// 		console.error("Error decoding token or fetching articles:", err);
// 		res.status(500).json({ message: "Server error", error: err.message });
// 	}
// };

exports.createComment = async (req, res) => {
	try {
		const { article_id, comment, parent_id } = req.body;
		const content = comment;

		const authHeader = req.headers.authorization;
		if (!authHeader)
			return res
				.status(401)
				.json({ message: "Authorization token is required." });

		const token = authHeader.split(" ")[1];
		if (!token)
			return res.status(401).json({ message: "JWT token not provided." });

		const decoded = jwt.verify(token, process.env.JWT_SECRET);
		const user_id = decoded.user_id;

		if (!article_id || !content)
			return res
				.status(400)
				.json({ message: "Article ID and content are required." });

		const article = await Article.findByPk(article_id, {
			include: [{ model: User, as: "author" }],
		});

		if (!article)
			return res.status(404).json({ message: "Article not found." });

		// If parent_id is provided, verify it exists and belongs to the same article
		if (parent_id) {
			const parentComment = await Comment.findOne({
				where: { comment_id: parent_id, article_id },
			});
			if (!parentComment) {
				return res.status(404).json({
					message: "Parent comment not found or doesn't belong to this article.",
				});
			}
		}

		const nowUTC = new Date().toISOString();

		const newComment = await Comment.create({
			article_id,
			user_id,
			content,
			parent_id: parent_id || null,
			createdAt: nowUTC,
			updatedAt: nowUTC,
		});

		// Notify author (if it's a top-level comment) or parent comment author (if it's a reply)
		if (parent_id) {
			// It's a reply - notify the parent comment author
			const parentComment = await Comment.findByPk(parent_id, {
				include: [{ model: User, as: "user" }],
			});
			if (parentComment && parentComment.user.user_id !== user_id) {
				await Notification.create({
					user_id: parentComment.user.user_id,
					type: "comment",
					title: "New Reply to Your Comment",
					message: `Someone replied to your comment on article "${article.title}".`,
					related_id: article_id,
				});
			}
		} else {
			// It's a top-level comment - notify article author
			if (article.author.user_id !== user_id) {
				await Notification.create({
					user_id: article.author.user_id,
					type: "comment",
					title: "New Comment on Your Article",
					message: `Someone commented on your article "${article.title}".`,
					related_id: article_id,
				});
			}
		}

		res
			.status(201)
			.json({ message: "Comment posted successfully.", comment: newComment });
	} catch (error) {
		console.error("Error posting comment:", error);
		res.status(500).json({ message: "Failed to post comment." });
	}
};

exports.deleteComment = async (req, res) => {
	const { comment_id } = req.params;

	try {
		const comment = await Comment.findByPk(comment_id);
		if (!comment) {
			return res.status(404).json({ message: "Comment not found." });
		}

		await comment.destroy();
		res.status(200).json({ message: "Comment deleted successfully." });
	} catch (error) {
		console.error("Error deleting comment:", error);
		res.status(500).json({ message: "Failed to delete comment." });
	}
};

// exports.getArticleById = async (req, res) => {
// 	const { id } = req.params;

// 	try {
// 		const article = await db.Article.findByPk(id, {
// 			include: [
// 				{
// 					model: db.Comment,
// 					as: "comments",
// 					attributes: ["comment_id", "user_id", "content", "createdAt"],
// 				},
// 				{ model: db.Like, as: "likes", attributes: ["like_id", "user_id"] },
// 			],
// 		});

// 		if (!article) {
// 			return res.status(404).json({ message: "Article not found." });
// 		}

// 		res.status(200).json(article);
// 	} catch (error) {
// 		console.error("🔥 Error fetching article by ID:", error.message);
// 		res.status(500).json({ message: "Server error retrieving article." });
// 	}
// };

// exports.getArticleById = async (req, res) => {
// 	const { id } = req.params;

// 	try {
// 		const article = await db.Article.findByPk(id, {
// 			include: [
// 				{
// 					model: db.Comment,
// 					as: "comments",
// 					attributes: ["comment_id", "user_id", "content", "createdAt"],
// 					include: [
// 						{
// 							model: db.User,
// 							as: "user",
// 							attributes: ["user_id", "role"],
// 						},
// 					],
// 				},
// 				{
// 					model: db.Like,
// 					as: "likes",
// 					attributes: ["like_id", "user_id"],
// 				},
// 			],
// 		});

// 		if (!article) {
// 			return res.status(404).json({ message: "Article not found." });
// 		}

// 		// ✅ Post-process comments to attach correct full name
// 		const commentsWithNames = await Promise.all(
// 			article.comments.map(async (comment) => {
// 				const user = comment.user;
// 				let fullName = "Unknown";

// 				if (!user) return { ...comment.toJSON(), fullName };

// 				switch (user.role) {
// 					case "admin":
// 						const admin = await db.Admin.findOne({
// 							where: { user_id: user.user_id },
// 							attributes: ["first_name", "last_name"],
// 						});
// 						if (admin) fullName = `${admin.first_name} ${admin.last_name}`;
// 						break;

// 					case "client": {
// 						const client = await db.Client.findOne({
// 							where: { user_id: user.user_id },
// 							attributes: ["first_name", "last_name"],
// 						});
// 						if (client) fullName = `${client.first_name} ${client.last_name}`;
// 						break;
// 					}

// 					case "doctor": {
// 						const doctor = await db.Doctor.findOne({
// 							where: { user_id: user.user_id },
// 							attributes: ["first_name", "last_name"],
// 						});
// 						if (doctor) fullName = `${doctor.first_name} ${doctor.last_name}`;
// 						break;
// 					}
// 				}

// 				return {
// 					...comment.toJSON(),
// 					fullName,
// 				};
// 			})
// 		);

// 		res.status(200).json({
// 			...article.toJSON(),
// 			comments: commentsWithNames,
// 		});
// 	} catch (error) {
// 		console.error("🔥 Error fetching article by ID:", error.message);
// 		res.status(500).json({ message: "Server error retrieving article." });
// 	}
// };

exports.getArticleById = async (req, res) => {
	const { id } = req.params;

	try {
		const article = await db.Article.findByPk(id, {
			include: [
				{
					model: db.Comment,
					as: "comments",
					attributes: [
						"comment_id",
						"user_id",
						"content",
						"parent_id",
						"createdAt",
						"updatedAt",
					],
					include: [
						{
							model: db.User,
							as: "user",
							attributes: ["user_id", "role"],
						},
						{
							model: db.Comment,
							as: "replies",
							attributes: [
								"comment_id",
								"user_id",
								"content",
								"parent_id",
								"createdAt",
								"updatedAt",
							],
							include: [
								{
									model: db.User,
									as: "user",
									attributes: ["user_id", "role"],
								},
							],
						},
					],
				},
				{
					model: db.Like,
					as: "likes",
					attributes: ["like_id", "user_id"],
				},
			],
		});

		if (!article) {
			return res.status(404).json({ message: "Article not found." });
		}

		// Helper function to get full name based on role
		const getFullName = async (user) => {
			if (!user) return "Unknown";

			switch (user.role) {
				case "admin": {
					const admin = await db.Admin.findOne({
						where: { user_id: user.user_id },
						attributes: ["first_name", "last_name"],
					});
					return admin ? `${admin.first_name} ${admin.last_name}` : "Unknown";
				}
				case "client": {
					const client = await db.Client.findOne({
						where: { user_id: user.user_id },
						attributes: ["first_name", "last_name"],
					});
					return client ? `${client.first_name} ${client.last_name}` : "Unknown";
				}
				case "doctor": {
					const doctor = await db.Doctor.findOne({
						where: { user_id: user.user_id },
						attributes: ["first_name", "last_name"],
					});
					return doctor ? `${doctor.first_name} ${doctor.last_name}` : "Unknown";
				}
				default:
					return "Unknown";
			}
		};

		// Process top-level comments (parent_id is null) and their replies
		const topLevelComments = article.comments.filter(
			(comment) => !comment.parent_id
		);

		const commentsWithNames = await Promise.all(
			topLevelComments.map(async (comment) => {
				const user = comment.user;
				const fullName = await getFullName(user);

				// Process replies
				const repliesWithNames = await Promise.all(
					comment.replies.map(async (reply) => {
						const replyUser = reply.user;
						const replyFullName = await getFullName(replyUser);
						const replyCreatedAtPH = moment(reply.createdAt)
							.tz("Asia/Manila")
							.format("YYYY-MM-DD HH:mm:ss");

						return {
							...reply.toJSON(),
							fullName: replyFullName,
							createdAt: replyCreatedAtPH,
						};
					})
				);

				// Convert createdAt (UTC) → Philippine time (Asia/Manila)
				const createdAtPH = moment(comment.createdAt)
					.tz("Asia/Manila")
					.format("YYYY-MM-DD HH:mm:ss");

				return {
					...comment.toJSON(),
					fullName,
					createdAt: createdAtPH,
					replies: repliesWithNames,
				};
			})
		);

		// ✅ Convert article timestamps from UTC to Philippine time
		const articleData = article.toJSON();
		if (articleData.createdAt) {
			articleData.createdAt = moment(articleData.createdAt)
				.tz("Asia/Manila")
				.format("YYYY-MM-DD HH:mm:ss");
		}
		if (articleData.updatedAt) {
			articleData.updatedAt = moment(articleData.updatedAt)
				.tz("Asia/Manila")
				.format("YYYY-MM-DD HH:mm:ss");
		}

		res.status(200).json({
			...articleData,
			comments: commentsWithNames,
		});
	} catch (error) {
		console.error("🔥 Error fetching article by ID:", error.message);
		res.status(500).json({ message: "Server error retrieving article." });
	}
};
