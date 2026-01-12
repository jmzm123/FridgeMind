# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**FridgeMind Server** - A Node.js backend for a smart refrigerator management system (冰箱管家). This is a family-oriented fridge inventory app that uses AI for ingredient recognition and recipe suggestions.

**Key Technologies:**
- TypeScript + Express.js backend
- PostgreSQL database (with pgcrypto for UUID generation)
- OpenAI-compatible API (using DashScope/Aliyun for AI features)
- JWT authentication
- Zod for validation (installed but usage patterns vary)

## Common Development Commands

```bash
# Development (with hot reload)
npm run dev

# Build TypeScript
npm run build

# Start production server
npm run start

# Initialize database schema
npm run init-db

# Run tests (not configured - shows error message)
npm run test
```

## Architecture & Code Structure

### Entry Points
- `src/server.ts` - Main entry point. **Critical**: Loads `.env` BEFORE importing `app.ts` to ensure environment variables are available during module initialization
- `src/app.ts` - Express app configuration, middleware setup, and route registration

### Database Layer
- `src/config/database.ts` - PostgreSQL connection pool with `query()` and `getClient()` helpers
- `scripts/init-db.ts` - Database schema initialization script (run via `npm run init-db`)

**Database Schema (8 tables):**
1. `users` - User accounts (email-based, no passwords - magic link auth)
2. `families` - Family groups (owner-based)
3. `family_members` - Many-to-many relationship between users and families
4. `ingredients` - Fridge inventory with storage types (frozen/chilled/room), quantities, expiration dates
5. `dishes` - Recipes (both user-created and built-in), stored as JSONB for ingredients/steps
6. `login_codes` - Temporary email verification codes (5-min expiry)
7. `family_invites` - Invite codes for family joining
8. `family_invites` - Family invitation system

### Module Structure (Feature-based)

Each module follows a pattern: `routes.ts` → `controller.ts` → `service.ts`

```
src/modules/
├── auth/          # Authentication (magic link via email)
│   ├── auth.routes.ts     # /api/v1/auth/send-code, /verify-code
│   ├── auth.controller.ts
│   └── auth.service.ts
├── family/        # Family management
│   ├── family.routes.ts   # /api/v1/families (create, list)
│   ├── family.controller.ts
│   └── family.service.ts
├── ingredient/    # Fridge inventory
│   ├── ingredient.routes.ts
│   ├── ingredient.controller.ts
│   └── ingredient.service.ts
├── dish/          # Recipes/Meal planning
│   ├── dish.routes.ts     # /api/v1/families/:familyId/dishes
│   ├── dish.controller.ts
│   └── dish.service.ts
└── ai/            # AI features
    ├── ai.routes.ts       # /api/v1/ai/identify-ingredients, /suggest-recipe
    ├── ai.controller.ts
    └── ai.service.ts      # DashScope integration (Qwen models)
```

### Authentication Flow
1. User submits email to `/auth/send-code`
2. Code stored in `login_codes` table (expires in 5 min)
3. User submits code to `/auth/verify-code`
4. Server verifies code, creates/updates user, returns JWT
5. JWT is `Bearer` token for all protected routes

**JWT Payload:** `{ userId, email }`
**Token expiry:** 7 days

### AI Service (ai.service.ts)
**Critical Note:** Uses lazy initialization - client is created on first use, not at startup. This prevents startup failures if API key is missing.

**Features:**
- `identifyIngredients(imageUrl)` - Uses `qwen-vl-plus` model to analyze images
  - Returns: `[{ name, quantity, unit, storageType }]`
  - Accepts: Image URL or Base64 Data URI
- `suggestRecipe(ingredients, cookingMethod)` - Uses `qwen-plus` model
  - Returns: `{ name, description, cookingMethod, ingredients[], steps[], missingIngredients[] }`

**Configuration:**
- API Key: `DASHSCOPE_API_KEY` (Aliyun DashScope)
- Base URL: `https://dashscope.aliyuncs.com/compatible-mode/v1`

### Route Structure & Middleware

**Global Middleware (app.ts):**
- `helmet()` - Security headers
- `cors()` - Cross-origin requests
- `morgan('dev')` - Request logging
- `express.json({ limit: '50mb' })` - Body parsing (increased for image uploads)

**Authentication Middleware (`src/middlewares/auth.middleware.ts`):**
- `requireAuth` - Validates JWT from `Authorization: Bearer <token>` header
- Attaches `{ userId, email }` to `req.user`

**Route Registration (app.ts):**
```
GET  /health                                    # Health check
POST /api/v1/auth/send-code                     # Send login code
POST /api/v1/auth/verify-code                   # Verify & login

POST /api/v1/families                           # Create family (auth)
GET  /api/v1/families                           # List user's families (auth)

GET  /api/v1/families/:familyId/ingredients     # List ingredients (auth)
POST /api/v1/families/:familyId/ingredients     # Create ingredient (auth)
PUT  /api/v1/ingredients/:id                    # Update ingredient (auth)
DELETE /api/v1/ingredients/:id                  # Delete ingredient (auth)

GET  /api/v1/families/:familyId/dishes          # List dishes (auth)
GET  /api/v1/families/:familyId/dishes/:id      # Get dish (auth)
POST /api/v1/families/:familyId/dishes          # Create dish (auth)
PUT  /api/v1/families/:familyId/dishes/:id      # Update dish (auth)
DELETE /api/v1/families/:familyId/dishes/:id    # Delete dish (auth)
POST /api/v1/families/:familyId/dishes/cook-decision  # AI cook decision (auth)

POST /api/v1/ai/identify-ingredients            # AI image analysis (auth)
POST /api/v1/ai/suggest-recipe                  # AI recipe suggestion (auth)
```

### Environment Variables (.env file)

**Required:**
```ini
PORT=3000
DB_HOST=127.0.0.1
DB_PORT=5432
DB_USER=fridgemind
DB_PASS=<database_password>
DB_NAME=fridgemind
JWT_SECRET=<random_long_string>
DASHSCOPE_API_KEY=<aliyun_api_key>
```

**Important Notes:**
- `.env` is in `.gitignore` - never commit it
- `server.ts` loads `.env` from `__dirname/../.env` (relative to compiled `dist/` directory)
- If `.env` not found, falls back to `dotenv.config()` (current working directory)

### TypeScript Configuration
- Target: ES2020
- Module: CommonJS
- Output: `dist/` directory
- Strict mode enabled
- `skipLibCheck` enabled

## Deployment

### Local Development with Docker
```bash
docker-compose up -d  # Start PostgreSQL
npm install
npm run init-db
npm run dev
```

### Production (宝塔面板)
See `DEPLOY_BT_PANEL.md` for detailed deployment guide.

**Key steps:**
1. Create PostgreSQL database in宝塔面板
2. Upload code (without node_modules)
3. `npm install && npm run build`
4. Update `.env` with production database credentials
5. `npm run init-db`
6. Use PM2 to run `dist/server.js`
7. Configure Nginx reverse proxy to port 3000

## Testing Scripts

Available in `scripts/` directory:
- `test-ai.ts` - Integration test for AI endpoints (requires running server)
- `test-flow.ts` - Full flow test (auth → family → ingredients → dishes)
- `migrate_add_recipe_fields.ts` - Database migration helper

Run with: `npx ts-node scripts/test-ai.ts`

## Important Implementation Details

### 1. Environment Loading Order
`server.ts` loads `.env` BEFORE importing `app.ts`. This is critical because:
- Database config imports happen at module level
- AI service uses lazy initialization but still needs env vars
- Prevents "undefined" errors during startup

### 2. AI Service Lazy Initialization
The `AIService` class only creates the OpenAI client when first called:
```typescript
private static get client(): OpenAI {
  if (!this._client) {
    this._client = new OpenAI({ apiKey: process.env.DASHSCOPE_API_KEY, ... });
  }
  return this._client;
}
```
This allows the server to start even if the API key is missing.

### 3. Family-Scoped Routes
Ingredients and dishes are scoped to families via URL pattern:
- `/api/v1/families/:familyId/ingredients`
- `/api/v1/families/:familyId/dishes`

The `mergeParams: true` option in Express Router preserves `:familyId` from parent route.

### 4. Soft Deletes
Ingredients table has `deleted_at` column for soft deletion pattern.

### 5. JSONB Storage
Dishes store ingredients and steps as JSONB arrays in PostgreSQL for flexibility.

## Common Tasks

### Adding a New Module
1. Create directory in `src/modules/`
2. Create `routes.ts`, `controller.ts`, `service.ts`
3. Import and register in `app.ts`
4. Add any required tables to `scripts/init-db.ts`

### Modifying Database Schema
1. Update `scripts/init-db.ts`
2. Run `npm run init-db` (note: this may fail if tables exist - you may need manual migration)

### Debugging AI Issues
1. Check `DASHSCOPE_API_KEY` in `.env`
2. Verify API key has access to `qwen-vl-plus` and `qwen-plus` models
3. Check `ai.service.ts` console.error logs
4. Test with `scripts/test-ai.ts`

### Fixing Startup Errors
If server fails to start:
1. Verify `.env` exists in project root (or `dist/../.env`)
2. Check all required env vars are set
3. Ensure database is running and accessible
4. Check `server.ts` logs for "Loading .env from:" message

## Security Considerations

- All authenticated routes use `requireAuth` middleware
- JWT secrets should be strong and unique per environment
- Database passwords in `.env` (never commit)
- API keys in `.env` (never commit)
- Helmet.js provides security headers
- CORS is enabled (configure origins in production)
- Body parser limits set to 50MB for image uploads

## Related Files
- `DEPLOY_BT_PANEL.md` - Production deployment guide
- `package.json` - Dependencies and scripts
- `tsconfig.json` - TypeScript configuration
- `docker-compose.yml` - Local PostgreSQL setup
