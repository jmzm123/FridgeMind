# AI Sync Spec v1.0

> 用途：
> - 作为 **AI 自动生成同步代码的唯一依据**
> - 适用于：iOS 本地存储 ↔ 服务端 PostgreSQL
>
> 目标：
> - 离线可用
> - 不丢数据
> - 不出现“幽灵数据 / 回滚地狱”

---

## 0. 核心前提（强约束）

1. 云端是 **Single Source of Truth**
2. 本地允许短暂不一致
3. 同步必须是 **幂等的**
4. 同步逻辑只能写在 **SyncManager**

---

## 1. 本地数据模型（同步相关字段）

```
Entity: IngredientLocal
Fields (sync-related):
  - local_id: UUID (PK)
  - server_id: UUID | null
  - updated_at: timestamp (local)
  - sync_status: enum { pending, synced, failed }
  - deleted: boolean
```

Rules:
- sync_status 只由 SyncManager 修改
- UI 层不得直接修改 sync_status

---

## 2. 同步触发条件（必须实现）

Trigger Sync when ANY of the following occurs:

- App launch
- App enter foreground
- Network becomes reachable
- There exists any record where sync_status != synced
- User manually pulls to refresh

---

## 3. 同步总流程（强制顺序）

```
SYNC START
  ↓
STEP 1: PUSH LOCAL CHANGES
  ↓
STEP 2: PULL SERVER CHANGES
  ↓
SYNC END
```

❗ 不允许 STEP 2 在 STEP 1 之前执行

---

## 4. STEP 1：本地 → 云端（Push）

### 4.1 选取同步对象

```
SELECT * FROM IngredientLocal
WHERE sync_status IN (pending, failed)
ORDER BY updated_at ASC
```

---

### 4.2 单条记录同步规则

#### Case A：server_id == null AND deleted == false

Action:
```
POST /ingredients
```

On Success:
- save server_id
- overwrite updated_at (from server)
- sync_status = synced

---

#### Case B：server_id != null AND deleted == false

Action:
```
PUT /ingredients/{server_id}
```

On Success:
- overwrite updated_at
- sync_status = synced

---

#### Case C：server_id != null AND deleted == true

Action:
```
DELETE /ingredients/{server_id}
```

On Success:
- remove local record permanently

---

#### Case D：server_id == null AND deleted == true

Action:
- remove local record permanently

---

### 4.3 错误处理

- Network error → keep sync_status
- 4xx error → sync_status = failed
- 5xx error → retry later

---

## 5. STEP 2：云端 → 本地（Pull）

### 5.1 拉取条件

```
GET /ingredients?updated_since=last_success_sync_time
```

---

### 5.2 单条记录合并规则

For each server_record:

```
IF local_record NOT EXISTS:
  INSERT
ELSE IF server.updated_at > local.updated_at:
  OVERWRITE local_record
ELSE:
  IGNORE
```

---

### 5.3 处理云端删除

If server.deleted_at IS NOT NULL:

```
IF local_record EXISTS:
  DELETE local_record permanently
```

---

## 6. 冲突判定规则（不可更改）

| 场景 | 结果 |
|----|----|
| 本地 pending，云端更新 | 云端覆盖本地 |
| 本地更新，云端删除 | 删除 |
| 双方修改 | updated_at 较新者胜 |

---

## 7. 幂等性要求（AI 必须满足）

- 重复执行 PUSH 不得产生重复记录
- 重复执行 PULL 不得覆盖新数据
- 任意时刻中断，同步可恢复

---

## 8. 禁止事项（极其重要）

AI MUST NOT:
- 在 UI 线程执行同步
- 并行同步同一 Entity
- 推测 last_sync_time
- 跳过 deleted 逻辑

---

## 9. 验收标准（代码级）

- 断网新增 → 联网后成功同步
- 同一记录重复同步不重复创建
- 同步过程中 App kill → 重启后可继续

---

> 本文档是 **SyncManager 的唯一实现依据**。
> 若实现行为与本文档冲突，则视为实现错误。

