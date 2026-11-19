import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:card_design/viewmodel/create_post_viewmodel.dart';
import 'package:card_design/viewmodel/login_viewmodel.dart';
import 'package:card_design/viewmodel/post_viewmodel.dart';

class CreatePostView extends StatefulWidget {
  const CreatePostView({super.key});

  @override
  State<CreatePostView> createState() => _CreatePostViewState();
}

class _CreatePostViewState extends State<CreatePostView> {
  final TextEditingController _captionController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;

  // Memilih gambar dari galeri HP atau browser
  Future<void> _pickImage() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 80,
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImage = image;
        _selectedImageBytes = bytes;
      });
    }
  }

  // Mengirim postingan ke backend.
  Future<void> _submitPost() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih gambar terlebih dahulu')),
      );
      return;
    }

    final viewModel = context.read<CreatePostViewModel>();
    final postViewModel = context.read<PostViewModel>();
    final userId = context.read<LoginViewModel>().activeUserId;
    final captionText = _captionController.text.trim();

    final success = await viewModel.createPost(
      userId: userId,
      fileBytes: _selectedImageBytes,
      filename: _selectedImage!.name,
      imagePath: _selectedImage!.path,
      caption: captionText,
    );

    if (!mounted) return;

    if (!success && _selectedImageBytes != null) {
      // Tambahkan secara lokal jika server backend belum berjalan
      final base64Image =
          'data:image/jpeg;base64,${base64Encode(_selectedImageBytes!)}';
      postViewModel.addLocalPost(
        userId: userId,
        caption: captionText,
        imageUrl: base64Image,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Postingan berhasil dibuat!')),
      );
      _captionController.clear();
      setState(() {
        _selectedImage = null;
        _selectedImageBytes = null;
      });
      Navigator.pop(context, true);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Postingan berhasil dibuat'
              : viewModel.errorMessage ?? 'Upload gagal',
        ),
      ),
    );

    if (success) {
      _captionController.clear();
      setState(() {
        _selectedImage = null;
        _selectedImageBytes = null;
      });
      Navigator.pop(context, true);
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CreatePostViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Buat Postingan')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Area pratinjau gambar (Universal untuk Web & Mobile via Image.memory)
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _selectedImageBytes == null
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined, size: 48, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('Ketuk untuk memilih gambar', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          _selectedImageBytes!,
                          fit: BoxFit.contain,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Kolom caption.
            TextField(
              controller: _captionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Caption',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Tombol upload.
            ElevatedButton(
              onPressed: viewModel.isLoading ? null : _submitPost,
              child: viewModel.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Unggah Postingan'),
            ),
          ],
        ),
      ),
    );
  }
}
