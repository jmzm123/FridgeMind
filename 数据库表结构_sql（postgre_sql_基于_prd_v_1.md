# 数据库表结构 SQL（PostgreSQL · MVP v1.0）

> 设计目标：
> - 支撑家庭共享冰箱数据
> - 结构清晰、可扩展
> - 个人开发者可长期维护

统一约定：
- 主键：`id` 使用 `UUID`
- 时间字段：`TIMESTAMPTZ`
- 删除策略：**软删除 + 物理删除结合**（MVP 可直接物理删除）

---

## 1. 用户表（users）

```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT NOT NULL UNIQUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

---

## 2. 家庭表（families）

```sql
CREATE TABLE families (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  owner_user_id UUID NOT NULL REFERENCES users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_families_owner ON families(owner_user_id);
```

---

## 3. 家庭成员关系表（family_members）

```sql
CREATE TABLE family_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role TEXT NOT NULL DEFAULT 'member', -- owner / member
  joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (family_id, user_id)
);

CREATE INDEX idx_family_members_family ON family_members(family_id);
```

---

## 4. 食材表（ingredients）

```sql
CREATE TABLE ingredients (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  storage_type TEXT NOT NULL CHECK (storage_type IN ('frozen', 'chilled', 'room')),
  quantity INTEGER DEFAULT 1,
  unit TEXT DEFAULT '个',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expire_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ -- Soft delete
);

CREATE INDEX idx_ingredients_family ON ingredients(family_id);
CREATE INDEX idx_ingredients_expire ON ingredients(expire_at);
CREATE INDEX idx_ingredients_deleted ON ingredients(deleted_at);
```

---

## 5. 菜品表（dishes）

```sql
CREATE TABLE dishes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  ingredients JSONB NOT NULL DEFAULT '[]', -- [{ "name": "排骨", "amount": 1, "unit": "斤" }]
  is_builtin BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_dishes_family ON dishes(family_id);
```

---

## 6. 菜品-食材关联表（已废弃）

> v2.0 变更：使用 dishes.ingredients (JSONB) 存储，简化模型。

---

## 7. 登录验证码表（login_codes）

```sql
CREATE TABLE login_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT NOT NULL,
  code TEXT NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_login_codes_email ON login_codes(email);
```

---

## 8. 邀请码表（family_invites）

```sql
CREATE TABLE family_invites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,
  invite_code TEXT NOT NULL UNIQUE,
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_family_invites_family ON family_invites(family_id);
```

---

## 9. 设计说明（关键决策）

### 9.1 为什么 Ingredient 直接挂 family_id
- 冰箱是家庭级资产
- 减少中间表
- 查询效率高

### 9.2 为什么 dishes.ingredients 使用 JSONB
- 食材是“动态库存”
- 菜品只描述“需要什么”
- JSON 结构灵活，支持单位和数量描述
- 降低删除 / 修改的耦合风险

### 9.3 冲突策略支持
- 最后写入 wins（updated_at）
- 删除为最终状态

---

## 10. 后续可扩展字段（v2+）

- ingredients.source（超市 / 手动 / AI）
- ingredients.image_url
- dishes.category
- 操作日志（audit_logs）

---

> 本 SQL 结构可直接用于生产环境 MVP，
> 不需要重构即可支撑多平台与 AI 能力扩展。

