import pool from '../src/config/database';

const createTablesSQL = `
-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 1. Users
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT NOT NULL UNIQUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. Families
CREATE TABLE IF NOT EXISTS families (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  owner_user_id UUID NOT NULL REFERENCES users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_families_owner ON families(owner_user_id);

-- 3. Family Members
CREATE TABLE IF NOT EXISTS family_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role TEXT NOT NULL DEFAULT 'member',
  joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (family_id, user_id)
);
CREATE INDEX IF NOT EXISTS idx_family_members_family ON family_members(family_id);

-- 4. Ingredients
CREATE TABLE IF NOT EXISTS ingredients (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  storage_type TEXT NOT NULL CHECK (storage_type IN ('frozen', 'chilled', 'room')),
  quantity INTEGER DEFAULT 1,
  unit TEXT DEFAULT '个',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expire_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS idx_ingredients_family ON ingredients(family_id);
CREATE INDEX IF NOT EXISTS idx_ingredients_expire ON ingredients(expire_at);
CREATE INDEX IF NOT EXISTS idx_ingredients_deleted ON ingredients(deleted_at);

-- 5. Dishes
CREATE TABLE IF NOT EXISTS dishes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  ingredients JSONB NOT NULL DEFAULT '[]',
  steps JSONB DEFAULT '[]',
  description TEXT,
  cooking_method TEXT,
  is_builtin BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_dishes_family ON dishes(family_id);

-- 7. Login Codes
CREATE TABLE IF NOT EXISTS login_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT NOT NULL,
  code TEXT NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_login_codes_email ON login_codes(email);

-- 8. Family Invites
CREATE TABLE IF NOT EXISTS family_invites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,
  invite_code TEXT NOT NULL UNIQUE,
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_family_invites_family ON family_invites(family_id);
`;

const initDb = async () => {
  try {
    console.log('Connecting to database...');
    const client = await pool.connect();
    console.log('Connected. Creating tables...');
    
    await client.query(createTablesSQL);
    
    console.log('Tables created successfully.');
    client.release();
  } catch (err) {
    console.error('Error initializing database:', err);
  } finally {
    await pool.end();
  }
};

initDb();
