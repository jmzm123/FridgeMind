import { Request, Response } from 'express';
import { FamilyService } from './family.service';

export class FamilyController {
  static async create(req: Request, res: Response) {
    try {
      const userId = req.user!.userId;
      const { name } = req.body;
      
      if (!name) return res.status(400).json({ error: 'Family name required' });

      const family = await FamilyService.createFamily(userId, name);
      res.status(201).json(family);
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }

  static async list(req: Request, res: Response) {
    try {
      const userId = req.user!.userId;
      const families = await FamilyService.getMyFamilies(userId);
      res.json(families);
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }
}
