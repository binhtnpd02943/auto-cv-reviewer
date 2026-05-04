// src/controllers/cvController.js
const fs = require('fs');
const { extractQueue, aiQueue, successQueue } = require('../queues');

const uploadAndReview = async (req, res) => {
  try {
    if (!req.file) {
      return res
        .status(400)
        .json({ message: 'Vui lòng upload file CV (PDF).' });
    }

    // Tạo một ID duy nhất để theo dõi CV này xuyên suốt 3 công đoạn
    const trackingId = `CV-${Date.now()}-${Math.round(Math.random() * 1000)}`;

    // Đẩy thông tin file vào hàng đợi đầu tiên (Extract PDF)
    await extractQueue.add(
      'extract',
      {
        filePath: req.file.path,
        originalName: req.file.originalname,
        jobIdOriginal: trackingId,
      },
      {
        jobId: trackingId,
      },
    );

    res.status(200).json({
      message: 'Hệ thống đã tiếp nhận CV và đưa vào dây chuyền xử lý!',
      trackingId: trackingId,
      status: 'processing',
    });
  } catch (error) {
    if (req.file) {
      fs.unlinkSync(req.file.path);
    }
    res.status(500).json({ message: error.message });
  }
};

const getJobStatus = async (req, res) => {
  const { id } = req.params;

  try {
    // Quét lần lượt qua 3 hàng đợi để xem CV đang nằm ở đâu
    const successJob = await successQueue.getJob(id);

    if (successJob) {
      const state = await successJob.getState();
      return res.json({
        trackingId: id,
        currentPhase: '3-success-sync',
        state: state,
        result: successJob.returnvalue || 'Đang lưu trữ dữ liệu...',
      });
    }

    const aiJob = await aiQueue.getJob(id);
    if (aiJob) {
      const state = await aiJob.getState();
      return res.json({
        trackingId: id,
        currentPhase: '2-ai-processing',
        state: state,
        message: 'AI đang phân tích dữ liệu, vui lòng chờ...',
      });
    }

    const extractJob = await extractQueue.getJob(id);
    if (extractJob) {
      const state = await extractJob.getState();
      return res.json({
        trackingId: id,
        currentPhase: '1-extract-pdf',
        state: state,
        message: 'Đang trích xuất văn bản từ PDF...',
      });
    }

    // Nếu không tìm thấy ở cả 3 queue
    res
      .status(404)
      .json({ message: 'Không tìm thấy tiến trình xử lý cho CV này.' });
  } catch (error) {
    res.status(500).json({
      message: 'Lỗi khi kiểm tra trạng thái CV',
      error: error.message,
    });
  }
};

module.exports = { uploadAndReview, getJobStatus };
