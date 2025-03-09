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

  Future<void> _selectImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  void _clearImage() {
    setState(() {
      _imageFile = null;
    });
  }

  Future<void> _uploadPost() async {
    if (_imageFile == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = Provider.of<UserProvider>(context, listen: false).getUser;
      if (user == null) throw 'User not found';

      // Upload image to storage
      String photoUrl = await _storageService.uploadImageToStorage(
        'posts',
        _imageFile!,
      );

      // Create post in Firestore
      await _firestoreService.uploadPost(
        user.uid,
        user.username,
        _descriptionController.text,
        photoUrl,
        user.photoUrl,
      );

      setState(() {
        _imageFile = null;
        _isLoading = false;
        _descriptionController.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Posted successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error posting: $e')),
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

    return _imageFile == null
        ? Center(
            child: IconButton(
              icon: const Icon(Icons.upload),
              onPressed: _selectImage,
            ),
          )
        : Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _clearImage,
              ),
              title: const Text('Post to'),
              actions: [
                TextButton(
                  onPressed: _uploadPost,
                  child: const Text(
                    'Post',
                    style: TextStyle(
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            body: Column(
              children: [
                _isLoading
                    ? const LinearProgressIndicator()
                    : const Padding(padding: EdgeInsets.only(top: 0)),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundImage: NetworkImage(user?.photoUrl ?? ''),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.5,
                      child: TextField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          hintText: 'Write a caption...',
                          border: InputBorder.none,
                        ),
                        maxLines: 8,
                      ),
                    ),
                    SizedBox(
                      height: 45,
                      width: 45,
                      child: AspectRatio(
                        aspectRatio: 487 / 451,
                        child: Container(
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: FileImage(_imageFile!),
                              fit: BoxFit.fill,
                              alignment: FractionalOffset.topCenter,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(),
              ],
            ),
          );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }
}
