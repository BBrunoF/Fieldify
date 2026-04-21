import 'package:flutter_test/flutter_test.dart';
import 'package:project/features/client/request/data/models/trade_model.dart';

void main() {
  test('Trade.fromJson maps Supabase data into the model', () {
    final trade = Trade.fromJson({
      'id': 3,
      'name': 'Carpentry',
      'description': 'Furniture, doors, floors',
      'standard_rate': 35,
    });

    expect(trade.id, 3);
    expect(trade.name, 'Carpentry');
    expect(trade.description, 'Furniture, doors, floors');
    expect(trade.standardRate, 35);
  });
}
