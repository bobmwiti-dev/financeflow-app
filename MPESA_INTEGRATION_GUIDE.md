# M-Pesa SMS Import Integration Guide

## 🚀 Quick Start

The M-Pesa SMS import system is now fully integrated into FinanceFlow. Here's how to use it:

### 1. **Access M-Pesa Import**
```dart
// Navigate to M-Pesa import screen
Navigator.pushNamed(context, '/mpesa_import');

// Or navigate to M-Pesa settings
Navigator.pushNamed(context, '/mpesa_settings');
```

### 2. **Add to Settings Menu**
Add M-Pesa options to your settings screen:

```dart
ListTile(
  leading: Icon(Icons.mobile_friendly),
  title: Text('M-Pesa Import'),
  subtitle: Text('Import transactions from SMS'),
  onTap: () => Navigator.pushNamed(context, '/mpesa_import'),
),
ListTile(
  leading: Icon(Icons.settings),
  title: Text('M-Pesa Settings'),
  subtitle: Text('Configure import preferences'),
  onTap: () => Navigator.pushNamed(context, '/mpesa_settings'),
),
```

### 3. **Add to Dashboard Quick Actions**
```dart
QuickActionCard(
  title: 'Import M-Pesa',
  icon: Icons.sms,
  color: Colors.green,
  onTap: () => Navigator.pushNamed(context, '/mpesa_import'),
),
```

## 📱 User Workflow

### **First Time Setup:**
1. User taps "Import M-Pesa" from settings or dashboard
2. App requests SMS permission
3. User grants permission
4. App scans SMS messages for M-Pesa transactions
5. User previews parsed transactions
6. User confirms import
7. Transactions appear in expenses/income screens

### **Subsequent Imports:**
1. User opens M-Pesa import
2. App automatically detects new transactions
3. Shows only new/unimported transactions
4. User confirms import
5. New transactions added to existing data

## 🔧 Developer API

### **Import Transactions Programmatically:**
```dart
// Import all M-Pesa transactions from last 30 days
final result = await MpesaImportService.importTransactions(
  maxDays: 30,
  categorizeAutomatically: true,
  skipDuplicates: true,
);

print('Imported: ${result.imported}');
print('Skipped: ${result.skipped}');
print('Failed: ${result.failed}');
```

### **Test SMS Parsing:**
```dart
// Test parsing without importing
final transactions = await MpesaImportService.testSmsImport(
  maxCount: 10,
);

for (var tx in transactions) {
  print('${tx.type}: ${tx.amount} - ${tx.description}');
}
```

### **Get Import Statistics:**
```dart
final stats = await MpesaImportService.getImportStatistics();
print('Total M-Pesa records: ${stats['totalMpesaTransactions']}');
print('Import success rate: ${stats['importSuccessRate']}');
```

### **Configure Import Settings:**
```dart
final config = MpesaImportConfig(
  autoImportEnabled: true,
  categorizeAutomatically: true,
  importOnlyNewSms: true,
  maxDaysToImport: 30,
);

await MpesaImportService.saveImportConfig(config);
```

## 📊 Supported Transaction Types

| M-Pesa Type | Description | Auto Category |
|-------------|-------------|---------------|
| **Sent** | Money sent to others | Transfer |
| **Received** | Money received | Income |
| **Withdrawal** | Cash from agent | Cash Withdrawal |
| **Deposit** | Cash to agent | Cash Deposit |
| **Paybill** | Bill payments | Utilities/Bills |
| **Buy Goods** | Merchant payments | Shopping/Food |
| **Airtime** | Mobile top-up | Utilities |
| **Reversal** | Transaction reversal | Adjustment |

## 🏪 Kenya-Specific Auto-Categorization

### **Merchants:**
- **Java House** → Food & Dining
- **Naivas, Tuskys** → Groceries
- **Shell, Total** → Transport

### **Utilities:**
- **KPLC** → Utilities (Electricity)
- **Nairobi Water** → Utilities (Water)

### **Services:**
- **Hospitals, Clinics** → Healthcare
- **Schools, Universities** → Education
- **Insurance Companies** → Insurance

## 🔒 Privacy & Security

- **On-Device Processing**: All SMS parsing happens locally
- **No Data Transmission**: SMS content never sent to servers
- **Secure Storage**: M-Pesa records stored in user's Firestore
- **Permission-Based**: Requires explicit SMS permission
- **Audit Trail**: Complete import history maintained

## 🚨 Error Handling

### **Common Issues:**
1. **SMS Permission Denied**: Guide user to grant permission
2. **No M-Pesa SMS Found**: Check SMS inbox for M-Pesa messages
3. **Parsing Failures**: Some SMS formats may not be recognized
4. **Duplicate Imports**: Automatic duplicate detection prevents re-imports

### **Error Recovery:**
```dart
try {
  final result = await MpesaImportService.importTransactions();
  if (!result.success) {
    // Handle import failure
    showErrorDialog(result.message);
  }
} catch (e) {
  // Handle exceptions
  showErrorDialog('Import failed: $e');
}
```

## 📈 Performance Considerations

- **Batch Processing**: Handles large SMS volumes efficiently
- **Background Processing**: Import runs asynchronously
- **Memory Efficient**: Processes SMS in chunks
- **Fast Parsing**: Optimized regex patterns for speed

## 🔄 Integration with Existing Features

### **Dashboard:**
- Imported transactions appear in recent transactions
- Safe-to-spend calculation includes M-Pesa data
- Monthly summaries include imported amounts

### **Reports:**
- All report cards include M-Pesa transactions
- Category breakdowns show M-Pesa categories
- Trends analysis includes imported data

### **Budgets:**
- M-Pesa expenses count toward budget limits
- Budget alerts include imported transactions
- Category budgets track M-Pesa spending

## 🎯 Best Practices

1. **Regular Imports**: Encourage users to import weekly/monthly
2. **Review Before Import**: Always show preview screen
3. **Category Verification**: Allow users to adjust auto-categories
4. **Backup Data**: M-Pesa records provide audit trail
5. **User Education**: Explain benefits of automatic import

## 📱 Testing

### **Test with Sample SMS:**
```
QH12345678 Confirmed. Ksh500.00 sent to JOHN DOE 0722123456 on 15/1/25 at 2:30 PM. M-PESA balance is Ksh15,000.00.
```

### **Expected Result:**
- **Type**: Sent
- **Amount**: 500.00
- **Recipient**: JOHN DOE
- **Category**: Transfer
- **Balance**: 15,000.00

## 🚀 Future Enhancements

- **Real-time Import**: Automatic import on SMS receipt
- **Bank Integration**: Extend to other mobile money services
- **AI Categorization**: Machine learning for better categories
- **Expense Splitting**: Split transactions among family members
- **Receipt Matching**: Match M-Pesa to physical receipts

---

**Status**: ✅ Production Ready
**Version**: 1.0.0
**Last Updated**: January 2025
