const express = require('express');
const router = express.Router();
const { db } = require('../firebaseConfig');

// Get all products
router.get('/', async (req, res) => {
    try {
        const snapshot = await db.collection('products').get();
        const products = [];
        snapshot.forEach(doc => {
            products.push({ id: doc.id, ...doc.data() });
        });
        res.status(200).json(products);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// Create a new product
router.post('/', async (req, res) => {
    try {
        const newProduct = req.body;
        const docRef = await db.collection('products').add(newProduct);
        res.status(201).json({ id: docRef.id, ...newProduct });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// Get a product by ID
router.get('/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const doc = await db.collection('products').doc(id).get();
        if (!doc.exists) {
            return res.status(404).json({ message: 'Product not found' });
        }
        res.status(200).json({ id: doc.id, ...doc.data() });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// Update a product by ID
router.put('/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const updatedProduct = req.body;
        await db.collection('products').doc(id).update(updatedProduct);
        res.status(200).json({ id, ...updatedProduct });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// Delete a product by ID
router.delete('/:id', async (req, res) => {
    try {
        const { id } = req.params;
        await db.collection('products').doc(id).delete();
        res.status(200).json({ message: 'Product deleted successfully' });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

module.exports = router;
