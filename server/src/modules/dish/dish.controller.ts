import { Request, Response } from 'express';
import { DishService } from './dish.service';

export class DishController {
  static async list(req: Request, res: Response) {
    try {
      const { familyId } = req.params;
      const dishes = await DishService.listByFamily(familyId);
      res.json(dishes);
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }

  static async create(req: Request, res: Response) {
    try {
      const { familyId } = req.params;
      const { name, ingredients, steps, description, cookingMethod } = req.body;

      if (!name) return res.status(400).json({ error: 'Name required' });

      const dish = await DishService.create(
        familyId, 
        name, 
        ingredients || [], 
        steps || [], 
        description || '', 
        cookingMethod || ''
      );
      res.status(201).json(dish);
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }

  static async decide(req: Request, res: Response) {
    try {
      const { familyId } = req.params;
      const { dishIds } = req.body;

      if (!dishIds || !Array.isArray(dishIds)) {
        return res.status(400).json({ error: 'dishIds array required' });
      }

      const result = await DishService.makeDecision(familyId, dishIds);
      res.json(result);
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }
}
