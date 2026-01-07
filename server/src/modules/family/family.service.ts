import { query } from '../../config/database';

export class FamilyService {
  static async createFamily(userId: string, name: string) {
    const client = await import('../../config/database').then(m => m.default.connect());
    
    try {
      await client.query('BEGIN');

      // 1. Create Family
      const familyRes = await client.query(
        'INSERT INTO families (name, owner_user_id) VALUES ($1, $2) RETURNING *',
        [name, userId]
      );
      const family = familyRes.rows[0];

      // 2. Add Owner as Member
      await client.query(
        'INSERT INTO family_members (family_id, user_id, role) VALUES ($1, $2, $3)',
        [family.id, userId, 'owner']
      );

      await client.query('COMMIT');
      return family;
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  }

  static async getMyFamilies(userId: string) {
    const sql = `
      SELECT f.*, fm.role 
      FROM families f
      JOIN family_members fm ON f.id = fm.family_id
      WHERE fm.user_id = $1
      ORDER BY f.created_at DESC
    `;
    const res = await query(sql, [userId]);
    return res.rows;
  }
}
