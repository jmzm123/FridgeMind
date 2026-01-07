import axios from 'axios';

const API_URL = 'http://localhost:3000/api/v1';
const TEST_EMAIL = 'test_user@example.com';
const TEST_CODE = '123456';

// 使用阿里云官方文档的示例图片 (确保阿里云服务器能访问)
const TEST_IMAGE_URL = 'https://help-static-aliyun-doc.aliyuncs.com/file-manage-files/zh-CN/20241022/emyrja/dog_and_girl.jpeg';

async function runAITest() {
  try {
    console.log('🤖 Starting AI Integration Test...\n');

    // 1. Login
    console.log('1. [Auth] Sending code & Logging in...');
    // 先发送验证码
    await axios.post(`${API_URL}/auth/send-code`, { email: TEST_EMAIL });
    // 再验证登录
    const loginRes = await axios.post(`${API_URL}/auth/verify-code`, {
      email: TEST_EMAIL,
      code: TEST_CODE
    });
    const { token } = loginRes.data;
    console.log('   ✅ Logged in');

    const authClient = axios.create({
      baseURL: API_URL,
      headers: { Authorization: `Bearer ${token}` }
    });

    // 2. Identify Ingredients
    console.log('\n2. [AI] Identifying Ingredients from image...');
    console.log(`   Image: ${TEST_IMAGE_URL}`);
    const identifyRes = await authClient.post('/ai/identify-ingredients', {
      imageUrl: TEST_IMAGE_URL
    });
    console.log('   ✅ Response:', JSON.stringify(identifyRes.data, null, 2));

    // 3. Suggest Recipe
    console.log('\n3. [AI] Suggesting Recipe...');
    const ingredients = ['Tomato', 'Egg', 'Green Onion'];
    console.log(`   Ingredients: ${ingredients.join(', ')}`);
    const recipeRes = await authClient.post('/ai/suggest-recipe', {
      ingredients
    });
    console.log('   ✅ Response:', JSON.stringify(recipeRes.data, null, 2));

  } catch (error: any) {
    console.error('❌ Test Failed:', error.response?.data || error.message);
  }
}

runAITest();
