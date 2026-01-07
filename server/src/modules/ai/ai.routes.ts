import { Router } from 'express';
import { AIController } from './ai.controller';
import { requireAuth } from '../../middlewares/auth.middleware';

const router = Router();

// 这些接口通常需要登录，但也可能开放给未登录用户体验
// 这里我们先加上 authMiddleware 保护
router.post('/identify-ingredients', requireAuth, AIController.identifyIngredients);
router.post('/suggest-recipe', requireAuth, AIController.suggestRecipe);

export default router;
