"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.FamilyService = void 0;
const database_1 = require("../../config/database");
class FamilyService {
    static async createFamily(userId, name) {
        const client = await Promise.resolve().then(() => __importStar(require('../../config/database'))).then(m => m.default.connect());
        try {
            await client.query('BEGIN');
            // 1. Create Family
            const familyRes = await client.query('INSERT INTO families (name, owner_user_id) VALUES ($1, $2) RETURNING *', [name, userId]);
            const family = familyRes.rows[0];
            // 2. Add Owner as Member
            await client.query('INSERT INTO family_members (family_id, user_id, role) VALUES ($1, $2, $3)', [family.id, userId, 'owner']);
            await client.query('COMMIT');
            return family;
        }
        catch (err) {
            await client.query('ROLLBACK');
            throw err;
        }
        finally {
            client.release();
        }
    }
    static async getMyFamilies(userId) {
        const sql = `
      SELECT f.*, fm.role 
      FROM families f
      JOIN family_members fm ON f.id = fm.family_id
      WHERE fm.user_id = $1
      ORDER BY f.created_at DESC
    `;
        const res = await (0, database_1.query)(sql, [userId]);
        return res.rows;
    }
}
exports.FamilyService = FamilyService;
