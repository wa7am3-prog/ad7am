import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;

// ⚠️ غير هذا الرابط إلى IP جهازك أو عنوان الخادم عند التجربة على هاتف حقيقي
const String baseUrl = 'http://10.0.2.2:3000'; 

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InstaClone',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(backgroundColor: Colors.black),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

// -------------------------------------------------------------
// الشاشة الرئيسية مع شريط التنقل السفلي
// -------------------------------------------------------------
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    FeedScreen(),
    MemoriesScreen(),
    AddPostScreen(),
    ChatDetailScreen(chatId: 'general_room', receiverName: 'غرفة الدردشة العامّة'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'الرئيسية'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'الذكريات'),
          BottomNavigationBarItem(icon: Icon(Icons.add_box_outlined), label: 'إضافة'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'الدردشة'),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// 1. شاشة المنشورات والقصص (Feed)
// -------------------------------------------------------------
class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  List posts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPosts();
  }

  Future<void> fetchPosts() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/posts'));
      if (res.statusCode == 200) {
        setState(() {
          posts = json.decode(res.body);
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Instagram', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchPosts,
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchPosts,
              child: ListView.builder(
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(post['userImage']),
                        ),
                        title: Text(post['userName'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Image.network(
                        post['postUrl'],
                        height: 300,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(height: 200, color: Colors.grey[800], child: const Icon(Icons.image)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: const [
                            Icon(Icons.favorite_border),
                            SizedBox(width: 16),
                            Icon(Icons.chat_bubble_outline),
                            SizedBox(width: 16),
                            Icon(Icons.send),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Text('${post['likes']} إعجاب', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                        child: Text('${post['userName']}: ${post['caption']}'),
                      ),
                      const SizedBox(height: 15),
                    ],
                  );
                },
              ),
            ),
    );
  }
}

// -------------------------------------------------------------
// 2. شاشة إضافة منشور (Add Post)
// -------------------------------------------------------------
class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final _captionController = TextEditingController();
  final _imageUrlController = TextEditingController();
  bool isUploading = false;

  Future<void> submitPost() async {
    if (_captionController.text.isEmpty || _imageUrlController.text.isEmpty) return;

    setState(() => isUploading = true);

    try {
      await http.post(
        Uri.parse('$baseUrl/api/posts'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userName': 'مستخدم Flutter',
          'postUrl': _imageUrlController.text,
          'caption': _captionController.text,
        }),
      );

      _captionController.clear();
      _imageUrlController.clear();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم نشر المنشور بنجاح!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ أثناء النشر')),
      );
    } finally {
      setState(() => isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إنشاء منشور جديد')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _imageUrlController,
              decoration: const InputDecoration(labelText: 'رابط الصورة (URL)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _captionController,
              decoration: const InputDecoration(labelText: 'الوصف / Caption'),
            ),
            const SizedBox(height: 24),
            isUploading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: submitPost,
                    child: const Text('نشر الان'),
                  ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// 3. شاشة الذكريات (Memories)
// -------------------------------------------------------------
class MemoriesScreen extends StatefulWidget {
  const MemoriesScreen({super.key});

  @override
  State<MemoriesScreen> createState() => _MemoriesScreenState();
}

class _MemoriesScreenState extends State<MemoriesScreen> {
  List memories = [];

  @override
  void initState() {
    super.initState();
    fetchMemories();
  }

  Future<void> fetchMemories() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/memories'));
      if (res.statusCode == 200) {
        setState(() => memories = json.decode(res.body));
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الذكريات')),
      body: memories.isEmpty
          ? const Center(child: Text('لا توجد ذكريات حالياً'))
          : ListView.builder(
              itemCount: memories.length,
              itemBuilder: (context, index) {
                final memory = memories[index];
                return Card(
                  margin: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Image.network(memory['postUrl'], height: 200, width: double.infinity, fit: BoxFit.cover),
                      ListTile(
                        title: Text(memory['caption']),
                        subtitle: Text('التاريخ: ${memory['date']}'),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

// -------------------------------------------------------------
// 4. شاشة الدردشة عبر WebSocket (Socket.IO)
// -------------------------------------------------------------
class ChatDetailScreen extends StatefulWidget {
  final String chatId;
  final String receiverName;

  const ChatDetailScreen({super.key, required this.chatId, required this.receiverName});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  late IO.Socket socket;
  final TextEditingController _msgController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final String myUserId = 'user_123';

  @override
  void initState() {
    super.initState();
    connectSocket();
  }

  void connectSocket() {
    socket = IO.io(baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.connect();

    socket.onConnect((_) {
      socket.emit('join_chat', widget.chatId);
    });

    socket.on('receive_message', (data) {
      if (mounted) {
        setState(() {
          _messages.add(Map<String, dynamic>.from(data));
        });
      }
    });
  }

  void sendMessage() {
    if (_msgController.text.trim().isEmpty) return;

    final messageData = {
      'chatId': widget.chatId,
      'senderId': myUserId,
      'text': _msgController.text.trim(),
    };

    socket.emit('send_message', messageData);
    _msgController.clear();
  }

  @override
  void dispose() {
    socket.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.receiverName)),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isMe = msg['senderId'] == myUserId;
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.blue : Colors.grey[800],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(msg['text'] ?? ''),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.grey[900],
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    decoration: const InputDecoration(
                      hintText: 'اكتب رسالتك...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: sendMessage,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
