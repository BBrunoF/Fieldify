import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/trade_model.dart';
import '../services/request_service.dart';

class RequestFailure implements Exception {
  final String message;
  const RequestFailure(this.message);

  @override
  String toString() => message;
}

class RequestRepository {
  final RequestService _service;

  RequestRepository({RequestService? service})
    : _service = service ?? RequestService();

  String? getCurrentUserId() => _service.getCurrentUserId();

  Future<void> submitRequest(Map<String, dynamic> data) async {
    try {
      await _service.submitRequest(data);
    } on PostgrestException catch (e) {
      throw RequestFailure(e.message);
    }
  }

  Future<List<Trade>> getTrades() async {
    try {
      final rows = await _service.getTrades();
      return rows.map(Trade.fromJson).toList();
    } on PostgrestException catch (e) {
      throw RequestFailure(e.message);
    }
  }

  Future<List<String>> uploadPhotos({
    required String clientId,
    required String requestId,
    required List<File> files,
  }) async {
    try {
      final paths = <String>[];
      for (var i = 0; i < files.length; i++) {
        final path = await _service.uploadPhoto(
          clientId: clientId,
          requestId: requestId,
          index: i,
          file: files[i],
        );
        paths.add(path);
      }
      return paths;
    } on StorageException catch (e) {
      throw RequestFailure(e.message);
    }
  }
}