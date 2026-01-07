import { Request, Response } from 'express';
import { IngredientService } from './ingredient.service';

export class IngredientController {
  static async list(req: Request, res: Response) {
    try {
      const { familyId } = req.params;
      const ingredients = await IngredientService.listByFamily(familyId);
      res.json(ingredients);
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }

  static async create(req: Request, res: Response) {
    try {
      const { familyId } = req.params;
      const { name, storageType, quantity, unit } = req.body;

      if (!name || !storageType) {
        return res.status(400).json({ error: 'Name and storageType required' });
      }

      const ingredient = await IngredientService.create({
        familyId,
        name,
        storageType,
        quantity: quantity || 1,
        unit: unit || '个'
      });
      res.status(201).json(ingredient);
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }

  static async update(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const updated = await IngredientService.update(id, req.body);
      
      if (!updated) {
        return res.status(404).json({ error: 'Ingredient not found' });
      }
      res.json(updated);
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }

  static async delete(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const success = await IngredientService.delete(id);
      
      if (!success) {
        return res.status(404).json({ error: 'Ingredient not found' });
      }
      res.json({ success: true });
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }
}
