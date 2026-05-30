import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/app_theme.dart';
import '../../../../core/cloudinary_service.dart';
import '../../../../core/leafmark_text_field.dart';
import '../../data/services/google_books_service.dart';
import '../../domain/models/book.dart';
import '../../domain/models/book_fetch_result.dart';
import '../providers/book_shelf_provider.dart';

class AddBookScreen extends StatefulWidget {
  final String? isbn;
  final GoogleBooksService? googleBooksService;

  const AddBookScreen({
    super.key,
    required this.isbn,
    this.googleBooksService,
  });

  @override
  State<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen> {
  final _formKey = GlobalKey<FormState>();
  late final GoogleBooksService _googleBooksService;
  final ImagePicker _picker = ImagePicker();

  late final TextEditingController _isbnController;
  late final TextEditingController _titleController;
  late final TextEditingController _authorsController;
  late final TextEditingController _notesController;
  late final TextEditingController _locationController;

  BookCondition _condition = BookCondition.good;
  String? _selectedCategory;

  BookFetchResult? _fetchResult;
  _ScreenState _state = _ScreenState.idle;
  String? _errorMessage;
  bool _isSaving = false;

  bool _isDetectingLocation = false;
  bool _locationWasAutoDetected = false;
  bool _showCategoryDropdown = false;
  String? _locationMessage;

  final List<File> _selectedPhotos = [];

  @override
  void initState() {
    super.initState();

    _googleBooksService = widget.googleBooksService ?? GoogleBooksService();

    _isbnController = TextEditingController(text: widget.isbn ?? '');
    _titleController = TextEditingController();
    _authorsController = TextEditingController();
    _notesController = TextEditingController();
    _locationController = TextEditingController();

    if (widget.isbn != null && widget.isbn!.isNotEmpty) {
      _fetchBookDetails(widget.isbn!);
    } else {
      setState(() => _state = _ScreenState.manual);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _detectLocation();
    });
  }

  @override
  void dispose() {
    _isbnController.dispose();
    _titleController.dispose();
    _authorsController.dispose();
    _notesController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _fetchBookDetails(String isbn) async {
    setState(() {
      _state = _ScreenState.loading;
      _errorMessage = null;
    });

    try {
      final result = await _googleBooksService.fetchByIsbn(isbn);

      if (!mounted) return;

      if (result == null) {
        setState(() {
          _state = _ScreenState.notFound;
          _fetchResult = BookFetchResult.empty(isbn);
          _titleController.clear();
          _authorsController.clear();
          _selectedCategory = null;
          _showCategoryDropdown = true;
        });
      } else {
        setState(() {
          _state = _ScreenState.found;
          _fetchResult = result;
          _titleController.text = result.title;
          _authorsController.text = result.authors;
          _selectedCategory = result.category;
          _showCategoryDropdown = result.category == null;
        });
      }
    } on BookFetchException catch (e) {
      if (!mounted) return;

      setState(() {
        _state = _ScreenState.error;
        _errorMessage = e.message;
      });
    }
  }

  Future<void> _detectLocation() async {
    if (_isDetectingLocation) return;

    setState(() {
      _isDetectingLocation = true;
      _locationMessage = 'Detecting your location...';
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        setState(() {
          _locationMessage = 'Location services are off. You can type it manually.';
          _locationWasAutoDetected = false;
        });
        return;
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        setState(() {
          _locationMessage = 'Location permission denied. You can type it manually.';
          _locationWasAutoDetected = false;
        });
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationMessage = 'Location permission permanently denied. You can type it manually.';
          _locationWasAutoDetected = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
        ),
      );

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      final place = placemarks.isNotEmpty ? placemarks.first : null;
      final detectedLocation = _formatLocation(place);

      if (detectedLocation == null || detectedLocation.isEmpty) {
        setState(() {
          _locationMessage = 'Could not detect a useful location. You can type it manually.';
          _locationWasAutoDetected = false;
        });
        return;
      }

      setState(() {
        _locationController.text = detectedLocation;
        _locationWasAutoDetected = true;
        _locationMessage = 'Detected automatically. You can still edit it.';
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _locationMessage = 'Could not detect location. You can type it manually.';
        _locationWasAutoDetected = false;
      });
    } finally {
      if (mounted) {
        setState(() => _isDetectingLocation = false);
      }
    }
  }

  String? _formatLocation(Placemark? place) {
    if (place == null) return null;

    final candidates = [
      place.locality,
      place.subAdministrativeArea,
      place.administrativeArea,
    ];

    for (final candidate in candidates) {
      final value = candidate?.trim();

      if (value != null && value.isNotEmpty) {
        return value;
      }
    }

    return null;
  }

  Future<void> _pickPhotos() async {
    if (_selectedPhotos.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can only add up to 3 photos.')),
      );
      return;
    }

    try {
      final images = await _picker.pickMultiImage(
        imageQuality: 70,
        maxWidth: 1000,
      );

      if (images.isNotEmpty) {
        setState(() {
          final remainingSlots = 3 - _selectedPhotos.length;
          final photosToAdd = images
              .take(remainingSlots)
              .map((image) => File(image.path))
              .toList();

          _selectedPhotos.addAll(photosToAdd);
        });
      }
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to pick images.')),
      );
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _selectedPhotos.removeAt(index);
    });
  }

  Future<void> _saveBook() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final uploadedUrls = <String>[];
    final bookId = const Uuid().v4();

    try {
      for (final photo in _selectedPhotos) {
        final url = await CloudinaryService.uploadImage(
          photo,
          'leafmark_books/$bookId',
        );

        if (url == null) {
          throw Exception('PhotoUploadFailure');
        }

        uploadedUrls.add(url);
      }

      final book = Book(
        id: bookId,
        isbn: _isbnController.text.trim(),
        title: _titleController.text.trim(),
        authors: _authorsController.text.trim(),
        coverUrl: _fetchResult?.coverUrl,
        condition: _condition,
        category: _selectedCategory,
        location: _locationController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        addedAt: DateTime.now(),
        conditionPhotoUrls: uploadedUrls,
      );

      if (!mounted) return;

      await context.read<BookShelfProvider>().addBook(book);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${book.title}" added to your shelf!'),
          backgroundColor: AppTheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;

      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to save book. Please try again.'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Add Book'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _IsbnInputRow(
                controller: _isbnController,
                isLoading: _state == _ScreenState.loading,
                onLookup: () {
                  final isbn = _isbnController.text.trim();
                  if (isbn.isNotEmpty) _fetchBookDetails(isbn);
                },
              ),
              const SizedBox(height: 20),
              if (_state == _ScreenState.loading)
                const _StatusBanner(
                  icon: Icons.search_rounded,
                  message: 'Looking up book details…',
                  color: Colors.blue,
                ),
              if (_state == _ScreenState.notFound)
                const _StatusBanner(
                  icon: Icons.info_outline_rounded,
                  message: 'Book not found — fill in the details manually.',
                  color: Colors.orange,
                ),
              if (_state == _ScreenState.error)
                _StatusBanner(
                  icon: Icons.error_outline_rounded,
                  message: _errorMessage ?? 'Unknown error',
                  color: Colors.red,
                ),
              if (_state == _ScreenState.found ||
                  _state == _ScreenState.notFound ||
                  _state == _ScreenState.manual)
                _BookForm(
                  titleController: _titleController,
                  authorsController: _authorsController,
                  notesController: _notesController,
                  locationController: _locationController,
                  coverUrl: _fetchResult?.coverUrl,
                  condition: _condition,
                  onConditionChanged: (condition) {
                    setState(() => _condition = condition);
                  },
                  selectedPhotos: _selectedPhotos,
                  onPickPhotos: _pickPhotos,
                  onRemovePhoto: _removePhoto,
                  categories: bookCategories,
                  selectedCategory: _selectedCategory,
                  onCategoryChanged: (category) {
                    setState(() => _selectedCategory = category);
                  },
                  detectedCategory: _fetchResult?.category,

                  showCategoryDropdown: _showCategoryDropdown,
                  onChangeCategoryPressed: () {
                    setState(() {
                      _showCategoryDropdown = true;
                    });
                  },

                  isDetectingLocation: _isDetectingLocation,
                  locationWasAutoDetected: _locationWasAutoDetected,
                  locationMessage: _locationMessage,
                  onDetectLocation: _detectLocation,
                ),
              const SizedBox(height: 32),
              ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: double.infinity,
                  maxHeight: 52,
                  minHeight: 52,
                ),
                child: FilledButton(
                  onPressed: (_state == _ScreenState.loading || _isSaving)
                      ? null
                      : _saveBook,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    'Add to My Shelf',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _IsbnInputRow extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onLookup;

  const _IsbnInputRow({
    required this.controller,
    required this.isLoading,
    required this.onLookup,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: LeafmarkTextField(
            controller: controller,
            label: 'ISBN',
            hintText: '9780140449136',
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9X]')),
            ],
            validator: (value) {
              final isbn = value?.trim() ?? '';

              if (isbn.isEmpty) return 'Enter an ISBN';

              if (isbn.length != 10 && isbn.length != 13) {
                return 'ISBN must be 10 or 13 digits';
              }

              return null;
            },
          ),
        ),
        const SizedBox(width: 10),
        Padding(
          padding: const EdgeInsets.only(top: 24),
          child: SizedBox(
            width: 52,
            height: 52,
            child: FilledButton(
              onPressed: isLoading ? null : onLookup,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                foregroundColor: AppTheme.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: AppTheme.primary,
                ),
              )
                  : const Icon(Icons.search_rounded),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color color;

  const _StatusBanner({
    required this.icon,
    required this.message,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookForm extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController authorsController;
  final TextEditingController notesController;
  final TextEditingController locationController;
  final String? coverUrl;
  final BookCondition condition;
  final ValueChanged<BookCondition> onConditionChanged;
  final List<File> selectedPhotos;
  final VoidCallback onPickPhotos;
  final Function(int) onRemovePhoto;
  final List<String> categories;
  final String? selectedCategory;
  final ValueChanged<String?> onCategoryChanged;
  final String? detectedCategory;
  final bool showCategoryDropdown;
  final VoidCallback onChangeCategoryPressed;
  final bool isDetectingLocation;
  final bool locationWasAutoDetected;
  final String? locationMessage;
  final VoidCallback onDetectLocation;

  const _BookForm({
    required this.titleController,
    required this.authorsController,
    required this.notesController,
    required this.locationController,
    required this.coverUrl,
    required this.condition,
    required this.onConditionChanged,
    required this.selectedPhotos,
    required this.onPickPhotos,
    required this.onRemovePhoto,
    required this.categories,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.detectedCategory,
    required this.showCategoryDropdown,
    required this.onChangeCategoryPressed,
    required this.isDetectingLocation,
    required this.locationWasAutoDetected,
    required this.locationMessage,
    required this.onDetectLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (coverUrl != null) ...[
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                coverUrl!,
                height: 140,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                const SizedBox.shrink(),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
        LeafmarkTextField(
          controller: titleController,
          label: 'Title',
          hintText: 'The Name of the Rose',
          validator: (value) =>
          value == null || value.trim().isEmpty ? 'Title is required' : null,
        ),
        const SizedBox(height: 14),
        LeafmarkTextField(
          controller: authorsController,
          label: 'Author(s)',
          hintText: 'Umberto Eco',
          validator: (value) =>
          value == null || value.trim().isEmpty ? 'Author is required' : null,
        ),
        const SizedBox(height: 14),
        _CategorySelector(
          categories: categories,
          selectedCategory: selectedCategory,
          detectedCategory: detectedCategory,
          showDropdown: showCategoryDropdown,
          onCategoryChanged: onCategoryChanged,
          onChangePressed: onChangeCategoryPressed,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: locationController,
          decoration: InputDecoration(
            labelText: 'Location (City or Campus)',
            hintText: 'e.g. FEUP, Porto',
            suffixIcon: isDetectingLocation
                ? const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
                : IconButton(
              tooltip: 'Detect location',
              onPressed: onDetectLocation,
              icon: const Icon(Icons.my_location_rounded),
            ),
          ),
          validator: (value) =>
          value == null || value.trim().isEmpty ? 'Location is required' : null,
        ),
        if (locationMessage != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                locationWasAutoDetected
                    ? Icons.check_circle_outline_rounded
                    : Icons.info_outline_rounded,
                size: 15,
                color: locationWasAutoDetected
                    ? Colors.green.shade700
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  locationMessage!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: locationWasAutoDetected
                        ? Colors.green.shade700
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: locationWasAutoDetected
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 20),
        Text(
          'Condition',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        _ConditionPicker(
          selected: condition,
          onChanged: onConditionChanged,
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Real Photos (${selectedPhotos.length}/3)',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            if (selectedPhotos.length < 3)
              TextButton.icon(
                onPressed: onPickPhotos,
                icon: const Icon(Icons.add_a_photo, size: 16),
                label: const Text('Add'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (selectedPhotos.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.photo_library_outlined,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Show others the real condition of your book to build trust.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: selectedPhotos.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          selectedPhotos[index],
                          height: 100,
                          width: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: -8,
                        right: -8,
                        child: IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                          onPressed: () => onRemovePhoto(index),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 20),
        LeafmarkTextField(
          controller: notesController,
          label: 'Notes (optional)',
          hintText: 'Minor pencil marks on page 42…',
          maxLines: 3,
        ),
      ],
    );
  }
}

class _CategorySelector extends StatelessWidget {
  final List<String> categories;
  final String? selectedCategory;
  final String? detectedCategory;
  final bool showDropdown;
  final ValueChanged<String?> onCategoryChanged;
  final VoidCallback onChangePressed;

  const _CategorySelector({
    required this.categories,
    required this.selectedCategory,
    required this.detectedCategory,
    required this.showDropdown,
    required this.onCategoryChanged,
    required this.onChangePressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasDetectedCategory =
        detectedCategory != null && selectedCategory == detectedCategory;

    if (hasDetectedCategory && !showDropdown) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.22),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Detected category',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    selectedCategory!,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: onChangePressed,
              child: const Text('Change'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border.all(color: AppTheme.divider),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedCategory,
              hint: const Text('Select a category'),
              isExpanded: true,
              dropdownColor: theme.colorScheme.surface,
              items: categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: onCategoryChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class _ConditionPicker extends StatelessWidget {
  final BookCondition selected;
  final ValueChanged<BookCondition> onChanged;

  const _ConditionPicker({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: BookCondition.values.map((condition) {
        final isSelected = condition == selected;

        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(condition),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primary
                    : AppTheme.primary.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? AppTheme.primary : Colors.transparent,
                ),
              ),
              child: Text(
                condition.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppTheme.primary,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

enum _ScreenState { idle, manual, loading, found, notFound, error }