import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:leafmark/features/auth/presentation/providers/auth_provider.dart';
import 'package:leafmark/features/search/presentation/providers/search_provider.dart';
import 'package:leafmark/features/books/data/services/google_books_service.dart';
import 'package:leafmark/core/app_theme.dart';
import 'package:leafmark/core/leafmark_text_field.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _bioController;

  List<String> _favoriteAuthors = [];
  bool _isSaving = false;

  File? _selectedImage;
  String? _currentPhotoUrl;
  File? _selectedBanner;
  String? _currentBannerUrl;

  String? _favBookTitle;
  String? _favBookAuthor;
  String? _favBookCoverUrl;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _bioController = TextEditingController(text: user?.bio ?? '');
    _currentPhotoUrl = user?.profilePictureUrl;
    _currentBannerUrl = user?.bannerPictureUrl;
    _favBookTitle = user?.favoriteBookTitle;
    _favBookAuthor = user?.favoriteBookAuthor;
    _favBookCoverUrl = user?.favoriteBookCoverUrl;
    if (user?.favoriteAuthors != null) {
      _favoriteAuthors = List<String>.from(user!.favoriteAuthors);
    }
  }

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source, {required bool isBanner}) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        if (isBanner) {
          _selectedBanner = File(pickedFile.path);
          _currentBannerUrl = null;
        } else {
          _selectedImage = File(pickedFile.path);
          _currentPhotoUrl = null;
        }
      });
    }
  }

  void _showImageOptions({required bool isBanner}) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () { Navigator.pop(ctx); _pickImage(ImageSource.gallery, isBanner: isBanner); },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () { Navigator.pop(ctx); _pickImage(ImageSource.camera, isBanner: isBanner); },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final auth = context.read<AuthProvider>();

    String? photoUrl = _currentPhotoUrl;
    if (_selectedImage != null) {
      final ref = FirebaseStorage.instance.ref().child('users/${auth.user!.uid}/profile.jpg');
      await ref.putFile(_selectedImage!);
      photoUrl = await ref.getDownloadURL();
    }

    String? bannerUrl = _currentBannerUrl;
    if (_selectedBanner != null) {
      final ref = FirebaseStorage.instance.ref().child('users/${auth.user!.uid}/banner.jpg');
      await ref.putFile(_selectedBanner!);
      bannerUrl = await ref.getDownloadURL();
    }

    await auth.updateProfile(
      bio: _bioController.text,
      profilePictureUrl: photoUrl,
      bannerPictureUrl: bannerUrl,
      favoriteAuthors: _favoriteAuthors,
      favoriteBookTitle: _favBookTitle,
      favoriteBookAuthor: _favBookAuthor,
      favoriteBookCoverUrl: _favBookCoverUrl,
    );
    if (mounted) Navigator.pop(context);
  }

  void _openSearchModal(bool isAuthor) {
    final searchProvider = context.read<SearchProvider>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return ChangeNotifierProvider.value(
          value: searchProvider,
          child: _SearchModal(
            isAuthor: isAuthor,
            onSelect: (title, author, cover) {
              setState(() {
                if (isAuthor) {
                  if (!_favoriteAuthors.contains(author)) _favoriteAuthors.add(author);
                } else {
                  _favBookTitle = title;
                  _favBookAuthor = author;
                  _favBookCoverUrl = cover;
                }
              });
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 160,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    GestureDetector(
                      onTap: () => _showImageOptions(isBanner: true),
                      child: Container(
                        height: 120, width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppTheme.primary, borderRadius: BorderRadius.circular(16),
                          image: _selectedBanner != null
                              ? DecorationImage(image: FileImage(_selectedBanner!), fit: BoxFit.cover)
                              : (_currentBannerUrl != null ? DecorationImage(image: NetworkImage(_currentBannerUrl!), fit: BoxFit.cover) : null),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      child: GestureDetector(
                        onTap: () => _showImageOptions(isBanner: false),
                        child: CircleAvatar(
                          radius: 46, backgroundColor: AppTheme.background,
                          child: CircleAvatar(
                            radius: 42, backgroundColor: AppTheme.primaryLight,
                            backgroundImage: _selectedImage != null ? FileImage(_selectedImage!) : (_currentPhotoUrl != null ? NetworkImage(_currentPhotoUrl!) : null),
                            child: _selectedImage == null && _currentPhotoUrl == null ? const Icon(Icons.camera_alt) : null,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              LeafmarkTextField(controller: _bioController, label: 'Bio', maxLines: 3),
              const SizedBox(height: 24),

              Text('Favorite Authors (Top 3)', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              if (_favoriteAuthors.length < 3)
                OutlinedButton.icon(
                  onPressed: () => _openSearchModal(true),
                  icon: const Icon(Icons.person_search),
                  label: const Text('Search Author'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                ),
              Wrap(
                spacing: 8,
                children: _favoriteAuthors.map((a) => Chip(
                  label: Text(a),
                  onDeleted: () => setState(() => _favoriteAuthors.remove(a)),
                )).toList(),
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              Text('Favorite Book', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),

              if (_favBookTitle != null)
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: _favBookCoverUrl != null
                          ? Image.network(
                        _favBookCoverUrl!,
                        width: 40,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.book, size: 40),
                      )
                          : const Icon(Icons.book, size: 40),
                    ),
                    title: Text(_favBookTitle!, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(_favBookAuthor ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => _openSearchModal(false),
                    ),
                  ),
                )
              else
                OutlinedButton.icon(
                  onPressed: () => _openSearchModal(false),
                  icon: const Icon(Icons.search),
                  label: const Text('Search Favorite Book'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                ),

              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  child: _isSaving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchModal extends StatefulWidget {
  final bool isAuthor;
  final Function(String, String, String?) onSelect;
  const _SearchModal({required this.isAuthor, required this.onSelect});

  @override
  State<_SearchModal> createState() => _SearchModalState();
}

class _SearchModalState extends State<_SearchModal> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final p = context.read<SearchProvider>();
      p.clearSearch();
      // Define estritamente o tipo de pesquisa inicial
      p.setSearchType(widget.isAuthor ? SearchType.author : SearchType.title);
    });
  }

  void _handleSearch(SearchProvider provider) {
    final query = _controller.text.trim();
    if (query.isNotEmpty) {
      // Garante a 100% que não pesquisa por ISBN aqui
      provider.setSearchType(widget.isAuthor ? SearchType.author : SearchType.title);
      provider.performSearch(query);
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SearchProvider>();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                // Textos atualizados conforme o teu pedido
                hintText: widget.isAuthor ? 'Search by author name...' : 'Search by book title...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: () => _handleSearch(provider),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onSubmitted: (_) => _handleSearch(provider),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.errorMessage != null
                  ? Center(
                child: Text(
                  provider.errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              )
                  : provider.results.isEmpty
                  ? Center(
                child: Text(
                  _controller.text.isEmpty ? 'Type to search' : 'No results found',
                  style: const TextStyle(color: Colors.grey),
                ),
              )
                  : ListView.builder(
                itemCount: provider.results.length,
                itemBuilder: (ctx, i) {
                  final b = provider.results[i];
                  return ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: b.coverUrl != null
                          ? Image.network(
                        b.coverUrl!, width: 40, height: 60, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.book, size: 40),
                      )
                          : const Icon(Icons.book, size: 40),
                    ),
                    title: Text(widget.isAuthor ? b.authors : b.title,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(widget.isAuthor ? 'Known for: ${b.title}' : b.authors),
                    onTap: () {
                      widget.onSelect(b.title, b.authors, b.coverUrl);
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}