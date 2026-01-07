import { Request, Response } from 'express';
import { AIService } from './ai.service';

export class AIController {
  
  static async identifyIngredients(req: Request, res: Response) {
    try {
      const { imageUrl } = req.body;
      if (!imageUrl) {
        return res.status(400).json({ error: 'imageUrl is required' });
      }
      
      const result = await AIService.identifyIngredients(imageUrl);
      res.json(result);
    } catch (error: any) {
      res.status(500).json({ error: error.message });
    }
  }

  static async suggestRecipe(req: Request, res: Response) {
    try {
      const { ingredients } = req.body;
      if (!ingredients || !Array.isArray(ingredients) || ingredients.length === 0) {
        return res.status(400).json({ error: 'ingredients array is required' });
      }

      const result = await AIService.suggestRecipe(ingredients);
      res.json(result);
    } catch (error: any) {
      res.status(500).json({ error: error.message });
    }
  }
}
