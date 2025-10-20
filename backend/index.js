const express = require('express');
const cors = require('cors');

const app = express();
const port = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Routes
const categoriesRouter = require('./routes/categories');
const productsRouter = require('./routes/products');
const customersRouter = require('./routes/customers');

app.use('/categories', categoriesRouter);
app.use('/products', productsRouter);
app.use('/customers', customersRouter);

app.listen(port, () => {
  console.log(`Server is running on port ${port}`);
});

module.exports = app;
