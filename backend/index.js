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
const outletsRouter = require('./routes/outlets');

app.use('/api/categories', categoriesRouter);
app.use('/api/products', productsRouter);
app.use('/api/customers', customersRouter);
app.use('/api/outlets', outletsRouter);

app.listen(port, () => {
  console.log(`Server is running on port ${port}`);
});

module.exports = app;
