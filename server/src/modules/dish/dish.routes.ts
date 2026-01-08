import { Router } from 'express';
import { DishController } from './dish.controller';
import { requireAuth } from '../../middlewares/auth.middleware';

const router = Router({ mergeParams: true });

router.use(requireAuth);

router.get('/', DishController.list);
router.get('/:id', DishController.get);
router.post('/', DishController.create);
router.put('/:id', DishController.update);
router.delete('/:id', DishController.delete);
router.post('/cook-decision', DishController.decide);

export default router;
