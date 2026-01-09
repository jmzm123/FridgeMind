# 冰箱管家服务端 - 宝塔面板 (BT Panel) 部署指南

本指南将帮助你将 FridgeMind 服务端（Node.js + PostgreSQL）部署到宝塔面板。

## 前置要求

在宝塔面板的【软件商店】中安装以下软件：
1. **Nginx** (任意版本，推荐 1.20+)
2. **PostgreSQL管理器** (推荐 12+ 版本)
3. **PM2管理器** (用于运行 Node.js 项目)

---

## 步骤 1：准备数据库

1. 打开宝塔面板 -> **数据库** -> **PostgreSQL**。
2. 点击 **添加数据库**：
   - **数据库名**: `fridgemind`
   - **用户名**: `fridgemind`
   - **密码**: (记下这个密码，稍后要用)
   - **访问权限**: 本地服务器 (127.0.0.1)
3. 提交创建。

---

## 步骤 2：上传代码

### 方法 A：本地打包上传 (推荐新手)
1. 在本地将 `server` 文件夹打包为 `server.zip`。
   - 包含 `src`, `scripts`, `package.json`, `tsconfig.json` 等文件。
   - **不要** 包含 `node_modules` 文件夹 (体积大且需要重新安装)。
2. 打开宝塔面板 -> **文件**。
3. 进入 `/www/wwwroot` 目录。
4. 点击 **上传**，上传 `server.zip` 并解压。
5. 将解压后的文件夹重命名为 `fridgemind-server`。

### 方法 B：使用 Git 拉取 (你使用的方法)
1. 在宝塔面板或终端进入 `/www/wwwroot` 目录。
2. 使用 git clone 拉取你的仓库：
   ```bash
   git clone 你的仓库地址 fridgemind-server
   ```
3. **⚠️ 安全警告**：你提到上传了 `.env` 文件。
   - **风险**：`.env` 包含密钥和数据库密码，通常不应提交到 Git。
   - **操作**：请务必确保你的 Git 仓库是私有的。

---

## 步骤 3：安装依赖与编译

1. 打开宝塔面板 -> **终端** (或 SSH 连接服务器)。
2. 进入项目目录：
   ```bash
   cd /www/wwwroot/fridgemind-server
   ```
3. 安装依赖：
   ```bash
   # 如果国内下载慢，可先设置淘宝源
   npm config set registry https://registry.npmmirror.com
   
   npm install
   ```
4. 编译 TypeScript 代码：
   ```bash
   npm run build
   ```
   *成功后会生成 `dist` 目录。*

5. 初始化数据库表结构：
   ```bash
   # 重要：在运行初始化前，请先完成【步骤 4】修改 .env 文件！
   # 确保 .env 里的数据库密码是宝塔里创建的那个，而不是你本地的。
   
   npm run init-db
   ```
   *看到 "Tables created successfully" 即表示成功。*

   > **常见错误处理**：
   > 如果遇到 `extension "pgcrypto" is not available` 错误，说明服务器缺少 PostgreSQL 的扩展包。请在终端执行以下命令（根据你的 PG 版本，如 pg14）：
   > ```bash
   > # CentOS / Alibaba Cloud Linux
   > yum install postgresql-contrib
   > # 或者指定版本 (例如你安装的是 PG 14)
   > yum install postgresql14-contrib
   > ```
   > 安装完成后再次运行 `npm run init-db`。

---

## 步骤 4：配置环境变量 (关键！)

**注意**：既然你上传了 `.env`，它现在已经在服务器上了。但里面的配置（如 `DB_PASS`）通常是你本地电脑的，**直接运行会报错**。

1. 在宝塔面板 -> **文件** 中找到 `/www/wwwroot/fridgemind-server/.env` 文件。
2. **编辑** 该文件，将数据库信息修改为【步骤 1】中在宝塔创建的信息：

```ini
# 服务端口
PORT=3000

# 数据库配置 (必须修改为宝塔数据库的信息)
DB_HOST=127.0.0.1
DB_PORT=5432
DB_USER=fridgemind
DB_PASS=这里必须改成宝塔生成的随机密码！
DB_NAME=fridgemind

# JWT 密钥
JWT_SECRET=...
```
3. 保存文件。

---

## 步骤 5：使用 PM2 启动服务

1. 打开宝塔面板 -> **软件商店** -> **PM2管理器**。
2. 点击 **添加项目**：
   - **启动文件**: 选择 `/www/wwwroot/fridgemind-server/dist/server.js` 
     *(注意是 dist 目录下的 server.js)*
   - **运行目录**: `/www/wwwroot/fridgemind-server`
   - **项目名称**: `fridgemind`
3. 点击 **提交**。
4. 在列表中看到项目状态为绿色 (Running) 即表示启动成功。

---

## 步骤 6：配置 Nginx 反向代理 (让外网访问)

为了安全和方便，我们需要通过域名或 80 端口访问，而不是直接暴露 3000 端口。

1. 打开宝塔面板 -> **网站** -> **PHP项目** (或纯静态，反代都一样)。
2. 点击 **添加站点**：
   - **域名**: 填写你的域名 (如 `api.example.com`) 或 服务器IP。
   - **PHP版本**: 纯静态 (不使用 PHP)。
3. 提交后，点击该网站的 **设置**。
4. 在左侧菜单找到 **反向代理** -> **添加反向代理**：
   - **代理名称**: `API`
   - **目标URL**: `http://127.0.0.1:3000`
   - **发送域名**: `$host`
5. 点击 **提交**。

---

## 验证部署

1. 在浏览器或 Postman 中访问：
   `http://你的域名或IP/api/v1/auth/send-code` (POST 请求)
   或
   `http://你的域名或IP/` (如果根路径有页面)

2. 如果能正常返回 JSON 数据，说明部署成功！

---

## iOS 客户端修改

部署完成后，别忘了修改 iOS 项目中的 `NetworkManager.m`：

```objective-c
// 将 localhost 修改为你的服务器地址
static NSString * const kBaseURL = @"http://你的域名或IP/api/v1";
```
