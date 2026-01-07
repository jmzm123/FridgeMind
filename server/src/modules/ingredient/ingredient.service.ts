import { query } from '../../config/database';

export interface CreateIngredientDTO {
  familyId: string;
  name: string;
  storageType: 'frozen' | 'chilled' | 'room';
  quantity: number;
  unit: string;
}

export interface UpdateIngredientDTO {
  storageType?: 'frozen' | 'chilled' | 'room';
  quantity?: number;
  unit?: string;
  name?: string;
}

export class IngredientService {
  // 获取列表 (排除已删除的)
  static async listByFamily(familyId: string) {
    const sql = `
      SELECT * FROM ingredients 
      WHERE family_id = $1 AND deleted_at IS NULL
      ORDER BY expire_at ASC NULLS LAST, created_at DESC
    `;
    const res = await query(sql, [familyId]);
    return res.rows;
  }

  // 新增食材
  static async create(data: CreateIngredientDTO) {
    // 简单计算 expire_at (MVP 逻辑: 冷冻90天，冷藏7天，常温30天)
    // 实际应该由 AI 或更复杂的规则决定，这里先硬编码
    let expireDays = 30;
    if (data.storageType === 'frozen') expireDays = 90;
    if (data.storageType === 'chilled') expireDays = 7;
    
    const expireAt = new Date();
    expireAt.setDate(expireAt.getDate() + expireDays);

    const sql = `
      INSERT INTO ingredients (family_id, name, storage_type, quantity, unit, expire_at)
      VALUES ($1, $2, $3, $4, $5, $6)
      RETURNING *
    `;
    
    const res = await query(sql, [
      data.familyId,
      data.name,
      data.storageType,
      data.quantity,
      data.unit,
      expireAt
    ]);
    return res.rows[0];
  }

  // 更新食材
  static async update(id: string, data: UpdateIngredientDTO) {
    // 动态构建 update 语句
    const fields: string[] = [];
    const values: any[] = [];
    let idx = 1;

    if (data.name) { fields.push(`name = $${idx++}`); values.push(data.name); }
    if (data.quantity !== undefined) { fields.push(`quantity = $${idx++}`); values.push(data.quantity); }
    if (data.unit) { fields.push(`unit = $${idx++}`); values.push(data.unit); }
    if (data.storageType) { fields.push(`storage_type = $${idx++}`); values.push(data.storageType); }

    if (fields.length === 0) return null;

    values.push(id);
    const sql = `
      UPDATE ingredients 
      SET ${fields.join(', ')}, updated_at = NOW()
      WHERE id = $${idx} AND deleted_at IS NULL
      RETURNING *
    `;
    
    const res = await query(sql, values);
    return res.rows[0];
  }

  // 软删除
  static async delete(id: string) {
    const sql = `
      UPDATE ingredients 
      SET deleted_at = NOW()
      WHERE id = $1 AND deleted_at IS NULL
      RETURNING id
    `;
    const res = await query(sql, [id]);
    return res.rowCount && res.rowCount > 0;
  }
}
