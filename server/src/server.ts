import dotenv from 'dotenv';
import path from 'path';

// 1. Load environment variables BEFORE importing app
// Try to load from project root (assuming running from dist/)
const envPath = path.resolve(__dirname, '../.env');
console.log(`Loading .env from: ${envPath}`);
const result = dotenv.config({ path: envPath });

if (result.error) {
  console.warn('Warning: .env file not found at calculated path, trying default CWD...');
  dotenv.config(); // Fallback to default
}

import app from './app';

const PORT = process.env.PORT || 3000;

const server = app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});

process.on('SIGTERM', () => {
  console.log('SIGTERM signal received: closing HTTP server');
  server.close(() => {
    console.log('HTTP server closed');
  });
});
