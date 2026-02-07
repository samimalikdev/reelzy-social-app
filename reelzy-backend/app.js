require('dotenv').config();
const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const routes = require('./src/routes/router')
const { connectDB } = require('./src/config/database');

const app = express();

app.use(helmet());
app.use(cors()); 
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

const requiredEnvVars = [  
    'AWS_ACCESS_KEY_ID',
    'AWS_SECRET_ACCESS_KEY',
    'AWS_REGION',
    'AWS_S3_BUCKET',
    'MONGODB_URI'
];

for (const envVar of requiredEnvVars) {
    if (!process.env[envVar]) {
        console.error(`Error env not set ${envVar}`);
        process.exit();
    }
}


connectDB();

console.log(routes.stack.map(r => r.route?.path))
app.use('/', routes);

app.get('/health', (req, res) => {
    res.status(200).json({
        success: true,
        message: 'Server is running',
        timestamp: new Date().toISOString(),
    });
});

module.exports = app;