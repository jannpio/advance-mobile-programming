const User = require('../models/User');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const getUsers = async (req, res) => {
    try {
        const users = await User.find({}, '-password');
        res.json({ users });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

const createUser = async (req, res) => {
    try {
        if (!req.body.password) {
            return res.status(400).json({ message: 'Password is required' });
        }

        const hashedPassword = await bcrypt.hash(req.body.password, 10);

        const user = await User.create({ ...req.body, password: hashedPassword });

        res.status(201).json(user);
    } catch (error) {
        res.status(400).json({ message: error.message });
    }
};

const updateUser = async (req, res) => {
    try {
        if (req.body.password) {
            req.body.password = await bcrypt.hash(req.body.password, 10);
        }

        const user = await User.findByIdAndUpdate(req.params.id, req.body, {new: true });

        res.json(user);
    } catch (error) {
        res.status(400).json({ message: error.message });
    }
};

const deleteUser = async (req, res) => {
    try {
        const user = await User.findById(req.params.id);

        user.isActive = false;
        await user.save();

        res.json({ message: 'User deleted successfully' });
    } catch (error) {
        res.status(400).json({ message: error.message });
    }
};

const loginUser = async (req, res) => {
    try {
        const { email, password } = req.body;
        console.log('HELLOOOOOOOOOOOOOOOOOOOOO' + email + password);

        const user = await User.findOne({ email });
        if (!user) {
            console.log('User not found');
            return res.status(404).json({ message: 'User not found' });
        }

        if (!user.isActive) {
            console.log('Your account is inactive. Please contact support');
            return res.status(403).json({ message: 'Your account is inactive. Please contact support.' });
        }

        const isPasswordValid = await bcrypt.compare(password, user.password);
        if (!isPasswordValid) {
            console.log('Invalid credentials');
            return res.status(401).json({ message: 'Invalid credentials' });
        }

        const token = jwt.sign(
            {id: user._id, email: user.email, type: user.type },
            process.env.JWT_SECRET,
            { expiresIn: '1h' }
        );

        res.json({ 
            message: 'Login successful', 
            token, 
            id: user._id,
            firstName: user.firstName, 
            lastName: user.lastName ,
            age: user.age,
            gender: user.gender,
            contactNumber: user.contactNumber,
            email: user.email,
            username: user.username,
            address: user.address,
            type: user.type, 
        })
    } catch (error) {
        console.log('Error: ' + error);
        res.status(500).json({ message: error.message });
    }
};

const registerUser = async (req, res) => {
    try {
        const { firstName, lastName, age, gender, contactNumber, email, username, password, address } = req.body;

        // Check if user already exists
        const existingUser = await User.findOne({ email });
        if (existingUser) {
            return res.status(400).json({ message: "User already exists" });
        }

        // Hash the password
        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(password, salt);

        // Create new user
        const user = new User({
            firstName,
            lastName,
            age,
            gender,
            contactNumber,
            email,
            username,
            password: hashedPassword,
            address,
        });

        // Save to DB
        await user.save();

        // Generate token 
        const token = jwt.sign(
            { id: user._id, email: user.email, type: user.type },
            process.env.JWT_SECRET,
            { expiresIn: "1h" }
        );

        // Send response
        res.status(201).json({
            message: "Register successful",
            token,
            type: user.type,
            firstName: user.firstName,
            lastName: user.lastName,
            email: user.email,
        });

    } catch (error) {
        console.error("Error: " + error);
        res.status(500).json({ message: error.message });
    }
};

module.exports = { getUsers, createUser, updateUser, deleteUser, loginUser, registerUser };