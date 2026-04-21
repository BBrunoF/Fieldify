import 'package:flutter_test/flutter_test.dart';
import 'package:project/features/client/request/data/models/trade_model.dart';

void main() {
  test('Trade.fromJson maps Supabase data into the model', () {
    final trade = Trade.fromJson({
      'id': 3,
      'slug': 'carpentry',
      'display_name': 'Carpentry',
      'standard_rate': 35.00,
    });

    expect(trade.id, 3);
    expect(trade.slug, 'carpentry');
    expect(trade.displayName, 'Carpentry');
    expect(trade.standardRate, 35);
  });
}
