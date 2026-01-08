import { query } from '../../config/database';

export interface CreateIngredientDTO {
  familyId: string;
  name: string;
  storageType: 'frozen' | 'chilled' | 'room' | 'pantry' | 'refrigerated';
  quantity: number;
  unit: string;
  expirationDate?: string;
  createdAt?: string;
}

export interface UpdateIngredientDTO {
  storageType?: 'frozen' | 'chilled' | 'room' | 'pantry' | 'refrigerated';
  quantity?: number;
  unit?: string;
  name?: string;
  expirationDate?: string;
  createdAt?: string;
}

const toResponse = (row: any) => {
  if (!row) return null;
  return {
    id: row.id,
    _id: row.id,
    familyId: row.family_id,
    name: row.name,
    storageType: row.storage_type,
    quantity: parseFloat(row.quantity),
    unit: row.unit,
    expirationDate: row.expire_at,
    imageUrl: row.image_url,
    createdAt: row.created_at,
    updatedAt: row.updated_at
  };
};

export class IngredientService {
  // 获取列表 (排除已删除的)
  static async listByFamily(familyId: string) {
    const sql = `
      SELECT * FROM ingredients 
      WHERE family_id = $1 AND deleted_at IS NULL
      ORDER BY expire_at ASC NULLS LAST, created_at DESC
    `;
    const res = await query(sql, [familyId]);
    return res.rows.map(toResponse);
  }

  // 新增食材
  static async create(data: CreateIngredientDTO) {
    let expireAt;
    
    if (data.expirationDate) {
        expireAt = new Date(data.expirationDate);
    } else {
        // 简单计算 expire_at (MVP 逻辑: 冷冻90天，冷藏7天，常温30天)
        // 实际应该由 AI 或更复杂的规则决定，这里先硬编码
        let expireDays = 30;
        if (data.storageType === 'frozen') expireDays = 90;
        if (data.storageType === 'chilled' || data.storageType === 'refrigerated') expireDays = 7;
        
        expireAt = new Date();
        expireAt.setDate(expireAt.getDate() + expireDays);
    }

    const sql = `
      INSERT INTO ingredients (family_id, name, storage_type, quantity, unit, expire_at, created_at)
      VALUES ($1, $2, $3, $4, $5, $6, $7)
      RETURNING *
    `;
    
    const res = await query(sql, [
      data.familyId,
      data.name,
      data.storageType,
      data.quantity,
      data.unit,
      expireAt,
      data.createdAt ? new Date(data.createdAt) : new Date()
    ]);
    return toResponse(res.rows[0]);
  }

  // 更新食材
  static async update(id: string, data: UpdateIngredientDTO) {
    // 消耗控制：如果数量 <= 0，则从冰箱移除 (软删除)
    if (data.quantity !== undefined && data.quantity <= 0) {
        await this.delete(id);
        return { id, deleted: true };
    }

    // 动态构建 update 语句
    const fields: string[] = [];
    const values: any[] = [];
    let idx = 1;

    if (data.name) { fields.push(`name = $${idx++}`); values.push(data.name); }
    if (data.quantity !== undefined) { fields.push(`quantity = $${idx++}`); values.push(data.quantity); }
    if (data.unit) { fields.push(`unit = $${idx++}`); values.push(data.unit); }
    if (data.storageType) { fields.push(`storage_type = $${idx++}`); values.push(data.storageType); }
    if (data.expirationDate) { fields.push(`expire_at = $${idx++}`); values.push(new Date(data.expirationDate)); }
    if (data.createdAt) { fields.push(`created_at = $${idx++}`); values.push(new Date(data.createdAt)); }

    if (fields.length === 0) return null;

    values.push(id);
    const sql = `
      UPDATE ingredients 
      SET ${fields.join(', ')}, updated_at = NOW()
      WHERE id = $${idx} AND deleted_at IS NULL
      RETURNING *
    `;
    
    const res = await query(sql, values);
    return toResponse(res.rows[0]);
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
