// app.js
require('dotenv').config();
const express = require('express');
const routes = require('./routes/api');

const swaggerDocs = require('./config/swagger');

// Cấu hình BullMQ & Các Workers ---
const { extractQueue, aiQueue, successQueue } = require('./queues');
require('./workers/extractWorker');
require('./workers/aiWorker');
require('./workers/successWorker');

// Cấu hình Giao diện Bull-Board ---
const { createBullBoard } = require('@bull-board/api');
const { BullMQAdapter } = require('@bull-board/api/bullMQAdapter');
const { ExpressAdapter } = require('@bull-board/express');

const serverAdapter = new ExpressAdapter();
serverAdapter.setBasePath('/admin/queues');

createBullBoard({
  queues: [
    new BullMQAdapter(extractQueue),
    new BullMQAdapter(aiQueue),
    new BullMQAdapter(successQueue),
  ],
  serverAdapter: serverAdapter,
});
// -------------------------------------

const app = express();
const port = process.env.PORT || 3000;

// Middleware parse JSON
app.use(express.json());

// Gắn giao diện Dashboard quản lý Queue cho Backend Team
app.use('/admin/queues', serverAdapter.getRouter());

// Gắn các API routes chính
app.use('/api', routes);

// Route test server
app.get('/', (req, res) => {
  res.send('Hệ thống Pipeline Auto CV Reviewer đang chạy!');
});

swaggerDocs(app);

// Khởi động server
app.listen(port, () => {
  console.log(`\n======================================================`);
  console.log(`🚀 Server connected to http://localhost:${port}`);

  console.log(
    `📖 Swagger tự động quét API tại: http://localhost:${port}/api-docs`,
  );

  console.log(`📊 Queues: http://localhost:${port}/admin/queues`);
  console.log(`======================================================`);
});
