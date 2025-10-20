const express = require('express');
const router = express.Router();
const { db } = require('../firebaseConfig');
const authenticate = require('../middleware/authenticate');

// Get all customers for the authenticated user
router.get('/', authenticate, async (req, res) => {
    try {
        const userId = req.user.uid;
        const snapshot = await db.collection('customers').where('userId', '==', userId).get();
        const customers = [];
        snapshot.forEach(doc => {
            customers.push({ id: doc.id, ...doc.data() });
        });
        res.status(200).json(customers);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// Create a new customer
router.post('/', authenticate, async (req, res) => {
    try {
        const newCustomer = req.body;
        const docRef = await db.collection('customers').add(newCustomer);
        res.status(201).json({ id: docRef.id, ...newCustomer });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// Get a customer by ID
router.get('/:id', authenticate, async (req, res) => {
    try {
        const { id } = req.params;
        const doc = await db.collection('customers').doc(id).get();
        if (!doc.exists) {
            return res.status(404).json({ message: 'Customer not found' });
        }
        res.status(200).json({ id: doc.id, ...doc.data() });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// Update a customer by ID
router.put('/:id', authenticate, async (req, res) => {
    try {
        const { id } = req.params;
        const updatedCustomer = req.body;
        await db.collection('customers').doc(id).update(updatedCustomer);
        res.status(200).json({ id, ...updatedCustomer });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// Delete a customer by ID
router.delete('/:id', authenticate, async (req, res) => {
    try {
        const { id } = req.params;
        await db.collection('customers').doc(id).delete();
        res.status(200).json({ message: 'Customer deleted successfully' });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

module.exports = router;
