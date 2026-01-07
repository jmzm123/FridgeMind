import axios from 'axios';

const API_URL = 'http://localhost:3000/api/v1';
const TEST_EMAIL = 'test_user@example.com';
const TEST_CODE = '123456'; // 我们在 Auth Service 中硬编码了 123456 用于测试

async function runTest() {
  try {
    console.log('🚀 Starting Integration Test Flow...\n');

    // 1. Auth: Send Code
    console.log('1. [Auth] Sending verification code...');
    await axios.post(`${API_URL}/auth/send-code`, { email: TEST_EMAIL });
    console.log('   ✅ Code sent');

    // 2. Auth: Verify & Login
    console.log('2. [Auth] Verifying code & Logging in...');
    const loginRes = await axios.post(`${API_URL}/auth/verify-code`, {
      email: TEST_EMAIL,
      code: TEST_CODE
    });
    const { token, user } = loginRes.data;
    console.log(`   ✅ Logged in as ${user.email}`);
    
    // 配置 axios 默认 header
    const authClient = axios.create({
      baseURL: API_URL,
      headers: { Authorization: `Bearer ${token}` }
    });

    // 3. Family: Create
    console.log('3. [Family] Creating a new family...');
    const familyRes = await axios.post('/families', { name: "Test Family" }, {
      baseURL: API_URL,
      headers: { Authorization: `Bearer ${token}` }
    });
    const family = familyRes.data;
    console.log(`   ✅ Family created: "${family.name}" (ID: ${family.id})`);

    // 4. Ingredient: Add Frozen Ribs
    console.log('4. [Ingredient] Adding frozen ingredients...');
    const ingRes = await authClient.post(`/families/${family.id}/ingredients`, {
      name: "Pork Ribs",
      storageType: "frozen",
      quantity: 1,
      unit: "kg"
    });
    console.log(`   ✅ Added: ${ingRes.data.name} (${ingRes.data.storage_type})`);

    // 5. Dish: Create "Sweet & Sour Ribs"
    console.log('5. [Dish] Creating a dish...');
    const dishRes = await authClient.post(`/families/${family.id}/dishes`, {
      name: "Sweet & Sour Ribs",
      ingredients: [{ name: "Pork Ribs", amount: 0.5, unit: "kg" }]
    });
    const dish = dishRes.data;
    console.log(`   ✅ Dish created: "${dish.name}"`);

    // 6. Decision: Check if we can cook
    console.log('6. [Decision] Checking cook decision...');
    const decisionRes = await authClient.post(`/families/${family.id}/dishes/cook-decision`, {
      dishIds: [dish.id]
    });
    
    console.log('\n--- 🥘 Decision Result ---');
    const { available, needPreparation } = decisionRes.data;
    
    if (available.length > 0) {
      console.log('✅ Available to cook immediately:', available.map((d: any) => d.name));
    }
    
    if (needPreparation.length > 0) {
      console.log('⚠️  Need Preparation:', needPreparation.map((d: any) => 
        `${d.name} -> ${d.action} (${d.reason})`
      ));
    }
    console.log('--------------------------\n');

  } catch (error: any) {
    console.error('❌ Test Failed:', error.response?.data || error.message);
  }
}

runTest();
