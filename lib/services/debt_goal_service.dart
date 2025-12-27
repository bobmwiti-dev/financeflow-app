import 'package:logging/logging.dart';
import 'package:sqflite/sqflite.dart';

import 'database_service.dart';
import '../models/debt_payoff_goal.dart';
import '../models/debt_payment.dart';

/// Service responsible for persisting [DebtPayoffGoal]s in the local SQLite
/// database via [DatabaseService]. Firestore integration can be added later.
class DebtGoalService {
  static final DebtGoalService instance = DebtGoalService._internal();
  final Logger _logger = Logger('DebtGoalService');
  final DatabaseService _dbService = DatabaseService.instance;

  DebtGoalService._internal();

  Future<Database> get _db async {
    final db = await _dbService.database;
    // Ensure the table exists (idempotent). This makes the service self-contained
    // and avoids large edits in DatabaseService for now.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS debt_goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        originalAmount REAL NOT NULL,
        currentBalance REAL NOT NULL,
        interestRate REAL NOT NULL,
        minimumMonthlyPayment REAL NOT NULL,
        targetDate TEXT,
        description TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');
        // Ensure payments table as well
    await db.execute('''
      CREATE TABLE IF NOT EXISTS debt_payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        goalId INTEGER NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        note TEXT,
        FOREIGN KEY(goalId) REFERENCES debt_goals(id) ON DELETE CASCADE
      )
    ''');
    return db;
  }

  Future<List<DebtPayoffGoal>> fetchGoals() async {
    final db = await _db;
    final maps = await db.query('debt_goals', orderBy: 'createdAt DESC');
    return maps.map((m) => DebtPayoffGoal.fromMap(m)).toList();
  }

  Future<int> insertGoal(DebtPayoffGoal goal) async {
    final db = await _db;
    _logger.info('Inserting debt goal: ${goal.name}');
    return db.insert('debt_goals', goal.toMap());
  }

  Future<int> updateGoal(DebtPayoffGoal goal) async {
    if (goal.id == null) throw ArgumentError('Goal id is null');
    final db = await _db;
    _logger.info('Updating debt goal id=${goal.id}');
    return db.update('debt_goals', goal.toMap(), where: 'id = ?', whereArgs: [goal.id]);
  }

  /// Delete goal and its payments (ON DELETE CASCADE handles payments)
  Future<int> deleteGoal(String id) async {
    final db = await _db;
    _logger.info('Deleting debt goal id=$id');
    return db.delete('debt_goals', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<DebtPayment>> fetchPaymentsForGoal(int goalId) async {
    final db = await _db;
    final maps = await db.query('debt_payments', where: 'goalId = ?', whereArgs: [goalId]);
    return maps.map((m) => DebtPayment.fromMap(m)).toList();
  }

  Future<int> insertPayment(DebtPayment payment) async {
    final db = await _db;
    _logger.info('Inserting debt payment for goal ${payment.goalId}');
    return db.insert('debt_payments', payment.toMap());
  }

  Future<int> updatePayment(DebtPayment payment) async {
    if (payment.id == null) throw ArgumentError('Payment id is null');
    final db = await _db;
    _logger.info('Updating debt payment id=${payment.id}');
    return db.update('debt_payments', payment.toMap(), where: 'id = ?', whereArgs: [payment.id]);
  }

  Future<int> deletePayment(int id) async {
    final db = await _db;
    _logger.info('Deleting debt payment id=$id');
    return db.delete('debt_payments', where: 'id = ?', whereArgs: [id]);
  }
}
