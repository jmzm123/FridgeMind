import { Router } from 'express';
import { FamilyController } from './family.controller';
import { requireAuth } from '../../middlewares/auth.middleware';

const router = Router();

router.use(requireAuth); // Protect all routes

router.post('/', FamilyController.create);
router.get('/', FamilyController.list);

export default router;
