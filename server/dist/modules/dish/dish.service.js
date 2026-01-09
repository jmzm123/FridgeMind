"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.DishService = void 0;
const database_1 = require("../../config/database");
const ingredient_service_1 = require("../ingredient/ingredient.service");
class DishService {
    static async listByFamily(familyId) {
        const sql = `SELECT * FROM dishes WHERE family_id = $1 ORDER BY created_at DESC`;
        const res = await (0, database_1.query)(sql, [familyId]);
        return res.rows;
    }
    static async get(id, familyId) {
        const sql = `SELECT * FROM dishes WHERE id = $1 AND family_id = $2`;
        const res = await (0, database_1.query)(sql, [id, familyId]);
        return res.rows[0];
    }
    static async create(familyId, name, ingredients, steps = [], description = '', cookingMethod = '') {
        const sql = `
      INSERT INTO dishes (family_id, name, ingredients, steps, description, cooking_method)
      VALUES ($1, $2, $3, $4, $5, $6)
      RETURNING *
    `;
        const res = await (0, database_1.query)(sql, [
            familyId,
            name,
            JSON.stringify(ingredients),
            JSON.stringify(steps),
            description,
            cookingMethod
        ]);
        return res.rows[0];
    }
    static async update(id, familyId, updates) {
        const sql = `
      UPDATE dishes 
      SET name = $1, ingredients = $2, steps = $3, description = $4, cooking_method = $5, updated_at = NOW()
      WHERE id = $6 AND family_id = $7
      RETURNING *
    `;
        const res = await (0, database_1.query)(sql, [
            updates.name,
            JSON.stringify(updates.ingredients),
            JSON.stringify(updates.steps),
            updates.description,
            updates.cookingMethod,
            id,
            familyId
        ]);
        return res.rows[0];
    }
    static async delete(id, familyId) {
        const sql = `DELETE FROM dishes WHERE id = $1 AND family_id = $2`;
        const res = await (0, database_1.query)(sql, [id, familyId]);
        return (res.rowCount ?? 0) > 0;
    }
    // 做饭决策辅助
    static async makeDecision(familyId, dishIds) {
        // 1. 获取选中的菜品
        const dishesRes = await (0, database_1.query)(`SELECT * FROM dishes WHERE id = ANY($1) AND family_id = $2`, [dishIds, familyId]);
        const dishes = dishesRes.rows;
        // 2. 获取当前库存
        const inventory = await ingredient_service_1.IngredientService.listByFamily(familyId);
        // 建立库存索引：Name -> Item[]
        const stockMap = {};
        inventory.forEach(item => {
            if (!item)
                return;
            if (!stockMap[item.name])
                stockMap[item.name] = [];
            stockMap[item.name].push(item);
        });
        const available = [];
        const needPreparation = [];
        // 3. 逐个分析菜品
        for (const dish of dishes) {
            let needsDefrost = false;
            let missing = false;
            const requiredIngredients = dish.ingredients; // JSONB parsed auto? pg usually does
            for (const req of requiredIngredients) {
                const stockItems = stockMap[req.name];
                if (!stockItems || stockItems.length === 0) {
                    missing = true; // 缺食材
                    break;
                }
                // 检查是否有非冷冻的
                const hasFresh = stockItems.some(item => item.storage_type !== 'frozen');
                if (!hasFresh) {
                    // 只有冷冻的，需要解冻
                    needsDefrost = true;
                }
            }
            if (missing) {
                // 缺食材暂不推荐，或者放入单独列表 (MVP忽略)
                continue;
            }
            if (needsDefrost) {
                needPreparation.push({
                    dishId: dish.id,
                    name: dish.name,
                    action: 'defrost',
                    reason: 'Only frozen ingredients available'
                });
            }
            else {
                available.push(dish);
            }
        }
        return { available, needPreparation };
    }
}
exports.DishService = DishService;
