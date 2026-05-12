require('dotenv').config();

const config = {
  port: process.env.PORT || 3000,
  nodeEnv: process.env.NODE_ENV || 'development',
  redis: {
    host: process.env.REDIS_HOST || 'localhost',
    port: parseInt(process.env.REDIS_PORT, 10) || 6379,
  },
  gemini: {
    apiKey: process.env.GEMINI_API_KEY,
  },
  sharepoint: {
    clientId: process.env.SHAREPOINT_CLIENT_ID,
    clientSecret: process.env.SHAREPOINT_CLIENT_SECRET,
    tenantId: process.env.SHAREPOINT_TENANT_ID,
    siteId: process.env.SHAREPOINT_SITE_ID,
  },
};

// Validate critical config
const requiredConfigs = [
  'gemini.apiKey',
];

const missing = [];
requiredConfigs.forEach(key => {
  const value = key.split('.').reduce((obj, k) => obj && obj[k], config);
  if (!value) missing.push(key);
});

if (missing.length > 0 && config.nodeEnv === 'production') {
  console.error(`❌ Missing required configuration: ${missing.join(', ')}`);
  process.exit(1);
}

module.exports = config;
