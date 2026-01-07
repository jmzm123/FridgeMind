# 服务端 REST API 清单（MVP v1.0）

> 本文档用于：
> - 服务端接口设计
> - iOS / 未来多平台对接
> - 前后端并行开发

统一约定：
- Base URL：`/api/v1`
- 鉴权方式：`Authorization: Bearer <token>`
- 数据格式：JSON

---

## 1. 认证与用户（Auth & User）

### 1.1 发送登录验证码

**POST** `/auth/send-code`

请求：
```json
{
  "email": "user@example.com"
}
```

响应：
```json
{ "success": true }
```

---

### 1.2 验证验证码并登录

**POST** `/auth/verify-code`

请求：
```json
{
  "email": "user@example.com",
  "code": "123456"
}
```

响应：
```json
{
  "token": "jwt_token",
  "user": {
    "id": "u_1",
    "email": "user@example.com"
  }
}
```

---

### 1.3 获取当前用户信息

**GET** `/users/me`

响应：
```json
{
  "id": "u_1",
  "email": "user@example.com"
}
```

---

## 2. 家庭（Family）

### 2.1 创建家庭

**POST** `/families`

请求：
```json
{
  "name": "我的家庭"
}
```

响应：
```json
{
  "id": "f_1",
  "name": "我的家庭"
}
```

---

### 2.2 获取我加入的家庭列表

**GET** `/families`

响应：
```json
[
  { "id": "f_1", "name": "我的家庭" }
]
```

---

### 2.3 邀请家庭成员

**POST** `/families/{familyId}/invite`

响应：
```json
{ "inviteCode": "ABC123" }
```

---

### 2.4 通过邀请码加入家庭

**POST** `/families/join`

请求：
```json
{ "inviteCode": "ABC123" }
```

响应：
```json
{ "familyId": "f_1" }
```

---

## 3. 冰箱库存（Ingredient）

### 3.1 获取家庭全部食材

**GET** `/families/{familyId}/ingredients`

响应：
```json
[
  {
    "id": "i_1",
    "name": "排骨",
    "storageType": "frozen",
    "quantity": 1,
    "unit": "斤",
    "createdAt": "2026-01-01",
    "expireAt": "2026-04-01"
  }
]
```

---

### 3.2 新增食材

**POST** `/families/{familyId}/ingredients`

请求：
```json
{
  "name": "排骨",
  "storageType": "frozen",
  "quantity": 1,
  "unit": "斤"
}
```

响应：
```json
{ "id": "i_1" }
```

---

### 3.3 编辑食材

**PUT** `/ingredients/{ingredientId}`

请求：
```json
{
  "storageType": "chilled",
  "quantity": 1
}
```

---

### 3.4 删除 / 标记已用完

**DELETE** `/ingredients/{ingredientId}`

响应：
```json
{ "success": true }
```

---

## 4. 菜品与做饭决策

### 4.1 获取内置 + 用户菜品

**GET** `/families/{familyId}/dishes`

响应：
```json
[
  {
    "id": "d_1",
    "name": "糖醋排骨",
    "ingredients": [
      { "name": "排骨", "amount": 1, "unit": "斤" }
    ]
  }
]
```

---

### 4.2 新增自定义菜品

**POST** `/families/{familyId}/dishes`

请求：
```json
{
  "name": "西兰花炒肉",
  "ingredients": [
    { "name": "西兰花", "amount": 1, "unit": "个" },
    { "name": "猪肉", "amount": 200, "unit": "g" }
  ]
}
```

---

### 4.3 做饭决策推荐

**POST** `/families/{familyId}/cook-decision`

请求：
```json
{
  "dishIds": ["d_1", "d_2"]
}
```

响应：
```json
{
  "available": ["d_2"],
  "needPreparation": [
    {
      "dishId": "d_1",
      "action": "defrost",
      "suggestTime": "14:00"
    }
  ]
}
```

---

## 5. 提醒系统（逻辑接口）

### 5.1 获取提醒列表

**GET** `/families/{familyId}/reminders`

---

## 6. AI 能力接口（服务端封装）

### 6.1 拍照识别食材

**POST** `/ai/recognize-ingredients`

请求：
- multipart/form-data
- image

响应：
```json
{
  "drafts": [
    { "name": "排骨", "quantity": 1, "unit": "斤", "confidence": 0.87 },
    { "name": "西兰花", "quantity": 1, "unit": "个", "confidence": 0.76 }
  ]
}
```

---

### 6.2 食材保质期推断

**POST** `/ai/estimate-expire`

请求：
```json
{
  "name": "排骨",
  "storageType": "frozen"
}
```

响应：
```json
{ "days": 90 }
```

---

## 7. 统一错误格式

```json
{
  "error": {
    "code": "UNAUTHORIZED",
    "message": "Invalid token"
  }
}
```

---

> 本 API 清单为 MVP v1.0，
> 保证：简单、稳定、跨平台可扩展。

