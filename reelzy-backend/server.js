const app = require('./app');
const mongoose = require('mongoose');
const { initSocket } = require('./src/socket/socket');

const dotenv = require('dotenv');
dotenv.config();
const { Server } = require('socket.io');

const http = require('http');

const server = http.createServer(app);


const io = new Server(server, {
    cors: {
        origin: '*',
        methods: ['GET', 'POST'],
    }
});


initSocket(io);

const PORT = process.env.PORT || 3000;



const gracefulShutdown = () => {
    console.log('HTTP server closed');
    mongoose.connection.close(false, () => {
        console.log('MongoDB connection closed');
        process.exit(0);
    });
};


async function startServer() {
    try {
         server.listen(PORT, () => {
            console.log(`
 Server running on http://localhost:${PORT}

  `);
        });
        
        global.server = server;
        
    } catch (error) {
        console.error('Failed to start server:', error);
        process.exit(1);
    }
}

startServer();