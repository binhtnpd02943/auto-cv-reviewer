const express = require('express');
const router = express.Router();
const multer = require('multer');
const cvController = require('../controllers/cvController');

const upload = multer({ dest: 'uploads/' });

/**
 * @swagger
 * /api/review-cv:
 *   post:
 *     summary: 🚀 Upload CV và bắt đầu review
 *     tags: [CV Review]
 *     requestBody:
 *       required: true
 *       content:
 *         multipart/form-data:
 *           schema:
 *             type: object
 *             properties:
 *               cv:
 *                 type: string
 *                 format: binary
 *     responses:
 *       200:
 *         description: ✅ Trả về Job ID thành công
 */
router.post('/review-cv', upload.single('cv'), cvController.uploadAndReview);

/**
 * @swagger
 * /api/job/{id}:
 *   get:
 *     summary: 🔍 Kiểm tra trạng thái xử lý
 *     tags: [CV Review]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: ✅ Trả về kết quả Job
 */
router.get('/job/:id', cvController.getJobStatus);

module.exports = router;
