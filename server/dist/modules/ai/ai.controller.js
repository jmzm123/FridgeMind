"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.AIController = void 0;
const ai_service_1 = require("./ai.service");
class AIController {
    static async identifyIngredients(req, res) {
        try {
            const { imageUrl } = req.body;
            if (!imageUrl) {
                return res.status(400).json({ error: 'imageUrl is required' });
            }
            console.log('Received identify request. Image URL length:', imageUrl.length);
            console.log('Image URL prefix:', imageUrl.substring(0, 50));
            const result = await ai_service_1.AIService.identifyIngredients(imageUrl);
            res.json(result);
        }
        catch (error) {
            res.status(500).json({ error: error.message });
        }
    }
    static async suggestRecipe(req, res) {
        try {
            const { ingredients, cookingMethod } = req.body;
            if (!ingredients || !Array.isArray(ingredients) || ingredients.length === 0) {
                return res.status(400).json({ error: 'ingredients array is required' });
            }
            const result = await ai_service_1.AIService.suggestRecipe(ingredients, cookingMethod);
            res.json(result);
        }
        catch (error) {
            res.status(500).json({ error: error.message });
        }
    }
}
exports.AIController = AIController;
