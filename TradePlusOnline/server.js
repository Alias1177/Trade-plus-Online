const express = require('express');
const cors = require('cors');
const fs = require('fs').promises;
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;
const NODE_ENV = process.env.NODE_ENV || 'development';

// Security and optimization middleware
if (NODE_ENV === 'production') {
    try {
        const helmet = require('helmet');
        const compression = require('compression');
        
        app.use(helmet({
            contentSecurityPolicy: {
                directives: {
                    defaultSrc: ["'self'"],
                    styleSrc: ["'self'", "'unsafe-inline'", "https://cdn.tailwindcss.com", "https://cdnjs.cloudflare.com", "https://fonts.googleapis.com"],
                    scriptSrc: ["'self'", "'unsafe-inline'", "https://cdn.tailwindcss.com"],
                    fontSrc: ["'self'", "https://fonts.gstatic.com", "https://cdnjs.cloudflare.com"],
                    imgSrc: ["'self'", "data:", "https:"],
                    connectSrc: ["'self'"]
                }
            }
        }));
        app.use(compression());
    } catch (error) {
        console.log('Security middleware not available, running without helmet/compression');
    }
}

// Basic middleware
app.use(cors({
    origin: NODE_ENV === 'production' ? ['https://tradeplus.com', 'https://www.tradeplus.com'] : true,
    credentials: true
}));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Static files with caching
app.use(express.static('.', {
    maxAge: NODE_ENV === 'production' ? '1d' : 0,
    etag: true,
    lastModified: true
}));

// Package configurations - обновленные ID
const packages = {
    Id1: {
        name: "Trading Course",
        regularPrice: 47.99,
        earlyBirdPrice: 9.60,
        description: "Complete institutional trading guide"
    },
    Id2: {
        name: "AI Trading Bot",
        regularPrice: 97.99,
        earlyBirdPrice: 19.60,
        description: "24/7 automated trading assistant"
    },
    Id3: {
        name: "Complete Package",
        regularPrice: 145.98,
        earlyBirdPrice: 29.20,
        description: "Course + Bot + Exclusive Bonuses"
    }
};

// Store pre-orders in JSON file (in production, use a proper database)
const PREORDERS_FILE = 'preorders.json';

// Helper function to read pre-orders
async function readPreOrders() {
    try {
        const data = await fs.readFile(PREORDERS_FILE, 'utf8');
        return JSON.parse(data);
    } catch (error) {
        return [];
    }
}

// Helper function to save pre-orders
async function savePreOrders(preorders) {
    await fs.writeFile(PREORDERS_FILE, JSON.stringify(preorders, null, 2));
}

// Validate email format
function isValidEmail(email) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
}

// Validate phone number
function isValidPhone(phone) {
    // Remove all non-digit characters except +
    const cleanPhone = phone.replace(/[^\d+]/g, '');
    // Check if it starts with + and has 7-15 digits
    return /^\+\d{7,15}$/.test(cleanPhone);
}

// Rate limiting (simple implementation)
const rateLimitMap = new Map();
function rateLimit(req, res, next) {
    const ip = req.ip || req.connection.remoteAddress;
    const now = Date.now();
    const windowMs = 15 * 60 * 1000; // 15 minutes
    const maxRequests = 10;

    if (!rateLimitMap.has(ip)) {
        rateLimitMap.set(ip, { count: 1, resetTime: now + windowMs });
        return next();
    }

    const limit = rateLimitMap.get(ip);
    if (now > limit.resetTime) {
        limit.count = 1;
        limit.resetTime = now + windowMs;
        return next();
    }

    if (limit.count >= maxRequests) {
        return res.status(429).json({ error: 'Too many requests, please try again later.' });
    }

    limit.count++;
    next();
}

// API Routes

// Handle pre-order submissions - обновленный формат
app.post('/api/preorder', rateLimit, async (req, res) => {
    try {
        const {
            number,
            email,
            tg_nickname,
            selected_id
        } = req.body;
        
        // Validation - новый формат
        if (!selected_id || !packages[selected_id]) {
            return res.status(400).json({ error: 'Invalid selected_id. Must be: Id1, Id2, or Id3' });
        }
        
        if (!number || typeof number !== 'number' || number.toString().length < 8) {
            return res.status(400).json({ error: 'Valid number is required (minimum 8 digits)' });
        }
        
        if (!email || !isValidEmail(email)) {
            return res.status(400).json({ error: 'Valid email is required' });
        }
        
        // Check if email or number already exists
        const existingOrders = await readPreOrders();
        const emailExists = existingOrders.some(order => order.email.toLowerCase() === email.toLowerCase());
        
        // Проверяем дубликаты номеров
        const numberExists = existingOrders.some(order => {
            // Старый формат: отдельные поля countryCode и phoneNumber
            if (order.countryCode && order.phoneNumber) {
                const oldFullPhone = order.countryCode + order.phoneNumber;
                return oldFullPhone === `+${number}` || oldFullPhone === number.toString();
            }
            // Новый формат: номер в поле number или phoneNumber
            return order.number === number || order.phoneNumber === number.toString() || order.phoneNumber === `+${number}`;
        });
        
        if (emailExists) {
            return res.status(400).json({ error: 'Email already registered for early bird offer' });
        }
        
        if (numberExists) {
            return res.status(400).json({ error: 'Number already registered for early bird offer' });
        }
        
        // Create optimized order data - новый формат
        const orderData = {
            selected_id: selected_id,
            number: number,
            email: email.toLowerCase().trim(),
            tg_nickname: tg_nickname ? tg_nickname.trim() : null,
            timestamp: new Date().toISOString(),
            price: packages[selected_id].earlyBirdPrice,
            ip: req.ip || req.connection.remoteAddress,
            userAgent: req.get('User-Agent') || 'Unknown'
        };
        
        // Save to file
        existingOrders.push(orderData);
        await savePreOrders(existingOrders);
        
        // Return success response
        res.status(200).json({
            success: true,
            message: 'Pre-order confirmed successfully!',
            selected_id: orderData.selected_id,
            package: packages[selected_id].name,
            price: orderData.price
        });
        
        console.log(`✅ New pre-order: ${orderData.selected_id} - ${orderData.number} - ${packages[selected_id].name}`);
        
    } catch (error) {
        console.error('❌ Error processing pre-order:', error);
        res.status(500).json({ error: 'Internal server error. Please try again.' });
    }
});

// Get pre-order statistics - optimized
app.get('/api/stats', async (req, res) => {
    try {
        const orders = await readPreOrders();
        
        const stats = {
            totalOrders: orders.length,
            totalRevenue: orders.reduce((sum, order) => sum + order.price, 0),
            packageBreakdown: {
                Id1: orders.filter(o => o.selected_id === 'Id1' || o.orderId === 'Book').length,
                Id2: orders.filter(o => o.selected_id === 'Id2' || o.orderId === 'AIBOT').length,
                Id3: orders.filter(o => o.selected_id === 'Id3' || o.orderId === 'Combo').length
            },
            recentOrders: orders.slice(-10).reverse().map(order => ({
                selected_id: order.selected_id || order.orderId,
                timestamp: order.timestamp,
                price: order.price
            }))
        };
        
        res.json(stats);
    } catch (error) {
        console.error('❌ Error getting stats:', error);
        res.status(500).json({ error: 'Error retrieving statistics' });
    }
});

// Health check endpoint
app.get('/api/health', (req, res) => {
    res.json({ 
        status: 'OK', 
        timestamp: new Date().toISOString(),
        environment: NODE_ENV,
        uptime: process.uptime()
    });
});

// Serve main pages with proper headers
app.get('/', (req, res) => {
    res.set({
        'Cache-Control': 'public, max-age=300', // 5 minutes
        'X-Content-Type-Options': 'nosniff'
    });
    res.sendFile(path.join(__dirname, 'index.html'));
});

app.get('/pay', (req, res) => {
    res.set({
        'Cache-Control': 'public, max-age=300', // 5 minutes
        'X-Content-Type-Options': 'nosniff'
    });
    res.sendFile(path.join(__dirname, 'pay.html'));
});

// 404 handler
app.use((req, res) => {
    res.status(404).json({ error: 'Page not found' });
});

// Error handling middleware
app.use((err, req, res, next) => {
    console.error('❌ Server error:', err.stack);
    res.status(500).json({ error: 'Something went wrong!' });
});

// Graceful shutdown
process.on('SIGTERM', () => {
    console.log('🛑 SIGTERM received, shutting down gracefully');
    process.exit(0);
});

process.on('SIGINT', () => {
    console.log('🛑 SIGINT received, shutting down gracefully');
    process.exit(0);
});

// Start server
app.listen(PORT, () => {
    console.log(`🚀 Trader Plus Early Bird Server running on port ${PORT}`);
    console.log(`🌐 Environment: ${NODE_ENV}`);
    console.log(`🌐 Visit: http://localhost:${PORT}`);
    console.log(`📡 API endpoint: http://localhost:${PORT}/api/preorder`);
    console.log(`📊 Stats endpoint: http://localhost:${PORT}/api/stats`);
});

module.exports = app; 