import 'package:flutter_test/flutter_test.dart';
import 'package:spendmind/parser_service.dart';

void main() {
  group('SMSParserService Tests', () {
    test('Parse GPay Debit Notification SMS', () {
      const sms = "Sent Rs. 150.00 to Swiggy on 02-Jun-26 via HDFC Bank UPI Ref 12345.";
      final tx = SMSParserService.parseMessage(sms, "HDFCBK");
      
      expect(tx, isNotNull);
      expect(tx!.amount, equals(150.00));
      expect(tx.title, equals("Swiggy"));
      expect(tx.category, equals("Food"));
      expect(tx.isParsedSuccessfully, isTrue);
    });

    test('Parse Debited Notification SMS with INR', () {
      const sms = "Your A/c XX123 is debited by INR 2500 for Apollo Pharmacy.";
      final tx = SMSParserService.parseMessage(sms, "ICICIBK");
      
      expect(tx, isNotNull);
      expect(tx!.amount, equals(2500.00));
      expect(tx.title, equals("Apollo Pharmacy"));
      expect(tx.category, equals("Healthcare"));
    });

    test('Parse Txn Notification SMS', () {
      const sms = "Txn of Rs. 350.00 on A/c 54321 at HPCL Petrol Pump.";
      final tx = SMSParserService.parseMessage(sms, "SBIBK");
      
      expect(tx, isNotNull);
      expect(tx!.amount, equals(350.00));
      expect(tx.title, equals("Hpcl Petrol Pump"));
      expect(tx.category, equals("Fuel"));
    });

    test('Parse Simple Spent at Notification', () {
      const sms = "Rs. 649 spent at Netflix subscription on card ending 8812.";
      final tx = SMSParserService.parseMessage(sms, "AXISBK");
      
      expect(tx, isNotNull);
      expect(tx!.amount, equals(649.00));
      expect(tx.title, equals("Netflix"));
      expect(tx.category, equals("Subscriptions"));
    });

    test('Parse Non-Transaction SMS (should return null)', () {
      const sms = "Your OTP for login is 987654. Do not share this with anyone.";
      final tx = SMSParserService.parseMessage(sms, "AM-OTP");
      
      expect(tx, isNull);
    });
  });
}
