// app.js
const config = require('./config');
const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const morgan = require('morgan');
const compression = require('compression');
const rateLimit = require('express-rate-limit');

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

// Security & Optimization Middleware
app.use(helmet());
app.use(cors());
app.use(compression());
app.use(express.json());
app.use(morgan(config.nodeEnv === 'production' ? 'combined' : 'dev'));

// Rate Limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // limit each IP to 100 requests per windowMs
});
app.use('/api/', limiter);

// Health Check
app.get('/health', async (req, res) => {
  try {
    // Check Redis connection via one of the queues
    await extractQueue.client;
    res.status(200).json({ status: 'OK', environment: config.nodeEnv });
  } catch (err) {
    res.status(503).json({ status: 'Error', message: 'Redis unavailable' });
  }
});

// Giao diện Dashboard quản lý Queue
app.use('/admin/queues', serverAdapter.getRouter());

// Các API routes chính
app.use('/api', routes);

// Route test server
app.get('/', (req, res) => {
  res.send('Hệ thống Pipeline Auto CV Reviewer đang chạy!');
});

swaggerDocs(app);

// Global Error Handler
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ 
    message: 'Internal Server Error',
    error: config.nodeEnv === 'development' ? err.message : {}
  });
});

// Khởi động server
const server = app.listen(config.port, () => {
  console.log(`\n======================================================`);
  console.log(`🚀 Server connected to http://localhost:${config.port}`);
  console.log(`🌍 Environment: ${config.nodeEnv}`);
  console.log(`======================================================`);
});

// Graceful Shutdown
const gracefulShutdown = (signal) => {
  console.log(`\nReceived ${signal}. Shutting down gracefully...`);
  server.close(async () => {
    console.log('HTTP server closed.');
    try {
      await Promise.all([
        extractQueue.close(),
        aiQueue.close(),
        successQueue.close()
      ]);
      console.log('Redis connections closed.');
      process.exit(0);
    } catch (err) {
      console.error('Error during shutdown:', err);
      process.exit(1);
    }
  });
};

process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));
