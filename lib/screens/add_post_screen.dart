import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../providers/user_provider.dart';
import '../services/storage_service.dart';
import '../services/firestore_service.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({Key? key}) : super(key: key);

  @override
  _AddPostScreenState createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  File? _imageFile;
  final TextEditingController _descriptionController = TextEditingController();
  bool _isLoading = false;
  final StorageService _storageService = StorageService();
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    print('\n📸 Opening Add Post Screen...');
    print('ℹ️ Tap the upload button to select a photo');
  }

  @override
  void dispose() {
    print('👋 Closing Add Post Screen\n');
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectImage() async {
    print('🖼️ Opening photo gallery...');
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      print('✅ Photo selected successfully');
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    } else {
      print('ℹ️ No photo selected');
    }
  }

  void _clearImage() {
    print('🗑️ Clearing selected photo');
    setState(() {
      _imageFile = null;
    });
  }

  Future<void> _uploadPost() async {
    if (_imageFile == null) {
      print('❌ Cannot upload post: No photo selected');
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      print('❌ Cannot upload post: Caption is required');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text('Please write a caption for your post'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: EdgeInsets.all(16),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    print('📤 Uploading post...');

    try {
      final user = Provider.of<UserProvider>(context, listen: false).getUser;
      if (user == null) throw 'User not found';

      print('🖼️ Uploading photo to storage...');
      String photoUrl = await _storageService.uploadImageToStorage(
        'posts',
        _imageFile!,
      );
      print('✅ Photo uploaded successfully');

      print('📝 Creating post in database...');
      await _firestoreService.uploadPost(
        user.uid,
        user.username,
        _descriptionController.text,
        photoUrl,
        user.photoUrl,
      );
      print('✅ Post created successfully');

      setState(() {
        _imageFile = null;
        _isLoading = false;
        _descriptionController.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text('Posted successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      print('❌ Error uploading post: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text('Error posting: $e'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).getUser;

    return Scaffold(
      backgroundColor: Colors.white,
      body: _imageFile == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    padding: EdgeInsets.all(24),
                    child: IconButton(
                      icon: Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 48,
                        color: Colors.blue,
                      ),
                      onPressed: _selectImage,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Share a photo',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap to select from your gallery',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : Scaffold(
              appBar: AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _clearImage,
                ),
                title: Text(
                  'New Post',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: _isLoading ? null : _uploadPost,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue,
                      padding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: Text(
                      'Share',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _isLoading ? Colors.grey[400] : Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
              body: Column(
                children: [
                  if (_isLoading)
                    LinearProgressIndicator(
                      color: Colors.blue,
                      backgroundColor: Colors.grey[100],
                    ),
                  Divider(height: 0, color: Colors.grey[100]),
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundImage: NetworkImage(user?.photoUrl ?? ''),
                          radius: 20,
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _descriptionController,
                            decoration: InputDecoration(
                              hintText: 'Write a caption...',
                              hintStyle: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                            ),
                            maxLines: 5,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Container(
                          height: 64,
                          width: 64,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            image: DecorationImage(
                              image: FileImage(_imageFile!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 0, color: Colors.grey[100]),
                ],
              ),
            ),
    );
  }
}
