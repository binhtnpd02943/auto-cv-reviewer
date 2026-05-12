const swaggerJsdoc = require('swagger-jsdoc');
const swaggerUi = require('swagger-ui-express');
const path = require('path');

const options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'Auto CV Reviewer API',
      version: '1.0.0',
      description:
        'Tài liệu API cho hệ thống phân tích và chấm điểm CV tự động bằng AI (BullMQ + Gemini).',
      contact: {
        name: 'Backend Team',
      },
    },
    // --- CHÂN ÁI NẰM Ở ĐÂY ---
    servers: [
      {
        url: '/', // Tự động nhận diện host và giao thức (http/https) hiện tại
        description: 'Current Environment (Auto-detected)',
      },
      {
        url: 'http://localhost:3000',
        description: 'Local Development Server',
      },
    ],
  },
  apis: [path.join(__dirname, '../routes/*.js')],
};

const swaggerSpec = swaggerJsdoc(options);

function swaggerDocs(app) {
  // Thêm options explorer để giao diện trực quan hơn
  app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec, {
    explorer: true,
  }));

  app.get('/docs.json', (req, res) => {
    res.json(swaggerSpec);
  });
}

module.exports = swaggerDocs;
