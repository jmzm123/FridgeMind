"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const dotenv_1 = __importDefault(require("dotenv"));
const path_1 = __importDefault(require("path"));
// 1. Load environment variables BEFORE importing app
// Try to load from project root (assuming running from dist/)
const envPath = path_1.default.resolve(__dirname, '../.env');
console.log(`Loading .env from: ${envPath}`);
const result = dotenv_1.default.config({ path: envPath });
if (result.error) {
    console.warn('Warning: .env file not found at calculated path, trying default CWD...');
    dotenv_1.default.config(); // Fallback to default
}
const app_1 = __importDefault(require("./app"));
const PORT = process.env.PORT || 3000;
const server = app_1.default.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
});
process.on('SIGTERM', () => {
    console.log('SIGTERM signal received: closing HTTP server');
    server.close(() => {
        console.log('HTTP server closed');
    });
});
