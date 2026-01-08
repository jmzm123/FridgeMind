"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const auth_controller_1 = require("./auth.controller");
const router = (0, express_1.Router)();
router.post('/send-code', auth_controller_1.AuthController.sendCode);
router.post('/verify-code', auth_controller_1.AuthController.verifyCode);
exports.default = router;
