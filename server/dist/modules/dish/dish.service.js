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
    static async create(familyId, name, ingredients) {
        const sql = `
      INSERT INTO dishes (family_id, name, ingredients)
      VALUES ($1, $2, $3)
      RETURNING *
    `;
        const res = await (0, database_1.query)(sql, [familyId, name, JSON.stringify(ingredients)]);
        return res.rows[0];
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
