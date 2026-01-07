import { Router } from 'express';
import { DishController } from './dish.controller';
import { requireAuth } from '../../middlewares/auth.middleware';

const router = Router({ mergeParams: true });

router.use(requireAuth);

router.get('/', DishController.list);
router.post('/', DishController.create);
router.post('/cook-decision', DishController.decide);

export default router;
