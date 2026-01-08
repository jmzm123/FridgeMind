
import pool from '../src/config/database';

const migrate = async () => {
  try {
    console.log('Connecting to database...');
    const client = await pool.connect();
    console.log('Connected. Running migration...');

    const sql = `
      ALTER TABLE dishes ADD COLUMN IF NOT EXISTS description TEXT;
      ALTER TABLE dishes ADD COLUMN IF NOT EXISTS steps JSONB DEFAULT '[]';
      ALTER TABLE dishes ADD COLUMN IF NOT EXISTS cooking_method TEXT;
    `;

    await client.query(sql);
    
    console.log('Migration completed successfully.');
    client.release();
  } catch (err) {
    console.error('Error running migration:', err);
  } finally {
    await pool.end();
  }
};

migrate();
