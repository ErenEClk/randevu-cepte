import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/chat_model.dart';
import '../../services/chat_service.dart';
import '../../services/auth_service.dart';
import 'chat_detail_screen.dart';

class BusinessChatListScreen extends StatefulWidget {
  const BusinessChatListScreen({super.key});

  @override
  State<BusinessChatListScreen> createState() => _BusinessChatListScreenState();
}

class _BusinessChatListScreenState extends State<BusinessChatListScreen> {
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  
  Stream<List<ChatRoom>>? _chatRoomsStream;

  @override
  void initState() {
    super.initState();
    _initializeChatStream();
  }

  void _initializeChatStream() {
    final user = _authService.currentUser;
    if (user != null) {
      _chatRoomsStream = _chatService.getBusinessChatRoomsStream(user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Müşteri Mesajları'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {
              // Demo chat oluştur (test için)
              final user = _authService.currentUser;
              if (user != null) {
                _chatService.createDemoChatRoom(user.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Demo chat oluşturuluyor...'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            icon: const Icon(Icons.add_comment),
            tooltip: 'Demo Chat Ekle',
          ),
          IconButton(
            onPressed: () {
              // Arama özelliği - TODO: Implement ChatSearchDelegate
              /*
              showSearch(
                context: context,
                delegate: ChatSearchDelegate(_chatService),
              );
              */
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Arama özelliği yakında eklenecek')),
              );
            },
            icon: const Icon(Icons.search),
            tooltip: 'Ara',
          ),
        ],
      ),
      body: StreamBuilder<List<ChatRoom>>(
        stream: _chatRoomsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Mesajlar yüklenirken hata oluştu',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _initializeChatStream();
                      });
                    },
                    child: const Text('Tekrar Dene'),
                  ),
                ],
              ),
            );
          }

          final chatRooms = snapshot.data ?? [];

          if (chatRooms.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _initializeChatStream();
              });
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: chatRooms.length,
              itemBuilder: (context, index) {
                final chatRoom = chatRooms[index];
                return _buildChatRoomItem(chatRoom);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Henüz mesaj yok',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Müşterileriniz sizinle mesajlaştığında burada görünecek',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatRoomItem(ChatRoom chatRoom) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Text(
                chatRoom.customerName.isNotEmpty
                    ? chatRoom.customerName[0].toUpperCase()
                    : 'M',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            if (chatRoom.unreadCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  child: Text(
                    chatRoom.unreadCount > 9 ? '9+' : chatRoom.unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          chatRoom.customerName,
          style: TextStyle(
            fontWeight: chatRoom.unreadCount > 0 
                ? FontWeight.bold 
                : FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              chatRoom.salonName,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              chatRoom.lastMessageText,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: chatRoom.unreadCount > 0 
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                fontWeight: chatRoom.unreadCount > 0 
                    ? FontWeight.w500 
                    : FontWeight.normal,
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              chatRoom.lastMessageTime,
              style: TextStyle(
                fontSize: 12,
                color: chatRoom.unreadCount > 0 
                    ? AppColors.primary
                    : Colors.grey[500],
                fontWeight: chatRoom.unreadCount > 0 
                    ? FontWeight.bold 
                    : FontWeight.normal,
              ),
            ),
            if (chatRoom.lastMessage?.type == MessageType.image) ...[
              const SizedBox(height: 4),
              const Icon(
                Icons.image,
                size: 16,
                color: AppColors.secondary,
              ),
            ] else if (chatRoom.lastMessage?.type == MessageType.appointment) ...[
              const SizedBox(height: 4),
              const Icon(
                Icons.calendar_today,
                size: 16,
                color: AppColors.warning,
              ),
            ],
          ],
        ),
        onTap: () async {
          // Chat detay ekranına git
          final user = _authService.currentUser;
          if (user != null) {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatDetailScreen(
                  chatRoom: chatRoom,
                  currentUserId: user.id,
                  userType: 'business',
                ),
              ),
            );
            
            // Geri döndüğünde stream'i yenile
            setState(() {
              _initializeChatStream();
            });
          }
        },
        onLongPress: () {
          _showChatOptions(chatRoom);
        },
      ),
    );
  }

  void _showChatOptions(ChatRoom chatRoom) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            Container(
              width: 50,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              chatRoom.customerName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.mark_chat_read, color: AppColors.primary),
              title: const Text('Okundu İşaretle'),
              onTap: () async {
                Navigator.pop(context);
                await _chatService.markMessagesAsRead(chatRoom.id, 'business');
                setState(() {
                  _initializeChatStream();
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppColors.error),
              title: const Text('Sohbeti Sil'),
              onTap: () async {
                Navigator.pop(context);
                final bool? confirm = await _showDeleteConfirmation(chatRoom);
                if (confirm == true) {
                  await _chatService.deleteChatRoom(chatRoom.id);
                  setState(() {
                    _initializeChatStream();
                  });
                }
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showDeleteConfirmation(ChatRoom chatRoom) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sohbeti Sil'),
        content: Text(
          '${chatRoom.customerName} ile olan sohbeti silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}

class ChatSearchDelegate extends SearchDelegate<String> {
  final ChatService chatService;

  ChatSearchDelegate(this.chatService);

  @override
  String get searchFieldLabel => 'Müşteri ara...';

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        onPressed: () => query = '',
        icon: const Icon(Icons.clear),
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () => close(context, ''),
      icon: const Icon(Icons.arrow_back),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return buildSuggestions(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return const Center(
        child: Text('Müşteri adı girin...'),
      );
    }

    return FutureBuilder<List<ChatMessage>>(
      future: Future.value([]), // TODO: Implement search
      builder: (context, snapshot) {
        return const Center(
          child: Text('Arama özelliği yakında eklenecek'),
        );
      },
    );
  }
} 