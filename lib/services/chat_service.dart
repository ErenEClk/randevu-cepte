import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_model.dart';
import '../models/user_model.dart';
import '../models/salon_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Chat room oluştur veya var olanı getir
  Future<ChatRoom?> createOrGetChatRoom({
    required String customerId,
    required String customerName,
    required String salonId,
    required String salonName,
    required String businessId,
    required String businessName,
  }) async {
    try {
      // Var olan chat room'u kontrol et
      final querySnapshot = await _firestore
          .collection('chats')
          .where('customerId', isEqualTo: customerId)
          .where('salonId', isEqualTo: salonId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return ChatRoom.fromFirestore(querySnapshot.docs.first);
      }

      // Yeni chat room oluştur
      final chatRoom = ChatRoom(
        id: '',
        customerId: customerId,
        customerName: customerName,
        businessId: businessId,
        businessName: businessName,
        salonId: salonId,
        salonName: salonName,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final docRef = await _firestore.collection('chats').add(chatRoom.toFirestore());
      
      return chatRoom.copyWith(id: docRef.id);
    } catch (e) {
      print('Chat room oluşturma hatası: $e');
      return null;
    }
  }

  // Mesaj gönder
  Future<bool> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String senderType,
    required String content,
    MessageType type = MessageType.text,
    String? imageUrl,
    Map<String, dynamic>? appointmentData,
  }) async {
    try {
      final message = ChatMessage(
        id: '',
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        senderType: senderType,
        content: content,
        type: type,
        timestamp: DateTime.now(),
        imageUrl: imageUrl,
        appointmentData: appointmentData,
      );

      // Mesajı kaydet
      final docRef = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add(message.toFirestore());

      // Chat room'u güncelle
      await _updateChatRoom(chatId, message.copyWith(id: docRef.id));

      return true;
    } catch (e) {
      print('Mesaj gönderme hatası: $e');
      return false;
    }
  }

  // Chat room'u güncelle (son mesaj, tarih, okunmamış sayı)
  Future<void> _updateChatRoom(String chatId, ChatMessage lastMessage) async {
    try {
      final updateData = {
        'lastMessage': lastMessage.toFirestore(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      // Okunmamış mesaj sayısını artır
      if (lastMessage.senderType == 'customer') {
        updateData['unreadCount'] = FieldValue.increment(1);
      } else {
        updateData['customerUnreadCount'] = FieldValue.increment(1);
      }

      await _firestore.collection('chats').doc(chatId).update(updateData);
    } catch (e) {
      print('Chat room güncelleme hatası: $e');
    }
  }

  // Mesajları dinle (real-time)
  Stream<List<ChatMessage>> getMessagesStream(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessage.fromFirestore(doc))
            .toList());
  }

  // İşletme chat room'larını getir
  Stream<List<ChatRoom>> getBusinessChatRoomsStream(String businessId) {
    print('=== CHAT DEBUG ===');
    print('Business chat rooms stream başlatılıyor. Business ID: $businessId');
    
    try {
      // Önce sadece businessId ile sorgula, sonra client-side filtering yap
      return _firestore
          .collection('chats')
          .where('businessId', isEqualTo: businessId)
          .snapshots()
          .map((snapshot) {
            print('Firestore chat snapshot alındı. Doküman sayısı: ${snapshot.docs.length}');
            
            final chatRooms = snapshot.docs
                .map((doc) {
                  try {
                    print('Chat room parse ediliyor: ${doc.id}');
                    return ChatRoom.fromFirestore(doc);
                  } catch (e) {
                    print('Chat room parse hatası [${doc.id}]: $e');
                    return null;
                  }
                })
                .where((chatRoom) => chatRoom != null && chatRoom.isActive)
                .cast<ChatRoom>()
                .toList();
                
            // Client-side sorting
            chatRooms.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
            
            print('Aktif chat room sayısı: ${chatRooms.length}');
            return chatRooms;
          });
    } catch (e) {
      print('Chat stream hatası: $e');
      return Stream.value([]);
    }
  }

  // Müşteri chat room'larını getir
  Stream<List<ChatRoom>> getCustomerChatRoomsStream(String customerId) {
    print('=== CUSTOMER CHAT DEBUG ===');
    print('Customer chat rooms stream başlatılıyor. Customer ID: $customerId');
    
    try {
      // Önce sadece customerId ile sorgula, sonra client-side filtering yap
      return _firestore
          .collection('chats')
          .where('customerId', isEqualTo: customerId)
          .snapshots()
          .map((snapshot) {
            print('Customer chat snapshot alındı. Doküman sayısı: ${snapshot.docs.length}');
            
            final chatRooms = snapshot.docs
                .map((doc) {
                  try {
                    return ChatRoom.fromFirestore(doc);
                  } catch (e) {
                    print('Customer chat room parse hatası [${doc.id}]: $e');
                    return null;
                  }
                })
                .where((chatRoom) => chatRoom != null && chatRoom.isActive)
                .cast<ChatRoom>()
                .toList();
                
            // Client-side sorting
            chatRooms.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
            
            print('Aktif customer chat room sayısı: ${chatRooms.length}');
            return chatRooms;
          });
    } catch (e) {
      print('Customer chat stream hatası: $e');
      return Stream.value([]);
    }
  }

  // Mesajları okundu olarak işaretle
  Future<void> markMessagesAsRead(String chatId, String userType) async {
    try {
      final updateData = <String, dynamic>{};
      
      if (userType == 'business') {
        updateData['unreadCount'] = 0;
      } else {
        updateData['customerUnreadCount'] = 0;
      }

      await _firestore.collection('chats').doc(chatId).update(updateData);

      // Mesajları da okundu olarak işaretle
      final messagesSnapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in messagesSnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      print('Mesajları okundu işaretleme hatası: $e');
    }
  }

  // Chat room'u sil
  Future<bool> deleteChatRoom(String chatId) async {
    try {
      // Önce mesajları sil
      final messagesSnapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .get();

      final batch = _firestore.batch();
      for (final doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Chat room'u pasif yap
      batch.update(
        _firestore.collection('chats').doc(chatId),
        {'isActive': false},
      );

      await batch.commit();
      return true;
    } catch (e) {
      print('Chat room silme hatası: $e');
      return false;
    }
  }

  // Randevu mesajı gönder
  Future<bool> sendAppointmentMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String senderType,
    required Map<String, dynamic> appointmentData,
  }) async {
    String content = '';
    
    if (senderType == 'customer') {
      content = 'Randevu talebi gönderildi';
    } else {
      content = 'Randevu onaylandı';
    }

    return await sendMessage(
      chatId: chatId,
      senderId: senderId,
      senderName: senderName,
      senderType: senderType,
      content: content,
      type: MessageType.appointment,
      appointmentData: appointmentData,
    );
  }

  // Sistem mesajı gönder
  Future<bool> sendSystemMessage({
    required String chatId,
    required String content,
  }) async {
    return await sendMessage(
      chatId: chatId,
      senderId: 'system',
      senderName: 'Sistem',
      senderType: 'system',
      content: content,
      type: MessageType.system,
    );
  }

  // Toplam okunmamış mesaj sayısı (işletme için)
  Future<int> getTotalUnreadCount(String businessId) async {
    try {
      final querySnapshot = await _firestore
          .collection('chats')
          .where('businessId', isEqualTo: businessId)
          .where('isActive', isEqualTo: true)
          .get();

      int totalUnread = 0;
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        totalUnread += (data['unreadCount'] ?? 0) as int;
      }

      return totalUnread;
    } catch (e) {
      print('Toplam okunmamış mesaj sayısı hatası: $e');
      return 0;
    }
  }

  // Müşteri için toplam okunmamış mesaj sayısı
  Future<int> getCustomerTotalUnreadCount(String customerId) async {
    try {
      final querySnapshot = await _firestore
          .collection('chats')
          .where('customerId', isEqualTo: customerId)
          .where('isActive', isEqualTo: true)
          .get();

      int totalUnread = 0;
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        totalUnread += (data['customerUnreadCount'] ?? 0) as int;
      }

      return totalUnread;
    } catch (e) {
      print('Müşteri toplam okunmamış mesaj sayısı hatası: $e');
      return 0;
    }
  }

  // Chat room detayını getir
  Future<ChatRoom?> getChatRoom(String chatId) async {
    try {
      final doc = await _firestore.collection('chats').doc(chatId).get();
      if (doc.exists) {
        return ChatRoom.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Chat room getirme hatası: $e');
      return null;
    }
  }

  // Fotoğraf mesajı gönder
  Future<bool> sendImageMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String senderType,
    required String imageUrl,
    String content = 'Fotoğraf gönderildi',
  }) async {
    return await sendMessage(
      chatId: chatId,
      senderId: senderId,
      senderName: senderName,
      senderType: senderType,
      content: content,
      type: MessageType.image,
      imageUrl: imageUrl,
    );
  }

  // Mesaj ara
  Future<List<ChatMessage>> searchMessages(String chatId, String query) async {
    try {
      final snapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('content', isGreaterThanOrEqualTo: query)
          .where('content', isLessThanOrEqualTo: '$query\uf8ff')
          .orderBy('content')
          .orderBy('timestamp', descending: true)
          .limit(20)
          .get();

      return snapshot.docs
          .map((doc) => ChatMessage.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Mesaj arama hatası: $e');
      return [];
    }
  }

  // Demo chat room oluştur (test için)
  Future<void> createDemoChatRoom(String businessId) async {
    try {
      print('=== DEMO CHAT OLUŞTURULUYOR ===');
      print('Business ID: $businessId');
      
      // Demo chat room verisi
      final demoChatRoom = {
        'customerId': 'demo_customer_123',
        'customerName': 'Demo Müşteri',
        'businessId': businessId,
        'businessName': 'Test Kuaför Salonu',
        'salonId': businessId,
        'salonName': 'Test Kuaför Salonu',
        'lastMessage': {
          'id': 'demo_message_1',
          'chatId': 'demo_chat_id',
          'senderId': 'demo_customer_123',
          'senderName': 'Demo Müşteri',
          'senderType': 'customer',
          'content': 'Merhaba, randevu almak istiyorum.',
          'type': 'text',
          'timestamp': Timestamp.fromDate(DateTime.now().subtract(const Duration(minutes: 5))),
          'isRead': false,
        },
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 1))),
        'updatedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(minutes: 5))),
        'unreadCount': 1,
        'customerUnreadCount': 0,
        'isActive': true,
      };
      
      // Demo chat room'u kaydet
      final docRef = await _firestore.collection('chats').add(demoChatRoom);
      print('Demo chat room oluşturuldu: ${docRef.id}');
      
      // Demo mesajlar ekle
      final demoMessages = [
        {
          'chatId': docRef.id,
          'senderId': 'demo_customer_123',
          'senderName': 'Demo Müşteri',
          'senderType': 'customer',
          'content': 'Merhaba, randevu almak istiyorum.',
          'type': 'text',
          'timestamp': Timestamp.fromDate(DateTime.now().subtract(const Duration(minutes: 10))),
          'isRead': false,
        },
        {
          'chatId': docRef.id,
          'senderId': 'demo_customer_123',
          'senderName': 'Demo Müşteri',
          'senderType': 'customer',
          'content': 'Yarın için müsait saatiniz var mı?',
          'type': 'text',
          'timestamp': Timestamp.fromDate(DateTime.now().subtract(const Duration(minutes: 5))),
          'isRead': false,
        }
      ];
      
      for (final messageData in demoMessages) {
        await _firestore
            .collection('chats')
            .doc(docRef.id)
            .collection('messages')
            .add(messageData);
      }
      
      print('Demo mesajlar eklendi');
      print('=== DEMO CHAT HAZIR ===');
      
    } catch (e) {
      print('Demo chat oluşturma hatası: $e');
    }
  }
} 