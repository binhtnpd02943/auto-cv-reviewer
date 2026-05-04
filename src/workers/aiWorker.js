// src/workers/aiWorker.js
const { Worker } = require('bullmq');
const aiService = require('../services/aiService');
const { connection, successQueue } = require('../queues');

const worker = new Worker(
  '2-ai-processing',
  async (job) => {
    const { cvText, originalName, jobIdOriginal } = job.data;

    const currentAttempt = job.attemptsMade + 1;
    const maxAttempts = job.opts.attempts;

    console.log(
      `[Phase 2] AI phân tích: ${originalName} (Lần thử: ${currentAttempt}/${maxAttempts})`,
    );

    try {
      const result = await aiService.analyzeCV(cvText);

      await successQueue.add('save-data', {
        result,
        originalName,
        jobIdOriginal,
        finalAttempts: currentAttempt,
      });

      return 'AI phân tích xong';
    } catch (error) {
      const is429 = error.status === 429 || error.message?.includes('429');

      if (is429) {
        console.warn(
          `[Phase 2] ⛔ Lỗi 429. Dừng hàng đợi. (Lưu ý: Lần thử ${currentAttempt} này KHÔNG bị tính là failed)`,
        );
        throw Worker.RateLimitError();
      }

      console.error(
        `[Phase 2] ❌ Lỗi Job ${job.id} (Lần ${currentAttempt}):`,
        error.message,
      );
      throw error;
    }
  },
  {
    connection,
    concurrency: 3,
    limiter: {
      max: 15,
      duration: 60000,
    },
  },
);

worker.on('failed', (job, err) => {
  if (err.name !== 'RateLimitError') {
    console.log(
      `[Alert] Job ${job.id} THẤT BẠI HOÀN TOÀN sau ${job.attemptsMade} lần thử: ${err.message}`,
    );
  }
});

module.exports = worker;
