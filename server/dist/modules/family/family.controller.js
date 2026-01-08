"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.FamilyController = void 0;
const family_service_1 = require("./family.service");
class FamilyController {
    static async create(req, res) {
        try {
            const userId = req.user.userId;
            const { name } = req.body;
            if (!name)
                return res.status(400).json({ error: 'Family name required' });
            const family = await family_service_1.FamilyService.createFamily(userId, name);
            res.status(201).json(family);
        }
        catch (err) {
            res.status(500).json({ error: err.message });
        }
    }
    static async list(req, res) {
        try {
            const userId = req.user.userId;
            const families = await family_service_1.FamilyService.getMyFamilies(userId);
            res.json(families);
        }
        catch (err) {
            res.status(500).json({ error: err.message });
        }
    }
}
exports.FamilyController = FamilyController;
