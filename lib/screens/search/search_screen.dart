import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/palette.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/search_service.dart';
import '../../widgets/notification_button.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final SearchService _searchService = SearchService();

  bool _isLoading = false;
  bool _hasSearched = false;
  String? _error;
  List<dynamic> _coaches = [];
  List<dynamic> _sessions = [];

  @override
  void initState() {
    super.initState();
    _loadInitialSuggestions();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    // Update UI to show/hide clear button
    setState(() {});
  }

  Future<void> _loadInitialSuggestions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Use searchAll with empty query to get recommended coaches and upcoming sessions
      final result = await _searchService.searchAll(query: '', limit: 5);
      if (mounted) {
        setState(() {
          _coaches = result['data']['coaches'] ?? [];
          _sessions = result['data']['sessions'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _hasSearched = false;
        _sessions = [];
      });

      _loadInitialSuggestions();
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _error = null;
    });

    try {
      final result = await _searchService.searchAll(query: query, limit: 10);
      if (mounted) {
        setState(() {
          _coaches = result['data']['coaches'] ?? [];
          _sessions = result['data']['sessions'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header and Search Bar - Fixed at top
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Search',
                        style: GoogleFonts.inter(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ).animate().fadeIn().slideX(begin: -0.1),
                      NotificationButton(
                        iconColor: Theme.of(context).colorScheme.onSurface,
                        backgroundColor:
                            Theme.of(context).scaffoldBackgroundColor,
                        onTap: () {
                          final isGuardian = GoRouterState.of(context)
                              .uri
                              .toString()
                              .startsWith('/guardian');
                          context.push(
                            isGuardian
                                ? '/guardian/notifications'
                                : '/player/notifications',
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Theme.of(context).dividerColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      autofocus: false,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      onSubmitted: _performSearch,
                      onChanged: (value) {
                        // Debounce search
                        if (value.isEmpty) {
                          _performSearch(value);
                        }
                      },
                      decoration: InputDecoration(
                        hintText: 'Search for coaches, sessions...',
                        hintStyle: GoogleFonts.inter(
                          color: Theme.of(context).hintColor,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppPalette.orangeAccent,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  color: Theme.of(context).iconTheme.color,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  _performSearch('');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                ],
              ),
            ),

            // Results - Scrollable
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Failed to load results',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () {
                                  if (_hasSearched) {
                                    _performSearch(_searchController.text);
                                  } else {
                                    _loadInitialSuggestions();
                                  }
                                },
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Coaches Section
                              if (_coaches.isNotEmpty) ...[
                                Text(
                                  _hasSearched
                                      ? 'Coaches (${_coaches.length})'
                                      : 'Recommended Coaches',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                ).animate().fadeIn(delay: 300.ms),
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 160,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _coaches.length,
                                    separatorBuilder: (context, index) =>
                                        const SizedBox(width: 16),
                                    itemBuilder: (context, index) {
                                      final coach = _coaches[index];
                                      final user = coach['userId'];
                                      return _CoachCard(
                                        name: user?['fullName'] ?? 'Unknown',
                                        role:
                                            (coach['specializations'] as List?)
                                                    ?.join(', ') ??
                                                'Coach',
                                        rating: coach['ratings']?['overall']
                                                ?.toStringAsFixed(1) ??
                                            '0.0',
                                        imageUrl: user?['profilePhoto'] ??
                                            coach['profilePhoto'] ??
                                            coach['profileImage'] ??
                                            'https://ui-avatars.com/api/?name=${Uri.encodeComponent(user?['fullName'] ?? 'Unknown')}&background=random',
                                        onTap: () {
                                          // Navigate to coach details based on current tree
                                          final isGuardian = GoRouterState.of(
                                            context,
                                          )
                                              .uri
                                              .toString()
                                              .startsWith('/guardian');
                                          if (isGuardian) {
                                            context.push(
                                              '/guardian/coach-details/${coach['_id']}',
                                            );
                                          } else {
                                            context.push(
                                              '/coach-details/${coach['_id']}',
                                            );
                                          }
                                        },
                                      );
                                    },
                                  ),
                                ).animate().fadeIn(delay: 400.ms).slideX(),
                                const SizedBox(height: 32),
                              ],

                              // Sessions Section
                              if (_sessions.isNotEmpty) ...[
                                Text(
                                  'Sessions (${_sessions.length})',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                ).animate().fadeIn(delay: 500.ms),
                                const SizedBox(height: 16),
                                Column(
                                  children: _sessions.map((session) {
                                    final timeSlots =
                                        session['timeSlots'] as List?;
                                    final firstSlot =
                                        timeSlots?.isNotEmpty == true
                                            ? timeSlots!.first
                                            : null;
                                    final startTime = firstSlot != null
                                        ? DateTime.parse(firstSlot['startTime'])
                                        : null;

                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 12),
                                      child: _SearchResultItem(
                                        title: session['title'] ?? 'Session',
                                        subtitle: startTime != null
                                            ? '${_formatDate(startTime)} • ${_formatTime(startTime)}'
                                            : 'Date TBD',
                                        imageUrl: session['imageUrl'] ??
                                            session['coverImage'],
                                        icon: Icons.sports_cricket,
                                        onTap: () {
                                          final isGuardian = GoRouterState.of(
                                            context,
                                          )
                                              .uri
                                              .toString()
                                              .startsWith('/guardian');
                                          if (isGuardian) {
                                            context.push(
                                              '/guardian/session-details/${session['_id']}',
                                            );
                                          } else {
                                            context.push(
                                              '/session-details/${session['_id']}',
                                            );
                                          }
                                        },
                                      ),
                                    );
                                  }).toList(),
                                ).animate().fadeIn().slideX(begin: 0.1),
                              ],

                              // Empty state
                              if (_coaches.isEmpty && _sessions.isEmpty) ...[
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(48.0),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.search_off,
                                          size: 64,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant
                                              .withValues(alpha: 0.5),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          _hasSearched
                                              ? 'No results found'
                                              : 'No coaches available',
                                          style: GoogleFonts.inter(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _hasSearched
                                              ? 'Try different search terms'
                                              : 'Check back later',
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],

                              const SizedBox(height: 48),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final sessionDate = DateTime(date.year, date.month, date.day);

    if (sessionDate == DateTime(now.year, now.month, now.day)) {
      return 'Today';
    } else if (sessionDate == tomorrow) {
      return 'Tomorrow';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

class _CoachCard extends StatelessWidget {
  final String name;
  final String role;
  final String rating;
  final String imageUrl;
  final VoidCallback onTap;

  const _CoachCard({
    required this.name,
    required this.role,
    required this.rating,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: NetworkImage(imageUrl),
              backgroundColor: Theme.of(
                context,
              ).primaryColor.withValues(alpha: 0.1),
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              role,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.orange.withValues(alpha: 0.1)
                    : Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, size: 12, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text(
                    rating,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchResultItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? imageUrl;
  final IconData? icon;
  final VoidCallback onTap;

  const _SearchResultItem({
    required this.title,
    required this.subtitle,
    this.imageUrl,
    this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            if (imageUrl != null)
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: NetworkImage(imageUrl!),
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image:
                        AssetImage('assets/images/default_cricket_session.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
