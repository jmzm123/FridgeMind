"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const family_controller_1 = require("./family.controller");
const auth_middleware_1 = require("../../middlewares/auth.middleware");
const router = (0, express_1.Router)();
router.use(auth_middleware_1.requireAuth); // Protect all routes
router.post('/', family_controller_1.FamilyController.create);
router.get('/', family_controller_1.FamilyController.list);
exports.default = router;
