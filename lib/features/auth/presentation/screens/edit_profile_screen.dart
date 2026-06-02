import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:leafmark/core/app_theme.dart';
import 'package:leafmark/core/cloudinary_service.dart';
import 'package:leafmark/core/leafmark_text_field.dart';
import 'package:leafmark/features/auth/presentation/providers/auth_provider.dart';
import 'package:leafmark/features/search/presentation/providers/search_provider.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/book_search_modal.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bioController = TextEditingController();
  final _picker = ImagePicker();

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

    _bioController.text = user?.bio ?? '';
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
    final pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 85,
    );

    if (pickedFile == null) return;

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: pickedFile.path,
      aspectRatio: isBanner
          ? const CropAspectRatio(ratioX: 3, ratioY: 1)
          : const CropAspectRatio(ratioX: 1, ratioY: 1),
      maxWidth: isBanner ? 1500 : 800,
      maxHeight: isBanner ? 500 : 800,
      compressQuality: 85,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: isBanner ? 'Crop banner' : 'Crop profile photo',
          toolbarColor: Theme.of(context).colorScheme.primary,
          toolbarWidgetColor: Colors.white,
          lockAspectRatio: true,
          hideBottomControls: false,
        ),
        IOSUiSettings(
          title: isBanner ? 'Crop banner' : 'Crop profile photo',
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
          doneButtonTitle: 'Done',
          cancelButtonTitle: 'Cancel',
        ),
      ],
    );

    if (croppedFile == null) return;

    setState(() {
      if (isBanner) {
        _selectedBanner = File(croppedFile.path);
        _currentBannerUrl = null;
      } else {
        _selectedImage = File(croppedFile.path);
        _currentPhotoUrl = null;
      }
    });
  }

  void _showImageOptions({required bool isBanner}) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isBanner ? 'Update banner' : 'Update profile photo',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isBanner
                      ? 'Choose and crop the area that appears behind your profile.'
                      : 'Choose and crop the photo that appears as your avatar.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.62),
                  ),
                ),
                const SizedBox(height: 14),
                _ImageOptionTile(
                  icon: Icons.photo_library_outlined,
                  title: 'Gallery',
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    _pickImage(ImageSource.gallery, isBanner: isBanner);
                  },
                ),
                const SizedBox(height: 8),
                _ImageOptionTile(
                  icon: Icons.camera_alt_outlined,
                  title: 'Camera',
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    _pickImage(ImageSource.camera, isBanner: isBanner);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveProfile() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final auth = context.read<AuthProvider>();
    final uid = auth.user!.uid;

    try {
      String? photoUrl = _currentPhotoUrl;

      if (_selectedImage != null) {
        photoUrl = await CloudinaryService.uploadImage(
          _selectedImage!,
          'leafmark/users/$uid',
        );
      }

      String? bannerUrl = _currentBannerUrl;

      if (_selectedBanner != null) {
        bannerUrl = await CloudinaryService.uploadImage(
          _selectedBanner!,
          'leafmark/users/$uid',
        );
      }

      await auth.updateProfile(
        bio: _bioController.text.trim(),
        profilePictureUrl: photoUrl,
        bannerPictureUrl: bannerUrl,
        favoriteAuthors: _favoriteAuthors,
        favoriteBookTitle: _favBookTitle,
        favoriteBookAuthor: _favBookAuthor,
        favoriteBookCoverUrl: _favBookCoverUrl,
      );

      if (!mounted) return;

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to update profile. Please try again.'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );

      setState(() => _isSaving = false);
    }
  }

  void _openSearchModal(bool isAuthor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => ChangeNotifierProvider(
        create: (_) => SearchProvider(),
        child: BookSearchModal(
          isAuthor: isAuthor,
          onSelect: (title, authors, cover) {
            setState(() {
              if (isAuthor) {
                if (!_favoriteAuthors.contains(authors) &&
                    _favoriteAuthors.length < 3) {
                  _favoriteAuthors.add(authors);
                }
              } else {
                _favBookTitle = title;
                _favBookAuthor = authors;
                _favBookCoverUrl = cover;
              }
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _ProfilePhotoEditor(
                selectedImage: _selectedImage,
                currentPhotoUrl: _currentPhotoUrl,
                selectedBanner: _selectedBanner,
                currentBannerUrl: _currentBannerUrl,
                onAvatarTap: () => _showImageOptions(isBanner: false),
                onBannerTap: () => _showImageOptions(isBanner: true),
              ),
              const SizedBox(height: 30),
              _SectionCard(
                title: 'About you',
                subtitle:
                    'Add a short bio so other readers know who they are swapping with.',
                child: LeafmarkTextField(
                  controller: _bioController,
                  label: 'Bio',
                  maxLines: 3,
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Favorite Authors',
                subtitle: 'Choose up to 3 authors to show on your profile.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_favoriteAuthors.length < 3)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _openSearchModal(true),
                          icon: const Icon(Icons.person_search_rounded),
                          label: const Text('Search author'),
                        ),
                      ),
                    if (_favoriteAuthors.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _favoriteAuthors.map((author) {
                          return Chip(
                            label: Text(author),
                            onDeleted: () {
                              setState(() => _favoriteAuthors.remove(author));
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Favorite Book',
                subtitle: 'Pick one book that represents your taste.',
                child: _favBookTitle != null
                    ? _FavoriteBookTile(
                        title: _favBookTitle!,
                        author: _favBookAuthor,
                        coverUrl: _favBookCoverUrl,
                        onEdit: () => _openSearchModal(false),
                        onRemove: () {
                          setState(() {
                            _favBookTitle = null;
                            _favBookAuthor = null;
                            _favBookCoverUrl = null;
                          });
                        },
                      )
                    : SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _openSearchModal(false),
                          icon: const Icon(Icons.search_rounded),
                          label: const Text('Search favorite book'),
                        ),
                      ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Save Changes'),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your cropped photos will be uploaded when you save.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfilePhotoEditor extends StatelessWidget {
  final File? selectedImage;
  final String? currentPhotoUrl;
  final File? selectedBanner;
  final String? currentBannerUrl;
  final VoidCallback onAvatarTap;
  final VoidCallback onBannerTap;

  const _ProfilePhotoEditor({
    required this.selectedImage,
    required this.currentPhotoUrl,
    required this.selectedBanner,
    required this.currentBannerUrl,
    required this.onAvatarTap,
    required this.onBannerTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasAvatar =
        selectedImage != null ||
        (currentPhotoUrl != null && currentPhotoUrl!.isNotEmpty);
    final hasBanner =
        selectedBanner != null ||
        (currentBannerUrl != null && currentBannerUrl!.isNotEmpty);

    return SizedBox(
      height: 178,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: GestureDetector(
              onTap: onBannerTap,
              child: Container(
                height: 128,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(24),
                  image: hasBanner
                      ? DecorationImage(
                          image: selectedBanner != null
                              ? FileImage(selectedBanner!) as ImageProvider
                              : NetworkImage(currentBannerUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: hasBanner
                        ? Colors.black.withValues(alpha: 0.08)
                        : Colors.transparent,
                  ),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: _EditBadge(
                      label: 'Edit banner',
                      icon: Icons.crop_16_9_rounded,
                      margin: const EdgeInsets.all(12),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            child: GestureDetector(
              onTap: onAvatarTap,
              child: CircleAvatar(
                radius: 52,
                backgroundColor: theme.scaffoldBackgroundColor,
                child: CircleAvatar(
                  radius: 47,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.16),
                  backgroundImage: hasAvatar
                      ? selectedImage != null
                            ? FileImage(selectedImage!) as ImageProvider
                            : NetworkImage(currentPhotoUrl!)
                      : null,
                  child: !hasAvatar
                      ? Icon(
                          Icons.camera_alt_outlined,
                          color: Theme.of(context).colorScheme.primary,
                          size: 30,
                        )
                      : null,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 7,
            right: MediaQuery.of(context).size.width / 2 - 78,
            child: GestureDetector(
              onTap: onAvatarTap,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.scaffoldBackgroundColor,
                    width: 3,
                  ),
                ),
                child: const Icon(
                  Icons.crop_square_rounded,
                  color: Colors.white,
                  size: 17,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final EdgeInsets margin;

  const _EditBadge({
    required this.label,
    required this.icon,
    required this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 15),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ImageOptionTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Icon(icon),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _FavoriteBookTile extends StatelessWidget {
  final String title;
  final String? author;
  final String? coverUrl;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  const _FavoriteBookTile({
    required this.title,
    required this.author,
    required this.coverUrl,
    required this.onEdit,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final hasCover = coverUrl != null && coverUrl!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 48,
              height: 68,
              color: Colors.grey[200],
              child: hasCover
                  ? Image.network(
                      coverUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.book, color: Colors.grey),
                    )
                  : const Icon(Icons.book, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w900),
                ),
                if (author != null && author!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    author!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: 'Change book',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Remove book',
            onPressed: onRemove,
            icon: Icon(
              Icons.delete_outline_rounded,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }
}
