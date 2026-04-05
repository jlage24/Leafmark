import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/app_theme.dart';
import '../../../../core/leafmark_text_field.dart';
import '../../data/services/google_books_service.dart';
import '../../domain/models/book_fetch_result.dart';
import '../../domain/models/book.dart';
import '../providers/book_shelf_provider.dart';

/// Shown after a successful ISBN scan (or tapping "Enter manually").
/// Fetches book details, shows a pre-filled form, and lets the user save.
///
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

  // Controllers
  late final TextEditingController _isbnController;
  late final TextEditingController _titleController;
  late final TextEditingController _authorsController;
  late final TextEditingController _notesController;

  BookCondition _condition = BookCondition.good;
  BookFetchResult? _fetchResult;
  _ScreenState _state = _ScreenState.idle;
  String? _errorMessage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _googleBooksService = widget.googleBooksService ?? GoogleBooksService();

    _isbnController = TextEditingController(text: widget.isbn ?? '');
    _titleController = TextEditingController();
    _authorsController = TextEditingController();
    _notesController = TextEditingController();

    if (widget.isbn != null && widget.isbn!.isNotEmpty) {
      _fetchBookDetails(widget.isbn!);
    } else {
      setState(() => _state = _ScreenState.manual);
    }
  }

  @override
  void dispose() {
    _isbnController.dispose();
    _titleController.dispose();
    _authorsController.dispose();
    _notesController.dispose();
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
        });
      } else {
        setState(() {
          _state = _ScreenState.found;
          _fetchResult = result;
          _titleController.text = result.title;
          _authorsController.text = result.authors;
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

  Future<void> _saveBook() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final book = Book(
      id: const Uuid().v4(),
      isbn: _isbnController.text.trim(),
      title: _titleController.text.trim(),
      authors: _authorsController.text.trim(),
      coverUrl: _fetchResult?.coverUrl,
      condition: _condition,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      addedAt: DateTime.now(),
    );

    try {
      await context.read<BookShelfProvider>().addBook(book);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${book.title}" added to your shelf!'),
          backgroundColor: AppTheme.primary,
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to save book. Please try again.'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                  coverUrl: _fetchResult?.coverUrl,
                  condition: _condition,
                  onConditionChanged: (c) => setState(() => _condition = c),
                ),

              const SizedBox(height: 32),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 52,
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
                        strokeWidth: 2.5, color: Colors.white),
                  )
                      : const Text(
                    'Add to My Shelf',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
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
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9X]'))],
            validator: (v) {
              if (v == null || v.isEmpty) return 'Enter an ISBN';
              if (v.length != 10 && v.length != 13) {
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
            height: 52,
            child: FilledButton(
              onPressed: isLoading ? null : onLookup,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                foregroundColor: AppTheme.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: isLoading
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2.2, color: AppTheme.primary),
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
                  color: color, fontSize: 13, fontWeight: FontWeight.w500),
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
  final String? coverUrl;
  final BookCondition condition;
  final ValueChanged<BookCondition> onConditionChanged;

  const _BookForm({
    required this.titleController,
    required this.authorsController,
    required this.notesController,
    required this.coverUrl,
    required this.condition,
    required this.onConditionChanged,
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
                errorBuilder: (context, error, _) => const SizedBox.shrink(),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],

        LeafmarkTextField(
          controller: titleController,
          label: 'Title',
          hintText: 'The Name of the Rose',
          validator: (v) =>
          (v == null || v.isEmpty) ? 'Title is required' : null,
        ),

        const SizedBox(height: 14),

        LeafmarkTextField(
          controller: authorsController,
          label: 'Author(s)',
          hintText: 'Umberto Eco',
          validator: (v) =>
          (v == null || v.isEmpty) ? 'Author is required' : null,
        ),

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

class _ConditionPicker extends StatelessWidget {
  final BookCondition selected;
  final ValueChanged<BookCondition> onChanged;

  const _ConditionPicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: BookCondition.values.map((c) {
        final isSelected = c == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(c),
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
                  color: isSelected
                      ? AppTheme.primary
                      : Colors.transparent,
                ),
              ),
              child: Text(
                c.label,
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