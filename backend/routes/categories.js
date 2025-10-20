const express = require('express');
const router = express.Router();
const { db } = require('../firebaseConfig');
const authenticate = require('../middleware/authenticate');

// Get all categories for a specific outlet
router.get('/', authenticate, async (req, res) => {
    try {
        const { outletId } = req.query;
        if (!outletId) {
            return res.status(400).json({ message: 'outletId is required' });
        }

        const snapshot = await db.collection('categories').where('outletIds', 'array-contains', outletId).get();
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
router.post('/', authenticate, async (req, res) => {
    try {
        const newCategory = req.body;
        const docRef = await db.collection('categories').add(newCategory);
        res.status(201).json({ id: docRef.id, ...newCategory });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// Get a category by ID
router.get('/:id', authenticate, async (req, res) => {
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
router.put('/:id', authenticate, async (req, res) => {
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
router.delete('/:id', authenticate, async (req, res) => {
    try {
        const { id } = req.params;
        await db.collection('categories').doc(id).delete();
        res.status(200).json({ message: 'Category deleted successfully' });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

module.exports = router;
