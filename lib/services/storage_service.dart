import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<String> uploadImageToStorage(String childName, File file) async {
    print('\n📸 Starting image upload process...');
    print('📁 Folder: $childName');
    
    String id = const Uuid().v1();
    String path = '$childName/$id';
    print('🔄 Processing image...');

    try {
      print('⬆️ Uploading to Supabase storage...');
      await _supabase.storage.from('instagram-images').upload(
            path,
            file,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: false,
            ),
          );
      print('✅ Image uploaded successfully!');

      print('🔗 Generating public URL...');
      final String downloadUrl = _supabase.storage
          .from('instagram-images')
          .getPublicUrl(path);
      print('✅ Image URL generated!\n');

      return downloadUrl;
    } catch (e) {
      print('❌ Error uploading image: $e\n');
      throw Exception('Failed to upload image: $e');
    }
  }
}
