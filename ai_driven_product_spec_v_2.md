# AI‑Driven Product Spec v2.0

> 目标读者：AI 自动开发工具 / LLM 编程助手
>
> 强约束：
> - 后端：Node.js + TypeScript + PostgreSQL + REST
> - 客户端：iOS Objective‑C
> - AI：仅服务端调用，不可直连数据库
>
> 本文档为**确定性规格**，不允许自由发挥。

---

## 0. 总体原则（必须遵守）

1. 后端是**唯一真实数据源（SSOT）**
2. 客户端不计算业务规则
3. AI 不直接写数据库
4. 所有状态变化必须可追溯
5. 所有失败路径必须有返回结果

---

## 1. 领域模型（Domain Model）

### 1.1 User

```
Entity: User
Fields:
  - id: UUID (PK)
  - email: string (unique)
  - created_at: timestamp
```

Rules:
- User 不拥有库存
- User 通过 Family 访问数据

---

### 1.2 Family

```
Entity: Family
Fields:
  - id: UUID (PK)
  - name: string
  - owner_user_id: UUID
  - created_at: timestamp
```

Rules:
- 一个 User 可属于多个 Family
- 所有库存、菜品、AI 结果必须绑定 family_id

---

### 1.3 Ingredient（核心实体）

```
Entity: Ingredient
Fields:
  - id: UUID (PK)
  - family_id: UUID (FK)
  - name: string
  - quantity: number
  - unit: string
  - storage_type: enum { frozen, chilled, room }
  - expire_at: date
  - created_at: timestamp
  - updated_at: timestamp
  - deleted_at: timestamp | null
```

#### 状态机（强约束）

```
States (implicit via storage_type):
  - frozen
  - chilled
  - room

Transitions:
  - frozen -> chilled (manual only)
  - chilled -> consumed (quantity = 0)

Rules:
  - expire_at MUST be recalculated on storage_type change
  - quantity = 0 → auto set deleted_at
  - soft delete only
```

---

### 1.4 Dish（菜品）

```
Entity: Dish
Fields:
  - id: UUID
  - family_id: UUID
  - name: string
  - ingredients: JSON[] { name, amount, unit }
  - created_at
```

Rules:
- Dish 不绑定具体 Ingredient ID
- 匹配逻辑由服务端计算

---

## 2. 核心功能规格（Input → Process → Output）

### 2.1 手动新增食材

Input:
```
POST /ingredients
{
  name,
  quantity,
  unit,
  storage_type,
  expire_at?
}
```

Process:
- 如果 expire_at 缺失：
  - 根据 storage_type + name 查默认规则
- 校验 quantity > 0

Output:
```
201 Created
Ingredient
```

---

### 2.2 拍照批量入库（AI）

Input:
```
POST /ai/ingredients/recognize
images[] (1..10)
```

Process:
1. AI 识别物品列表
2. confidence < 0.6 → 标记为 unconfirmed
3. 不写数据库

Output:
```
{
  drafts: [{ name, quantity?, unit?, confidence }]
}
```

Failure:
- timeout > 5s → return empty drafts + retry=true

---

### 2.3 菜品推荐（基于库存）

Input:
```
POST /ai/dishes/recommend
{
  preferred_dish_ids[]?
}
```

Process:
- 优先使用临期食材
- 缺失食材 < 2 → 可推荐

Output:
```
{
  dishes: [{ dish_id, missing_ingredients[] }]
}
```

---

## 3. 冲突与并发规则（必须实现）

- 更新 vs 删除：删除优先
- 离线更新：以 updated_at 较新者为准
- 不支持同一 Ingredient 并发编辑

---

## 4. 前后端 / AI 职责边界

### Frontend MUST
- 不计算 expire_at
- 不直接调用 AI

### Backend MUST
- 统一业务规则
- 校验所有输入

### AI MUST NOT
- 写数据库
- 返回未结构化数据

---

## 5. 错误码（固定）

```
400 INVALID_INPUT
401 UNAUTHORIZED
403 FORBIDDEN
404 NOT_FOUND
409 CONFLICT
500 INTERNAL_ERROR
```

---

## 6. 非目标（明确不做）

- 不做营养分析
- 不做购物平台对接
- 不做实时协同编辑

---

## 7. 验收标准（AI 生成代码必须满足）

- 所有接口可 Postman 调用
- 任一失败路径有 JSON 返回
- 状态机规则不可绕过

---

> 本文档即为 **AI 的唯一真实需求来源**。
> 若实现与本文档冲突，以本文档为准。

