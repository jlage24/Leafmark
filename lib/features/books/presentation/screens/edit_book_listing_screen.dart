import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../core/app_theme.dart';
import '../../../../core/cloudinary_service.dart';
import '../../../../core/leafmark_text_field.dart';
import '../../domain/models/book.dart';
import '../providers/book_shelf_provider.dart';

class EditBookListingScreen extends StatefulWidget {
  final Book book;

  const EditBookListingScreen({super.key, required this.book});

  @override
  State<EditBookListingScreen> createState() => _EditBookListingScreenState();
}

class _EditBookListingScreenState extends State<EditBookListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  late final TextEditingController _locationController;
  late final TextEditingController _notesController;

  late BookCondition _condition;
  late List<String> _photoUrls;

  String? _selectedCategory;
  bool _isSaving = false;
  bool _isPickingPhoto = false;

  @override
  void initState() {
    super.initState();

    _condition = widget.book.condition;
    _selectedCategory = widget.book.category;
    _photoUrls = List<String>.from(widget.book.conditionPhotoUrls);

    _locationController = TextEditingController(
      text: widget.book.location ?? '',
    );
    _notesController = TextEditingController(text: widget.book.notes ?? '');
  }

  @override
  void dispose() {
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _addPhoto() async {
    if (_photoUrls.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can only add up to 3 photos.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
        maxWidth: 1000,
      );

      if (image == null) return;

      setState(() => _isPickingPhoto = true);

      final url = await CloudinaryService.uploadImage(
        File(image.path),
        'leafmark_books/${widget.book.id}',
      );

      if (url == null) {
        throw Exception('PhotoUploadFailure');
      }

      if (!mounted) return;

      setState(() {
        _photoUrls.add(url);
      });
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to upload photo. Please try again.'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isPickingPhoto = false);
      }
    }
  }

  void _removePhoto(String url) {
    setState(() {
      _photoUrls.remove(url);
    });
  }

  Future<void> _save() async {
    if (_isSaving || _isPickingPhoto) return;
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final updatedBook = Book(
      id: widget.book.id,
      isbn: widget.book.isbn,
      title: widget.book.title,
      authors: widget.book.authors,
      coverUrl: widget.book.coverUrl,
      condition: _condition,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      addedAt: widget.book.addedAt,
      ownerName: widget.book.ownerName,
      ownerId: widget.book.ownerId,
      lockedBySwapId: widget.book.lockedBySwapId,
      conditionPhotoUrls: _photoUrls,
      category: _selectedCategory,
      location: _locationController.text.trim(),
      lastExchangeId: widget.book.lastExchangeId,
    );

    try {
      await context.read<BookShelfProvider>().updateBook(updatedBook);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Listing updated.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );

      Navigator.pop(context, updatedBook);
    } catch (e) {
      if (!mounted) return;

      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayUrl = _photoUrls.isNotEmpty
        ? _photoUrls.first
        : widget.book.coverUrl;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit listing'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _BookSummaryCard(
                title: widget.book.title,
                authors: widget.book.authors,
                imageUrl: displayUrl,
              ),
              const SizedBox(height: 18),
              _SectionCard(
                title: 'Condition photos',
                subtitle:
                    'Add up to 3 real photos so other readers can judge the condition.',
                child: _PhotoEditor(
                  photoUrls: _photoUrls,
                  isUploading: _isPickingPhoto,
                  onAddPhoto: _addPhoto,
                  onRemovePhoto: _removePhoto,
                ),
              ),
              const SizedBox(height: 18),
              _SectionCard(
                title: 'Listing details',
                subtitle: 'Update how this book appears to other readers.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CategoryDropdown(
                      selectedCategory: _selectedCategory,
                      onChanged: (category) {
                        setState(() => _selectedCategory = category);
                      },
                    ),
                    const SizedBox(height: 16),
                    LeafmarkTextField(
                      controller: _locationController,
                      label: 'Location',
                      hintText: 'e.g. Porto, FEUP',
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Location is required'
                          : null,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Condition',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _ConditionPicker(
                      selected: _condition,
                      onChanged: (condition) {
                        setState(() => _condition = condition);
                      },
                    ),
                    const SizedBox(height: 18),
                    LeafmarkTextField(
                      controller: _notesController,
                      label: 'Notes',
                      hintText: 'Minor pencil marks, damaged cover...',
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving || _isPickingPhoto ? null : _save,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoEditor extends StatelessWidget {
  final List<String> photoUrls;
  final bool isUploading;
  final VoidCallback onAddPhoto;
  final ValueChanged<String> onRemovePhoto;

  const _PhotoEditor({
    required this.photoUrls,
    required this.isUploading,
    required this.onAddPhoto,
    required this.onRemovePhoto,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (photoUrls.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _EmptyPhotosHint(onAddPhoto: onAddPhoto),
          if (isUploading) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ...photoUrls.map(
              (url) => Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      url,
                      width: 92,
                      height: 124,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 92,
                          height: 124,
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.08,
                          ),
                          child: Icon(
                            Icons.menu_book_rounded,
                            color: theme.colorScheme.primary,
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () => onRemovePhoto(url),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.58),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 17,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (photoUrls.length < 3)
              _AddPhotoTile(isUploading: isUploading, onTap: onAddPhoto),
          ],
        ),
        if (isUploading) ...[
          const SizedBox(height: 12),
          const LinearProgressIndicator(),
        ],
      ],
    );
  }
}

class _EmptyPhotosHint extends StatelessWidget {
  final VoidCallback onAddPhoto;

  const _EmptyPhotosHint({required this.onAddPhoto});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onAddPhoto,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.18),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.add_a_photo_outlined, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Add real photos of the book condition.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  final bool isUploading;
  final VoidCallback onTap;

  const _AddPhotoTile({required this.isUploading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: isUploading ? null : onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 92,
        height: 124,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.5,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.25),
          ),
        ),
        child: isUploading
            ? const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _BookSummaryCard extends StatelessWidget {
  final String title;
  final String authors;
  final String? imageUrl;

  const _BookSummaryCard({
    required this.title,
    required this.authors,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
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
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 64,
              height: 92,
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              child: hasImage
                  ? Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.menu_book_rounded),
                    )
                  : const Icon(Icons.menu_book_rounded),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  authors,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
                  ),
                ),
              ],
            ),
          ),
        ],
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
              color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  final String? selectedCategory;
  final ValueChanged<String?> onChanged;

  const _CategoryDropdown({
    required this.selectedCategory,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DropdownButtonFormField<String>(
      initialValue: selectedCategory,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Category',
        prefixIcon: const Icon(Icons.auto_stories_outlined),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dropdownColor: theme.colorScheme.surface,
      items: bookCategories.map((category) {
        return DropdownMenuItem(value: category, child: Text(category));
      }).toList(),
      onChanged: onChanged,
      validator: (value) => value == null ? 'Category is required' : null,
    );
  }
}

class _ConditionPicker extends StatelessWidget {
  final BookCondition selected;
  final ValueChanged<BookCondition> onChanged;

  const _ConditionPicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: BookCondition.values.map((condition) {
        final isSelected = condition == selected;

        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(condition),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.primary.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : Colors.transparent,
                ),
              ),
              child: Text(
                condition.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : theme.colorScheme.primary,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
