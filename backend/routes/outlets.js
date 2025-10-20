const express = require('express');
const router = express.Router();
const { db } = require('../firebaseConfig');
const authenticate = require('../middleware/authenticate');

router.get('/', authenticate, async (req, res) => {
    try {
        const userId = req.user.uid;
        const outletsRef = db.collection('outlets');
        const snapshot = await outletsRef.where('userId', '==', userId).get();

        if (snapshot.empty) {
            console.log('No outlets found for user:', userId);
            return res.status(200).json([]);
        }

        const outletsList = snapshot.docs.map((doc) => ({
            id: doc.id,
            ...doc.data(),
        }));

        res.status(200).json(outletsList);
    } catch (error) {
        console.error('Error fetching outlets:', error);
        res.status(500).json({ message: 'An internal server error occurred.' });
    }
});

module.exports = router;
