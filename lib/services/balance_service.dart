import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/business_balance_model.dart';

class BalanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // İşletme bakiyesini getir
  Future<BusinessBalanceModel> getBusinessBalance(String businessId) async {
    try {
      // Tüm işlemleri getir
      final transactionsQuery = await _firestore
          .collection('transactions')
          .where('businessId', isEqualTo: businessId)
          .orderBy('createdAt', descending: true)
          .limit(100)
          .get();

      List<TransactionModel> transactions = transactionsQuery.docs
          .map((doc) => TransactionModel.fromFirestore(doc))
          .toList();

      // Bakiye hesapla
      double totalIncome = 0;
      double totalExpense = 0;
      double pendingAmount = 0;
      double withdrawnAmount = 0;

      for (var transaction in transactions) {
        switch (transaction.type) {
          case TransactionType.income:
            totalIncome += transaction.amount;
            break;
          case TransactionType.expense:
          case TransactionType.refund:
            totalExpense += transaction.amount;
            break;
          case TransactionType.withdrawal:
            withdrawnAmount += transaction.amount;
            break;
        }
      }

      double totalBalance = totalIncome - totalExpense;

      return BusinessBalanceModel(
        businessId: businessId,
        totalBalance: totalBalance,
        pendingBalance: pendingAmount,
        withdrawnBalance: withdrawnAmount,
        lastUpdated: DateTime.now(),
        recentTransactions: transactions.take(10).toList(),
      );
    } catch (e) {
      print('Bakiye getirme hatası: $e');
      // Hata durumunda boş bakiye döndür
      return BusinessBalanceModel(
        businessId: businessId,
        totalBalance: 0,
        pendingBalance: 0,
        withdrawnBalance: 0,
        lastUpdated: DateTime.now(),
        recentTransactions: [],
      );
    }
  }

  // Randevu tamamlandığında gelir ekle
  Future<void> addIncomeTransaction({
    required String businessId,
    required double amount,
    required String description,
    String? appointmentId,
    String? customerName,
  }) async {
    try {
      final transaction = TransactionModel(
        id: '',
        businessId: businessId,
        type: TransactionType.income,
        amount: amount,
        description: description,
        appointmentId: appointmentId,
        customerName: customerName,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('transactions')
          .add(transaction.toFirestore());

      print('✅ Gelir işlemi eklendi: $amount ₺');
    } catch (e) {
      print('❌ Gelir işlemi ekleme hatası: $e');
      throw e;
    }
  }

  // Gider işlemi ekle
  Future<void> addExpenseTransaction({
    required String businessId,
    required double amount,
    required String description,
  }) async {
    try {
      final transaction = TransactionModel(
        id: '',
        businessId: businessId,
        type: TransactionType.expense,
        amount: amount,
        description: description,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('transactions')
          .add(transaction.toFirestore());

      print('✅ Gider işlemi eklendi: $amount ₺');
    } catch (e) {
      print('❌ Gider işlemi ekleme hatası: $e');
      throw e;
    }
  }

  // Para çekme işlemi
  Future<void> addWithdrawalTransaction({
    required String businessId,
    required double amount,
    required String description,
  }) async {
    try {
      final transaction = TransactionModel(
        id: '',
        businessId: businessId,
        type: TransactionType.withdrawal,
        amount: amount,
        description: description,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('transactions')
          .add(transaction.toFirestore());

      print('✅ Para çekme işlemi eklendi: $amount ₺');
    } catch (e) {
      print('❌ Para çekme işlemi ekleme hatası: $e');
      throw e;
    }
  }

  // Tüm işlemleri getir
  Future<List<TransactionModel>> getAllTransactions(String businessId) async {
    try {
      final query = await _firestore
          .collection('transactions')
          .where('businessId', isEqualTo: businessId)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs
          .map((doc) => TransactionModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('İşlemler getirme hatası: $e');
      return [];
    }
  }

  // Belirli tarih aralığındaki işlemleri getir
  Future<List<TransactionModel>> getTransactionsByDateRange({
    required String businessId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final query = await _firestore
          .collection('transactions')
          .where('businessId', isEqualTo: businessId)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs
          .map((doc) => TransactionModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Tarih aralığı işlemleri getirme hatası: $e');
      return [];
    }
  }

  // Aylık gelir raporu
  Future<Map<String, double>> getMonthlyIncomeReport(String businessId) async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      final transactions = await getTransactionsByDateRange(
        businessId: businessId,
        startDate: startOfMonth,
        endDate: endOfMonth,
      );

      double totalIncome = 0;
      double totalExpense = 0;

      for (var transaction in transactions) {
        if (transaction.type == TransactionType.income) {
          totalIncome += transaction.amount;
        } else if (transaction.type == TransactionType.expense) {
          totalExpense += transaction.amount;
        }
      }

      return {
        'income': totalIncome,
        'expense': totalExpense,
        'profit': totalIncome - totalExpense,
      };
    } catch (e) {
      print('Aylık rapor hatası: $e');
      return {'income': 0, 'expense': 0, 'profit': 0};
    }
  }
} 