"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.AuthService = void 0;
const database_1 = require("../../config/database");
const jwt_1 = require("../../utils/jwt");
class AuthService {
    // 发送验证码 (MVP: 仅记录到数据库，不发邮件，固定返回 success)
    static async sendCode(email) {
        const code = '123456'; // MVP 固定验证码方便测试
        const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 mins
        // 先清理旧的
        await (0, database_1.query)('DELETE FROM login_codes WHERE email = $1', [email]);
        // 插入新的
        await (0, database_1.query)('INSERT INTO login_codes (email, code, expires_at) VALUES ($1, $2, $3)', [email, code, expiresAt]);
        console.log(`[DEV] Code for ${email}: ${code}`);
        return true;
    }
    // 验证登录
    static async verifyCode(email, code) {
        // 1. 查验证码
        const res = await (0, database_1.query)('SELECT * FROM login_codes WHERE email = $1 AND code = $2 AND expires_at > NOW()', [email, code]);
        if (res.rows.length === 0) {
            throw new Error('Invalid or expired code');
        }
        // 2. 验证通过，删除验证码
        await (0, database_1.query)('DELETE FROM login_codes WHERE email = $1', [email]);
        // 3. 查找或创建用户
        let userRes = await (0, database_1.query)('SELECT * FROM users WHERE email = $1', [email]);
        let user = userRes.rows[0];
        if (!user) {
            userRes = await (0, database_1.query)('INSERT INTO users (email) VALUES ($1) RETURNING *', [email]);
            user = userRes.rows[0];
        }
        // 4. 签发 Token
        const token = (0, jwt_1.signToken)({ userId: user.id, email: user.email });
        return { token, user };
    }
}
exports.AuthService = AuthService;
