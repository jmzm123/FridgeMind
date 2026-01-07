import { Router } from 'express';
import { IngredientController } from './ingredient.controller';
import { requireAuth } from '../../middlewares/auth.middleware';

const router = Router();

router.use(requireAuth);

// Global routes (e.g. /ingredients/:id)
// 这些路由需要挂载到 /api/v1/ingredients
router.put('/:id', IngredientController.update);
router.delete('/:id', IngredientController.delete);

// Family scoped routes
// 这些通常挂载到 /api/v1/families/:familyId/ingredients
// 但由于 express Router 的挂载机制，我们可以把这部分逻辑放在 family 路由里，或者单独处理。
// 为了简化，我们这里只暴露基于 ID 的操作。
// Family scoped 操作建议在 app.ts 里单独挂载，或者使用 mergeParams。

export default router;

// 另外导出一个用于 Family 嵌套的 Router
export const familyIngredientRouter = Router({ mergeParams: true });
familyIngredientRouter.use(requireAuth);
familyIngredientRouter.get('/', IngredientController.list);
familyIngredientRouter.post('/', IngredientController.create);
