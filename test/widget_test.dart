// Basic smoke test for Abeni Mart.
import 'package:abeni_mart/core/constants/app_constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('app name constant is set', () {
    expect(AppConstants.appName, 'Abeni Mart');
  });

  test('Congo units include Congo and Bag', () {
    expect(AppConstants.congoUnits.contains('Congo'), isTrue);
    expect(AppConstants.congoUnits.contains('Bag'), isTrue);
  });

  test('categories include required staples', () {
    final ids = AppConstants.categories.map((c) => c.id).toList();
    expect(ids, containsAll(['rice', 'beans', 'garri', 'sugar']));
  });
}
