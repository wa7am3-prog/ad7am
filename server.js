const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

const server = http.createServer(app);
const io = new Server(server, { cors: { origin: '*' } });

// بيانات مؤقتة في الذاكرة (Memory DB)
let posts = [
  {
    id: '1',
    userName: 'أحمد',
    userImage: 'https://via.placeholder.com/150',
    postUrl: 'https://via.placeholder.com/500',
    caption: 'أول منشور في التطبيق!',
    likes: 12,
    createdAt: new Date().toISOString()
  }
];

let memories = [
  {
    id: '101',
    postUrl: 'https://via.placeholder.com/500',
    caption: 'ذكرى من العام الماضي',
    date: '2025-10-12'
  }
];

// --- REST APIs --- //

// 1. جلب المنشورات
app.get('/api/posts', (req, res) => {
  res.json(posts);
});

// 2. إضافة منشور جديد
app.post('/api/posts', (req, res) => {
  const { userName, userImage, postUrl, caption } = req.body;
  const newPost = {
    id: Date.now().toString(),
    userName,
    userImage: userImage || 'https://via.placeholder.com/150',
    postUrl,
    caption,
    likes: 0,
    createdAt: new Date().toISOString()
  };
  posts.unshift(newPost);
  res.status(201).json(newPost);
});

// 3. جلب الذكريات
app.get('/api/memories', (req, res) => {
  res.json(memories);
});

// --- Socket.IO للدردشة المباشرة --- //
io.on('connection', (socket) => {
  console.log('مستخدم متصل:', socket.id);

  socket.on('join_chat', (chatId) => {
    socket.join(chatId);
  });

  socket.on('send_message', (data) => {
    // data: { chatId, senderId, text }
    io.to(data.chatId).emit('receive_message', data);
  });

  socket.on('disconnect', () => {
    console.log('انقطع الاتصال');
  });
});

const PORT = 3000;
server.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});
