import '../../../../../core/supabase/supabase_client.dart';
import '../models/trade_model.dart';

class TradesRepository {
  Future<List<Trade>> getTrades() async {
    final data = await supabase.from('trades').select().order('id');
    return (data as List).map((e) => Trade.fromJson(e)).toList();
  }
}
