"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.familyIngredientRouter = void 0;
const express_1 = require("express");
const ingredient_controller_1 = require("./ingredient.controller");
const auth_middleware_1 = require("../../middlewares/auth.middleware");
const router = (0, express_1.Router)();
router.use(auth_middleware_1.requireAuth);
// Global routes (e.g. /ingredients/:id)
// 这些路由需要挂载到 /api/v1/ingredients
router.put('/:id', ingredient_controller_1.IngredientController.update);
router.delete('/:id', ingredient_controller_1.IngredientController.delete);
// Family scoped routes
// 这些通常挂载到 /api/v1/families/:familyId/ingredients
// 但由于 express Router 的挂载机制，我们可以把这部分逻辑放在 family 路由里，或者单独处理。
// 为了简化，我们这里只暴露基于 ID 的操作。
// Family scoped 操作建议在 app.ts 里单独挂载，或者使用 mergeParams。
exports.default = router;
// 另外导出一个用于 Family 嵌套的 Router
exports.familyIngredientRouter = (0, express_1.Router)({ mergeParams: true });
exports.familyIngredientRouter.use(auth_middleware_1.requireAuth);
exports.familyIngredientRouter.get('/', ingredient_controller_1.IngredientController.list);
exports.familyIngredientRouter.post('/', ingredient_controller_1.IngredientController.create);
