const { Worker } = require('bullmq');
const fs = require('fs').promises;
const pdfService = require('../services/pdfService');
const { connection, aiQueue } = require('../queues'); // Import queue tiếp theo

const worker = new Worker(
  '1-extract-pdf',
  async (job) => {
    const { filePath, originalName, jobIdOriginal } = job.data;
    console.log(`[Phase 1] Đang đọc PDF: ${originalName}`);

    try {
      const cvText = await pdfService.extractTextFromPDF(filePath);

      // Đọc xong -> Đẩy sang công đoạn 2 (AI)
      await aiQueue.add('analyze', {
        cvText,
        originalName,
        jobIdOriginal,
      });

      return 'Trích xuất text thành công';
    } finally {
      await fs.unlink(filePath).catch((e) => console.error(e));
    }
  },
  { connection, concurrency: 10 },
);

module.exports = worker;
