import { query } from '../../config/database';
import { IngredientService } from '../ingredient/ingredient.service';

interface DishIngredient {
  name: string;
  quantity: string | number;
  unit: string;
}

export class DishService {
  static async listByFamily(familyId: string) {
    const sql = `SELECT * FROM dishes WHERE family_id = $1 ORDER BY created_at DESC`;
    const res = await query(sql, [familyId]);
    return res.rows;
  }

  static async get(id: string, familyId: string) {
    const sql = `SELECT * FROM dishes WHERE id = $1 AND family_id = $2`;
    const res = await query(sql, [id, familyId]);
    return res.rows[0];
  }

  static async create(familyId: string, name: string, ingredients: DishIngredient[], steps: string[] = [], description: string = '', cookingMethod: string = '') {
    const sql = `
      INSERT INTO dishes (family_id, name, ingredients, steps, description, cooking_method)
      VALUES ($1, $2, $3, $4, $5, $6)
      RETURNING *
    `;
    const res = await query(sql, [
      familyId, 
      name, 
      JSON.stringify(ingredients),
      JSON.stringify(steps),
      description,
      cookingMethod
    ]);
    return res.rows[0];
  }

  static async update(id: string, familyId: string, updates: { name: string, ingredients: DishIngredient[], steps: string[], description: string, cookingMethod: string }) {
    const sql = `
      UPDATE dishes 
      SET name = $1, ingredients = $2, steps = $3, description = $4, cooking_method = $5, updated_at = NOW()
      WHERE id = $6 AND family_id = $7
      RETURNING *
    `;
    const res = await query(sql, [
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

  static async delete(id: string, familyId: string) {
    const sql = `DELETE FROM dishes WHERE id = $1 AND family_id = $2`;
    const res = await query(sql, [id, familyId]);
    return (res.rowCount ?? 0) > 0;
  }

  // 做饭决策辅助
  static async makeDecision(familyId: string, dishIds: string[]) {
    // 1. 获取选中的菜品
    const dishesRes = await query(
      `SELECT * FROM dishes WHERE id = ANY($1) AND family_id = $2`,
      [dishIds, familyId]
    );
    const dishes = dishesRes.rows;

    // 2. 获取当前库存
    const inventory = await IngredientService.listByFamily(familyId);
    
    // 建立库存索引：Name -> Item[]
    const stockMap: Record<string, any[]> = {};
    inventory.forEach(item => {
      if (!item) return;
      if (!stockMap[item.name]) stockMap[item.name] = [];
      stockMap[item.name].push(item);
    });

    const available: any[] = [];
    const needPreparation: any[] = [];

    // 3. 逐个分析菜品
    for (const dish of dishes) {
      let needsDefrost = false;
      let missing = false;

      const requiredIngredients: DishIngredient[] = dish.ingredients; // JSONB parsed auto? pg usually does

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
      } else {
        available.push(dish);
      }
    }

    return { available, needPreparation };
  }
}
