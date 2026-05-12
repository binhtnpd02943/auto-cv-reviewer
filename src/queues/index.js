// src/queues/index.js
const { Queue } = require('bullmq');
const IORedis = require('ioredis');
const config = require('../config');

// 1. Cấu hình Redis Connection
const redisConfig = {
  ...config.redis,
  maxRetriesPerRequest: null,
  enableReadyCheck: false,
};

const connection = new IORedis(redisConfig);

// 2. Định nghĩa hằng số
const JOB_KEEP_LIMIT = {
  COMPLETED: 500,
  FAILED: 1000,
  AGE: 24 * 3600,
};

// 3. Cấu hình mặc định (Áp dụng chung)
const defaultJobOptions = {
  removeOnFail: {
    age: 7 * 24 * 3600,
    count: JOB_KEEP_LIMIT.FAILED,
  },
  attempts: 5,
  backoff: {
    type: 'exponential',
    delay: 3000,
  },
};

// 4. Khởi tạo Queues
// CÔNG ĐOẠN 1: Trích xuất PDF
const extractQueue = new Queue('1-extract-pdf', {
  connection,
  defaultJobOptions: {
    ...defaultJobOptions,
    removeOnComplete: true,
  },
});

// CÔNG ĐOẠN 2: Xử lý AI
const aiQueue = new Queue('2-ai-processing', {
  connection,
  defaultJobOptions: {
    ...defaultJobOptions,
    removeOnComplete: true,
  },
});

// CÔNG ĐOẠN 3: Đồng bộ/Lưu trữ
const successQueue = new Queue('3-success-sync', {
  connection,
  defaultJobOptions: {
    ...defaultJobOptions,
    removeOnComplete: {
      count: JOB_KEEP_LIMIT.COMPLETED,
      age: JOB_KEEP_LIMIT.AGE,
    },
  },
});

// 5. Hệ thống Logging
const setupQueueEvents = (queue) => {
  queue.on('error', (err) => {
    console.error(`[Lỗi hệ thống Queue] ${queue.name}:`, err.message);
  });
};

[extractQueue, aiQueue, successQueue].forEach(setupQueueEvents);

module.exports = {
  extractQueue,
  aiQueue,
  successQueue,
  connection,
};
