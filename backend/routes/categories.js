const express = require('express');
const router = express.Router();
const { db } = require('../firebaseConfig');

// Get all categories
router.get('/', async (req, res) => {
    try {
        const snapshot = await db.collection('categories').get();
        const categories = [];
        snapshot.forEach(doc => {
            categories.push({ id: doc.id, ...doc.data() });
        });
        res.status(200).json(categories);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// Create a new category
router.post('/', async (req, res) => {
    try {
        const newCategory = req.body;
        const docRef = await db.collection('categories').add(newCategory);
        res.status(201).json({ id: docRef.id, ...newCategory });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// Get a category by ID
router.get('/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const doc = await db.collection('categories').doc(id).get();
        if (!doc.exists) {
            return res.status(404).json({ message: 'Category not found' });
        }
        res.status(200).json({ id: doc.id, ...doc.data() });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// Update a category by ID
router.put('/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const updatedCategory = req.body;
        await db.collection('categories').doc(id).update(updatedCategory);
        res.status(200).json({ id, ...updatedCategory });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// Delete a category by ID
router.delete('/:id', async (req, res) => {
    try {
        const { id } = req.params;
        await db.collection('categories').doc(id).delete();
        res.status(200).json({ message: 'Category deleted successfully' });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

module.exports = router;
