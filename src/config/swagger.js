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
    servers: [
      {
        url: 'http://localhost:3000',
        description: 'Development Server',
      },
    ],
  },
  apis: [path.join(__dirname, '../routes/*.js')],
};

const swaggerSpec = swaggerJsdoc(options);

function swaggerDocs(app) {
  app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));

  app.get('/docs.json', (req, res) => {
    res.json(swaggerSpec);
  });
}

module.exports = swaggerDocs;
