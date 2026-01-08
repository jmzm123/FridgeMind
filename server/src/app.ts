import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';

const app = express();

// Middlewares
app.use(helmet());
app.use(cors());
app.use(morgan('dev'));
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb', extended: true }));

import authRoutes from './modules/auth/auth.routes';
import familyRoutes from './modules/family/family.routes';
import ingredientRoutes, { familyIngredientRouter } from './modules/ingredient/ingredient.routes';
import dishRoutes from './modules/dish/dish.routes';
import aiRoutes from './modules/ai/ai.routes';

// ...

// Routes
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok', timestamp: new Date().toISOString() });
});

app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/families', familyRoutes);

// Ingredient Routes
app.use('/api/v1/ingredients', ingredientRoutes);
app.use('/api/v1/families/:familyId/ingredients', familyIngredientRouter);

// Dish Routes
app.use('/api/v1/families/:familyId/dishes', dishRoutes);

// AI Routes
app.use('/api/v1/ai', aiRoutes);




export default app;
