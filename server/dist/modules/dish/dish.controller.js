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
    static async get(req, res) {
        try {
            const { familyId, id } = req.params;
            const dish = await dish_service_1.DishService.get(id, familyId);
            if (!dish)
                return res.status(404).json({ error: 'Dish not found' });
            res.json(dish);
        }
        catch (err) {
            res.status(500).json({ error: err.message });
        }
    }
    static async create(req, res) {
        try {
            const { familyId } = req.params;
            const { name, ingredients, steps, description, cookingMethod } = req.body;
            if (!name)
                return res.status(400).json({ error: 'Name required' });
            const dish = await dish_service_1.DishService.create(familyId, name, ingredients || [], steps || [], description || '', cookingMethod || '');
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
    static async update(req, res) {
        try {
            const { familyId, id } = req.params;
            const { name, ingredients, steps, description, cookingMethod } = req.body;
            const dish = await dish_service_1.DishService.update(id, familyId, { name, ingredients, steps, description, cookingMethod });
            if (!dish)
                return res.status(404).json({ error: 'Dish not found' });
            res.json(dish);
        }
        catch (err) {
            res.status(500).json({ error: err.message });
        }
    }
    static async delete(req, res) {
        try {
            const { familyId, id } = req.params;
            const success = await dish_service_1.DishService.delete(id, familyId);
            if (!success)
                return res.status(404).json({ error: 'Dish not found' });
            res.json({ success: true });
        }
        catch (err) {
            res.status(500).json({ error: err.message });
        }
    }
}
exports.DishController = DishController;
