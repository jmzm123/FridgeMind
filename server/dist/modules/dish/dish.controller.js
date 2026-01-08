"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.DishController = void 0;
const dish_service_1 = require("./dish.service");
class DishController {
    static async list(req, res) {
        try {
            const { familyId } = req.params;
            const dishes = await dish_service_1.DishService.listByFamily(familyId);
            res.json(dishes);
        }
        catch (err) {
            res.status(500).json({ error: err.message });
        }
    }
    static async create(req, res) {
        try {
            const { familyId } = req.params;
            const { name, ingredients } = req.body;
            if (!name)
                return res.status(400).json({ error: 'Name required' });
            const dish = await dish_service_1.DishService.create(familyId, name, ingredients || []);
            res.status(201).json(dish);
        }
        catch (err) {
            res.status(500).json({ error: err.message });
        }
    }
    static async decide(req, res) {
        try {
            const { familyId } = req.params;
            const { dishIds } = req.body;
            if (!dishIds || !Array.isArray(dishIds)) {
                return res.status(400).json({ error: 'dishIds array required' });
            }
            const result = await dish_service_1.DishService.makeDecision(familyId, dishIds);
            res.json(result);
        }
        catch (err) {
            res.status(500).json({ error: err.message });
        }
    }
}
exports.DishController = DishController;
