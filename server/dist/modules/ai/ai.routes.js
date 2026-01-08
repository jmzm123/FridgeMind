"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const ai_controller_1 = require("./ai.controller");
const auth_middleware_1 = require("../../middlewares/auth.middleware");
const router = (0, express_1.Router)();
// 这些接口通常需要登录，但也可能开放给未登录用户体验
// 这里我们先加上 authMiddleware 保护
router.post('/identify-ingredients', auth_middleware_1.requireAuth, ai_controller_1.AIController.identifyIngredients);
router.post('/suggest-recipe', auth_middleware_1.requireAuth, ai_controller_1.AIController.suggestRecipe);
exports.default = router;
