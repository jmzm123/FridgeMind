import { Router } from 'express';
import { AuthController } from './auth.controller';

const router = Router();

router.post('/send-code', AuthController.sendCode);
router.post('/verify-code', AuthController.verifyCode);

export default router;
