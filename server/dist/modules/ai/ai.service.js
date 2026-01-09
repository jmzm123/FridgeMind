"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AIService = void 0;
const openai_1 = __importDefault(require("openai"));
const dotenv_1 = __importDefault(require("dotenv"));
dotenv_1.default.config();
class AIService {
    static get client() {
        if (!this._client) {
            this._client = new openai_1.default({
                apiKey: process.env.DASHSCOPE_API_KEY,
                baseURL: "https://dashscope.aliyuncs.com/compatible-mode/v1"
            });
        }
        return this._client;
    }
    /**
     * 识别图片中的食材
     * @param imageUrl 图片URL或Base64 Data URI
     * @returns 解析后的食材列表JSON
     */
    static async identifyIngredients(imageUrl) {
        try {
            const response = await this.client.chat.completions.create({
                model: "qwen-vl-plus",
                messages: [
                    {
                        role: "user",
                        content: [
                            {
                                type: "image_url",
                                image_url: {
                                    url: imageUrl
                                }
                            },
                            {
                                type: "text",
                                text: "请识别图中的食材。请只返回一个JSON数组，格式为：[{ \"name\": \"食材名称\", \"quantity\": 数量(数字), \"unit\": \"单位\", \"storageType\": \"chilled\" | \"frozen\" | \"room\" }]. 如果无法确定数量，默认为1。如果无法确定单位，默认为'个'或'份'。请不要返回任何Markdown格式或额外文字，只返回纯JSON字符串。"
                            }
                        ]
                    }
                ]
            });
            const content = response.choices[0].message.content || "[]";
            // 清理可能存在的 markdown 代码块标记
            const jsonStr = content.replace(/```json\n?|\n?```/g, "").trim();
            return JSON.parse(jsonStr);
        }
        catch (error) {
            console.error("AI Identify Error:", error);
            throw new Error(`Failed to identify ingredients: ${error.message}`);
        }
    }
    /**
     * 根据食材建议菜谱
     * @param ingredients 食材名称列表
     * @param cookingMethod 烹饪方式 (可选，默认炒菜)
     */
    static async suggestRecipe(ingredients, cookingMethod = '炒菜') {
        try {
            const response = await this.client.chat.completions.create({
                model: "qwen-plus",
                messages: [
                    {
                        role: "system",
                        content: `你是一个专业的厨师助手。请根据用户提供的食材和烹饪方式，推荐一道最合适的菜谱。
            请只返回一个JSON对象，格式为：
            { 
              "name": "菜名", 
              "description": "简介", 
              "cookingMethod": "烹饪方式",
               "ingredients": [{ "name": "食材名", "quantity": 1, "unit": "个" }],
               "steps": ["步骤1", "步骤2"], 
               "missingIngredients": ["缺失食材1"] 
             }。
             请不要返回任何Markdown格式，只返回纯JSON字符串。`
                    },
                    {
                        role: "user",
                        content: `我有以下食材：${ingredients.join(', ')}。我想做：${cookingMethod}。请推荐一道菜并给出详细教程。请确保ingredients中的quantity是数字，unit是单位字符串。`
                    }
                ]
            });
            const content = response.choices[0].message.content || "{}";
            const jsonStr = content.replace(/```json\n?|\n?```/g, "").trim();
            return JSON.parse(jsonStr);
        }
        catch (error) {
            console.error("AI Recipe Error:", error);
            throw new Error(`Failed to suggest recipe: ${error.message}`);
        }
    }
}
exports.AIService = AIService;
