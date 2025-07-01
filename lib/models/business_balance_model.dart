import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType {
  income,     // Gelir (randevu ödemesi)
  expense,    // Gider
  withdrawal, // Para çekme
  refund,     // İade
}

class TransactionModel {
  final String id;
  final String businessId;
  final TransactionType type;
  final double amount;
  final String description;
  final String? appointmentId;
  final String? customerName;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  TransactionModel({
    required this.id,
    required this.businessId,
    required this.type,
    required this.amount,
    required this.description,
    this.appointmentId,
    this.customerName,
    required this.createdAt,
    this.metadata,
  });

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return TransactionModel(
      id: doc.id,
      businessId: data['businessId'] ?? '',
      type: TransactionType.values.firstWhere(
        (t) => t.toString().split('.').last == data['type'],
        orElse: () => TransactionType.income,
      ),
      amount: (data['amount'] ?? 0.0).toDouble(),
      description: data['description'] ?? '',
      appointmentId: data['appointmentId'],
      customerName: data['customerName'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'businessId': businessId,
      'type': type.toString().split('.').last,
      'amount': amount,
      'description': description,
      'appointmentId': appointmentId,
      'customerName': customerName,
      'createdAt': Timestamp.fromDate(createdAt),
      'metadata': metadata,
    };
  }

  String get typeText {
    switch (type) {
      case TransactionType.income:
        return 'Gelir';
      case TransactionType.expense:
        return 'Gider';
      case TransactionType.withdrawal:
        return 'Para Çekme';
      case TransactionType.refund:
        return 'İade';
    }
  }

  String get amountText {
    final prefix = type == TransactionType.income ? '+' : '-';
    return '$prefix${amount.toStringAsFixed(2)} ₺';
  }
}

class BusinessBalanceModel {
  final String businessId;
  final double totalBalance;
  final double pendingBalance;
  final double withdrawnBalance;
  final DateTime lastUpdated;
  final List<TransactionModel> recentTransactions;

  BusinessBalanceModel({
    required this.businessId,
    required this.totalBalance,
    required this.pendingBalance,
    required this.withdrawnBalance,
    required this.lastUpdated,
    required this.recentTransactions,
  });

  double get availableBalance => totalBalance - pendingBalance;

  String get totalBalanceText => '${totalBalance.toStringAsFixed(2)} ₺';
  String get availableBalanceText => '${availableBalance.toStringAsFixed(2)} ₺';
  String get pendingBalanceText => '${pendingBalance.toStringAsFixed(2)} ₺';
  String get withdrawnBalanceText => '${withdrawnBalance.toStringAsFixed(2)} ₺';
} 