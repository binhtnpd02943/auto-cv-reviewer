// src/workers/successWorker.js (hoặc file bạn dùng để xử lý successQueue)
const { Worker } = require('bullmq');
const { connection } = require('../queues');
// const db = require('../models/db'); // Import DB của bạn

const successWorker = new Worker(
  '3-success-sync',
  async (job) => {
    // Bắt lấy finalAttempts từ Queue 2 truyền sang
    const { result, originalName, jobIdOriginal, finalAttempts } = job.data;

    console.log(
      `[Phase 3] Đang lưu CV: ${originalName}. Số lần AI đã xử lý: ${finalAttempts}`,
    );

    // Logic lưu Database của bạn
    /*
    await db.CV.update(
      { jobId: jobIdOriginal },
      {
        status: 'COMPLETED',
        aiResult: result,
        retries_count: finalAttempts // <-- Lưu cột này vào DB để xuất Report
      }
    );
    */

    return 'Lưu Database thành công';
  },
  { connection, concurrency: 5 },
);

module.exports = successWorker;
