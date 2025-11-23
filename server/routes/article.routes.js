const express = require("express");
const router = express.Router();
const articleController = require("../controllers/article.controllers.js");
const upload = require("../middleware/upload");

router.post("/", upload.single("cover_image"), articleController.createArticle);
router.get("/by-like", articleController.getAllArticlesWithCountsByUser); // Specific route first
router.get("/", articleController.getAllArticlesWithCounts);
router.get("/:id", articleController.getArticleById); // Dynamic route last
router.post("/like", articleController.toggleLike);
router.post("/comment", articleController.createComment);
router.delete("/comment/:comment_id", articleController.deleteComment);
router.delete("/:article_id", articleController.deleteArticle);
router.get("/slugs/list", articleController.getAllSlugs);
module.exports = router;
