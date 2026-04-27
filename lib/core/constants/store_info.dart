/// Public-facing store contact + payment details displayed in the app.
///
/// Kept in one place so it's easy to update when the store opens new
/// branches or adds more payment options.
class StoreInfo {
  StoreInfo._();

  static const String phone = '09029215938';
  static const String phoneDisplay = '0902 921 5938';
  static const String whatsAppNumber = '2349029215938'; // international format
  static const String email = 'blessingadebayo252@gmail.com';

  /// Direct bank transfer details for customers who choose the
  /// "Bank Transfer" payment option at checkout.
  static const BankAccount payoutAccount = BankAccount(
    accountName: 'Adebayo Blessing Ayobami',
    accountNumber: '9029215938',
    bankName: 'Opay',
  );
}

class BankAccount {
  final String accountName;
  final String accountNumber;
  final String bankName;
  const BankAccount({
    required this.accountName,
    required this.accountNumber,
    required this.bankName,
  });
}
