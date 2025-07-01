import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType {
  text,
  image,
  appointment,
  system,
}

class ChatMessage {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String senderType; // 'customer' veya 'business'
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final bool isRead;
  final String? imageUrl;
  final Map<String, dynamic>? appointmentData;

  ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    required this.senderType,
    required this.content,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.imageUrl,
    this.appointmentData,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    try {
      return ChatMessage(
        id: doc.id,
        chatId: data['chatId'] ?? '',
        senderId: data['senderId'] ?? '',
        senderName: data['senderName'] ?? 'Bilinmeyen',
        senderType: data['senderType'] ?? 'customer',
        content: data['content'] ?? '',
        type: MessageType.values.firstWhere(
          (type) => type.toString().split('.').last == data['type'],
          orElse: () => MessageType.text,
        ),
        timestamp: data['timestamp'] != null 
            ? (data['timestamp'] as Timestamp).toDate()
            : DateTime.now(),
        isRead: data['isRead'] ?? false,
        imageUrl: data['imageUrl'],
        appointmentData: data['appointmentData'],
      );
    } catch (e) {
      print('ChatMessage parse hatası: $e');
      print('Problematik message data: $data');
      rethrow;
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'senderType': senderType,
      'content': content,
      'type': type.toString().split('.').last,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'imageUrl': imageUrl,
      'appointmentData': appointmentData,
    };
  }

  ChatMessage copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? senderName,
    String? senderType,
    String? content,
    MessageType? type,
    DateTime? timestamp,
    bool? isRead,
    String? imageUrl,
    Map<String, dynamic>? appointmentData,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderType: senderType ?? this.senderType,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      imageUrl: imageUrl ?? this.imageUrl,
      appointmentData: appointmentData ?? this.appointmentData,
    );
  }
}

class ChatRoom {
  final String id;
  final String customerId;
  final String customerName;
  final String businessId;
  final String businessName;
  final String salonId;
  final String salonName;
  final ChatMessage? lastMessage;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int unreadCount; // İşletme için okunmamış mesaj sayısı
  final int customerUnreadCount; // Müşteri için okunmamış mesaj sayısı
  final bool isActive;

  ChatRoom({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.businessId,
    required this.businessName,
    required this.salonId,
    required this.salonName,
    this.lastMessage,
    required this.createdAt,
    required this.updatedAt,
    this.unreadCount = 0,
    this.customerUnreadCount = 0,
    this.isActive = true,
  });

  factory ChatRoom.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    try {
      print('ChatRoom parse ediliyor - ID: ${doc.id}');
      print('Data keys: ${data.keys.toList()}');
      
      return ChatRoom(
        id: doc.id,
        customerId: data['customerId'] ?? '',
        customerName: data['customerName'] ?? 'Bilinmeyen Müşteri',
        businessId: data['businessId'] ?? '',
        businessName: data['businessName'] ?? 'Bilinmeyen İşletme',
        salonId: data['salonId'] ?? '',
        salonName: data['salonName'] ?? 'Bilinmeyen Salon',
        lastMessage: data['lastMessage'] != null 
            ? _parseLastMessage(data['lastMessage'])
            : null,
        createdAt: data['createdAt'] != null 
            ? (data['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
        updatedAt: data['updatedAt'] != null 
            ? (data['updatedAt'] as Timestamp).toDate()
            : DateTime.now(),
        unreadCount: data['unreadCount'] ?? 0,
        customerUnreadCount: data['customerUnreadCount'] ?? 0,
        isActive: data['isActive'] ?? true,
      );
    } catch (e) {
      print('ChatRoom parse hatası: $e');
      print('Problematik data: $data');
      rethrow;
    }
  }

  static ChatMessage _parseLastMessage(Map<String, dynamic> data) {
    try {
      return ChatMessage(
        id: data['id'] ?? '',
        chatId: data['chatId'] ?? '',
        senderId: data['senderId'] ?? '',
        senderName: data['senderName'] ?? 'Bilinmeyen',
        senderType: data['senderType'] ?? 'customer',
        content: data['content'] ?? '',
        type: MessageType.values.firstWhere(
          (type) => type.toString().split('.').last == data['type'],
          orElse: () => MessageType.text,
        ),
        timestamp: data['timestamp'] != null 
            ? (data['timestamp'] as Timestamp).toDate()
            : DateTime.now(),
        isRead: data['isRead'] ?? false,
        imageUrl: data['imageUrl'],
        appointmentData: data['appointmentData'],
      );
    } catch (e) {
      print('LastMessage parse hatası: $e');
      print('Problematik lastMessage data: $data');
      // Hata durumunda boş mesaj döndür
      return ChatMessage(
        id: '',
        chatId: '',
        senderId: '',
        senderName: 'Sistem',
        senderType: 'system',
        content: 'Mesaj yüklenemedi',
        type: MessageType.text,
        timestamp: DateTime.now(),
      );
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'businessId': businessId,
      'businessName': businessName,
      'salonId': salonId,
      'salonName': salonName,
      'lastMessage': lastMessage?.toFirestore(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'unreadCount': unreadCount,
      'customerUnreadCount': customerUnreadCount,
      'isActive': isActive,
    };
  }

  ChatRoom copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? businessId,
    String? businessName,
    String? salonId,
    String? salonName,
    ChatMessage? lastMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? unreadCount,
    int? customerUnreadCount,
    bool? isActive,
  }) {
    return ChatRoom(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      businessId: businessId ?? this.businessId,
      businessName: businessName ?? this.businessName,
      salonId: salonId ?? this.salonId,
      salonName: salonName ?? this.salonName,
      lastMessage: lastMessage ?? this.lastMessage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      unreadCount: unreadCount ?? this.unreadCount,
      customerUnreadCount: customerUnreadCount ?? this.customerUnreadCount,
      isActive: isActive ?? this.isActive,
    );
  }

  String get lastMessageText {
    if (lastMessage == null) return 'Henüz mesaj yok';
    
    switch (lastMessage!.type) {
      case MessageType.text:
        return lastMessage!.content;
      case MessageType.image:
        return '📷 Fotoğraf';
      case MessageType.appointment:
        return '📅 Randevu';
      case MessageType.system:
        return lastMessage!.content;
    }
  }

  String get lastMessageTime {
    if (lastMessage == null) return '';
    
    final now = DateTime.now();
    final messageDate = lastMessage!.timestamp;
    final difference = now.difference(messageDate);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}g';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}s';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}dk';
    } else {
      return 'Şimdi';
    }
  }
} 