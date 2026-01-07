# 服务端项目结构设计（Node.js + TypeScript · MVP v1.0）

> 目标：
> - 一个人可长期维护
> - 支撑家庭共享、库存、AI
> - 不做过度工程化

---

## 一、总体原则

- **单体应用（Monolith）**
- 按“业务域”分模块，而不是按技术分层
- API、业务逻辑、数据访问分离
- AI 作为独立模块，便于替换

---

## 二、目录结构（推荐）

```
server/
├── src/
│   ├── app.ts              # 应用入口
│   ├── server.ts           # HTTP Server 启动
│   │
│   ├── config/             # 配置
│   │   ├── env.ts
│   │   └── database.ts
│   │
│   ├── modules/            # 业务模块（核心）
│   │   ├── auth/
│   │   │   ├── auth.controller.ts
│   │   │   ├── auth.service.ts
│   │   │   └── auth.routes.ts
│   │   │
│   │   ├── user/
│   │   │   ├── user.service.ts
│   │   │   └── user.routes.ts
│   │   │
│   │   ├── family/
│   │   │   ├── family.controller.ts
│   │   │   ├── family.service.ts
│   │   │   └── family.routes.ts
│   │   │
│   │   ├── ingredient/
│   │   │   ├── ingredient.controller.ts
│   │   │   ├── ingredient.service.ts
│   │   │   └── ingredient.routes.ts
│   │   │
│   │   ├── dish/
│   │   │   ├── dish.controller.ts
│   │   │   ├── dish.service.ts
│   │   │   └── dish.routes.ts
│   │   │
│   │   └── ai/
│   │       ├── ai.service.ts
│   │       └── ai.routes.ts
│   │
│   ├── middlewares/
│   │   ├── auth.middleware.ts
│   │   └── error.middleware.ts
│   │
│   ├── utils/
│   │   ├── jwt.ts
│   │   ├── time.ts
│   │   └── validator.ts
│   │
│   └── types/
│       └── express.d.ts
│
├── prisma/                 # ORM（可选，推荐）
│   └── schema.prisma
│
├── package.json
├── tsconfig.json
└── README.md
```

---

## 三、核心文件职责说明

### 1️⃣ app.ts

- 创建 Express App
- 注册中间件
- 挂载所有模块 routes

职责非常单一，不写业务逻辑。

---

### 2️⃣ modules/*（最重要）

每个模块结构统一：

```
module/
├── *.routes.ts      # 路由定义
├── *.controller.ts  # 请求/响应处理
└── *.service.ts     # 业务逻辑
```

**设计原则**：
- Controller 不写业务规则
- Service 不关心 HTTP

---

### 3️⃣ middlewares

- auth.middleware.ts
  - 解析 JWT
  - 挂 userId 到 req

- error.middleware.ts
  - 统一错误返回格式

---

### 4️⃣ ai 模块（独立非常重要）

职责：
- 调用外部 AI API
- 统一 prompt / 参数
- 返回结构化结果

以后可：
- 换模型
- 加缓存
- 灰度

不影响业务模块。

---

## 四、请求流示例（新增食材）

```
HTTP Request
  ↓
IngredientRoutes
  ↓
IngredientController
  ↓
IngredientService
  ↓
Database
```

AI 不参与的请求，不经过 ai 模块。

---

## 五、推荐基础依赖

```json
{
  "express": "^4",
  "jsonwebtoken": "^9",
  "pg": "^8",
  "zod": "^3",
  "dotenv": "^16"
}
```

ORM 推荐：
- Prisma（开发效率最高）
- 或 TypeORM

---

## 六、MVP 开发顺序（按模块）

1. auth
2. family
3. ingredient
4. dish
5. ai（最后）

---

## 七、为什么这个结构适合你

- 模块清晰，不会失控
- 未来加平台只写新 client
- AI 和业务彻底解耦
- 一个人也能跑很久

---

> 这个结构可以直接 `mkdir` 开始写代码，
> 不需要重构即可支撑产品早期到中期发展。

