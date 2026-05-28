import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/search_provider.dart';
import '../../../auth/domain/models/app_user.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/screens/public_profile_screen.dart';
import '../../../books/data/services/google_books_service.dart';
import '../../../books/presentation/widgets/book_card.dart';
import '../../../books/presentation/screens/book_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<bool> _hasText = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _searchController.dispose();
    _hasText.dispose();
    super.dispose();
  }

  void _clearSearch(SearchProvider provider) {
    _searchController.clear();
    _hasText.value = false;
    provider.clearSearch();
  }

  void _runSearch(BuildContext context, SearchProvider provider) {
    FocusScope.of(context).unfocus();

    provider.performSearch(
      _searchController.text,
      currentUid: context.read<AuthProvider>().user?.uid,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SearchProvider>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

            return Column(
              children: [
                Flexible(
                  flex: keyboardOpen ? 0 : 1,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!keyboardOpen) ...[
                          Text(
                            'Discover',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Find books to swap or readers to follow.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 18),
                        ],
                        _SearchCard(
                          controller: _searchController,
                          hasText: _hasText,
                          provider: provider,
                          onSearch: () => _runSearch(context, provider),
                          onClear: () => _clearSearch(provider),
                        ),
                        const SizedBox(height: 14),
                        _TargetSelector(provider: provider),
                        if (provider.target == SearchTarget.books) ...[
                          const SizedBox(height: 10),
                          _BookSearchTypeSelector(provider: provider),
                        ],
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: _SearchResults(
                      key: ValueKey(
                        '${provider.target}-${provider.searchType}-${provider.isLoading}-${provider.errorMessage}-${provider.bookResults.length}-${provider.userResults.length}',
                      ),
                      provider: provider,
                      query: _searchController.text,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SearchCard extends StatelessWidget {
  final TextEditingController controller;
  final ValueNotifier<bool> hasText;
  final SearchProvider provider;
  final VoidCallback onSearch;
  final VoidCallback onClear;

  const _SearchCard({
    required this.controller,
    required this.hasText,
    required this.provider,
    required this.onSearch,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: provider.target == SearchTarget.books
                    ? 'Title, author or ISBN'
                    : 'Name or username',
                prefixIcon: Icon(
                  provider.target == SearchTarget.books
                      ? Icons.menu_book_outlined
                      : Icons.person_search_outlined,
                ),
                suffixIcon: ValueListenableBuilder<bool>(
                  valueListenable: hasText,
                  builder: (context, hasValue, child) {
                    if (!hasValue) return const SizedBox.shrink();

                    return IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: onClear,
                    );
                  },
                ),
                border: InputBorder.none,
                filled: false,
              ),
              onSubmitted: (_) => onSearch(),
              onChanged: (value) => hasText.value = value.trim().isNotEmpty,
            ),
          ),
          const SizedBox(width: 4),
          FilledButton(
            onPressed: onSearch,
            style: FilledButton.styleFrom(
              minimumSize: const Size(48, 48),
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Icon(Icons.search_rounded),
          ),
        ],
      ),
    );
  }
}

class _TargetSelector extends StatelessWidget {
  final SearchProvider provider;

  const _TargetSelector({required this.provider});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<SearchTarget>(
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      segments: const [
        ButtonSegment(
          value: SearchTarget.books,
          icon: Icon(Icons.menu_book_outlined),
          label: Text('Books'),
        ),
        ButtonSegment(
          value: SearchTarget.users,
          icon: Icon(Icons.people_outline),
          label: Text('Users'),
        ),
      ],
      selected: {provider.target},
      onSelectionChanged: (selection) {
        provider.setTarget(selection.first);
      },
    );
  }
}

class _BookSearchTypeSelector extends StatelessWidget {
  final SearchProvider provider;

  const _BookSearchTypeSelector({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        _SearchTypeChip(
          label: 'Title',
          selected: provider.searchType == SearchType.title,
          onTap: () => provider.setSearchType(SearchType.title),
        ),
        _SearchTypeChip(
          label: 'Author',
          selected: provider.searchType == SearchType.author,
          onTap: () => provider.setSearchType(SearchType.author),
        ),
        _SearchTypeChip(
          label: 'ISBN',
          selected: provider.searchType == SearchType.isbn,
          onTap: () => provider.setSearchType(SearchType.isbn),
        ),
      ],
    );
  }
}

class _SearchTypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SearchTypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
    );
  }
}

class _SearchResults extends StatelessWidget {
  final SearchProvider provider;
  final String query;

  const _SearchResults({
    super.key,
    required this.provider,
    required this.query,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            provider.errorMessage!,
            style: TextStyle(
              color: theme.colorScheme.error,
              fontSize: 15,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (provider.target == SearchTarget.users) {
      return _UserResults(users: provider.userResults, query: query);
    }

    return _BookResults(provider: provider, query: query);
  }
}

class _BookResults extends StatelessWidget {
  final SearchProvider provider;
  final String query;

  const _BookResults({
    required this.provider,
    required this.query,
  });

  @override
  Widget build(BuildContext context) {
    if (provider.bookResults.isEmpty) {
      return _EmptySearchState(
        icon: query.trim().isEmpty ? Icons.search_rounded : Icons.search_off,
        title: query.trim().isEmpty ? 'Start exploring' : 'No books found',
        message: query.trim().isEmpty
            ? 'Search by title, author or ISBN to find your next swap.'
            : 'Try a different term or search type.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 18),
      itemCount: provider.bookResults.length,
      itemBuilder: (context, index) {
        final fetchResult = provider.bookResults[index];
        final book = fetchResult.toBook();

        return BookCard(
          book: book,
          isCatalogView: true,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookDetailScreen(
                  book: book,
                  isOwner: false,
                  isCatalogView: true,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _UserResults extends StatelessWidget {
  final List<AppUser> users;
  final String query;

  const _UserResults({
    required this.users,
    required this.query,
  });

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return _EmptySearchState(
        icon: query.trim().isEmpty
            ? Icons.person_search_outlined
            : Icons.person_off_outlined,
        title: query.trim().isEmpty ? 'Find readers' : 'No users found',
        message: query.trim().isEmpty
            ? 'Search by name or username and discover people to follow.'
            : 'Try another username or display name.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      itemCount: users.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        return _UserResultCard(user: users[index]);
      },
    );
  }
}

class _UserResultCard extends StatelessWidget {
  final AppUser user;

  const _UserResultCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final displayName =
    user.displayName.isNotEmpty ? user.displayName : 'LeafMark user';
    final initial = displayName.trim().isNotEmpty
        ? displayName.trim()[0].toUpperCase()
        : '?';

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PublicProfileScreen(
              userId: user.uid,
              displayName: displayName,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: scheme.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: scheme.primaryContainer,
              foregroundColor: scheme.onPrimaryContainer,
              backgroundImage:
              user.profilePictureUrl != null && user.profilePictureUrl!.isNotEmpty
                  ? NetworkImage(user.profilePictureUrl!)
                  : null,
              child: user.profilePictureUrl == null ||
                  user.profilePictureUrl!.isEmpty
                  ? Text(
                initial,
                style: const TextStyle(fontWeight: FontWeight.bold),
              )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  if (user.username.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      '@${user.username}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  ],
                  if (user.bio != null && user.bio!.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      user.bio!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              Icons.chevron_right_rounded,
              color: scheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptySearchState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptySearchState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 56,
                      color: scheme.primary.withValues(alpha: 0.38),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}