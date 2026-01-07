import { Request, Response } from 'express';
import { AuthService } from './auth.service';

export class AuthController {
  static async sendCode(req: Request, res: Response) {
    try {
      const { email } = req.body;
      if (!email) return res.status(400).json({ error: 'Email required' });

      await AuthService.sendCode(email);
      res.json({ success: true, message: 'Code sent (check console for MVP)' });
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }

  static async verifyCode(req: Request, res: Response) {
    try {
      const { email, code } = req.body;
      if (!email || !code) return res.status(400).json({ error: 'Email and code required' });

      const result = await AuthService.verifyCode(email, code);
      res.json(result);
    } catch (err: any) {
      res.status(401).json({ error: err.message });
    }
  }
}
