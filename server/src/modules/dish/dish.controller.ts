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

  static async get(req: Request, res: Response) {
    try {
      const { familyId, id } = req.params;
      const dish = await DishService.get(id, familyId);
      if (!dish) return res.status(404).json({ error: 'Dish not found' });
      res.json(dish);
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

  static async update(req: Request, res: Response) {
    try {
      const { familyId, id } = req.params;
      const { name, ingredients, steps, description, cookingMethod } = req.body;
      const dish = await DishService.update(id, familyId, { name, ingredients, steps, description, cookingMethod });
      if (!dish) return res.status(404).json({ error: 'Dish not found' });
      res.json(dish);
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }

  static async delete(req: Request, res: Response) {
    try {
      const { familyId, id } = req.params;
      const success = await DishService.delete(id, familyId);
      if (!success) return res.status(404).json({ error: 'Dish not found' });
      res.json({ success: true });
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }
}
