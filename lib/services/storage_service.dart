import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<String> uploadImageToStorage(String childName, File file) async {
    String id = const Uuid().v1();
    String path = '$childName/$id';

    try {
      await _supabase.storage.from('instagram').upload(
            path,
            file,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: false,
            ),
          );

      final String downloadUrl = _supabase.storage
          .from('instagram')
          .getPublicUrl(path);

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }
}
