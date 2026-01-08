"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.AuthController = void 0;
const auth_service_1 = require("./auth.service");
class AuthController {
    static async sendCode(req, res) {
        try {
            const { email } = req.body;
            if (!email)
                return res.status(400).json({ error: 'Email required' });
            await auth_service_1.AuthService.sendCode(email);
            res.json({ success: true, message: 'Code sent (check console for MVP)' });
        }
        catch (err) {
            res.status(500).json({ error: err.message });
        }
    }
    static async verifyCode(req, res) {
        try {
            const { email, code } = req.body;
            if (!email || !code)
                return res.status(400).json({ error: 'Email and code required' });
            const result = await auth_service_1.AuthService.verifyCode(email, code);
            res.json(result);
        }
        catch (err) {
            res.status(401).json({ error: err.message });
        }
    }
}
exports.AuthController = AuthController;
