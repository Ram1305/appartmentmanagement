import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/app_theme.dart';
import '../../../../core/models/conversation_model.dart';
import '../bloc/guard_chat_bloc.dart';
import '../bloc/guard_chat_event.dart';
import '../bloc/guard_chat_state.dart';

class SelectRecipientPage extends StatefulWidget {
  final String currentUserType;
  final Function(ChatParticipant) onRecipientSelected;

  const SelectRecipientPage({
    super.key,
    required this.currentUserType,
    required this.onRecipientSelected,
  });

  @override
  State<SelectRecipientPage> createState() => _SelectRecipientPageState();
}

class _SelectRecipientPageState extends State<SelectRecipientPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadRecipients();
  }

  void _loadRecipients() {
    context.read<GuardChatBloc>().add(const LoadRecipientList());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Search bar
          _buildSearchBar(),

          // Recipients list
          Expanded(
            child: BlocBuilder<GuardChatBloc, GuardChatState>(
              builder: (context, state) {
                if (state.isLoadingRecipients) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                    ),
                  );
                }

                if (state.recipientsError != null) {
                  return _buildErrorState(state.recipientsError!);
                }

                final filteredRecipients = _filterRecipients(state.recipients);

                if (filteredRecipients.isEmpty) {
                  return _buildEmptyState();
                }

                return _buildRecipientsList(filteredRecipients);
              },
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.primaryColor,
      title: Text(
        widget.currentUserType == 'security'
            ? 'Select Tenant'
            : 'Select Security Guard',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
          // For security users, search on server
          if (widget.currentUserType == 'security' && value.length >= 2) {
            context.read<GuardChatBloc>().add(LoadRecipientList(searchQuery: value));
          }
        },
        decoration: InputDecoration(
          hintText: widget.currentUserType == 'security'
              ? 'Search by name, block, or room...'
              : 'Search security guards...',
          hintStyle: TextStyle(
            color: AppTheme.textColor.withOpacityCompat(0.4),
          ),
          prefixIcon: Icon(
            Icons.search,
            color: AppTheme.textColor.withOpacityCompat(0.4),
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: AppTheme.textColor.withOpacityCompat(0.4),
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                    _loadRecipients();
                  },
                )
              : null,
          filled: true,
          fillColor: AppTheme.backgroundColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  List<ChatParticipant> _filterRecipients(List<ChatParticipant> recipients) {
    if (_searchQuery.isEmpty) {
      return recipients;
    }

    return recipients.where((recipient) {
      final nameMatch = recipient.name.toLowerCase().contains(_searchQuery);
      final blockMatch =
          recipient.block?.toLowerCase().contains(_searchQuery) ?? false;
      final roomMatch =
          recipient.roomNumber?.toLowerCase().contains(_searchQuery) ?? false;
      return nameMatch || blockMatch || roomMatch;
    }).toList();
  }

  Widget _buildRecipientsList(List<ChatParticipant> recipients) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: recipients.length,
      itemBuilder: (context, index) {
        final recipient = recipients[index];
        return _RecipientCard(
          recipient: recipient,
          onTap: () => widget.onRecipientSelected(recipient),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacityCompat(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_search_rounded,
                size: 50,
                color: AppTheme.primaryColor.withOpacityCompat(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _searchQuery.isNotEmpty ? 'No results found' : 'No recipients available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try a different search term'
                  : widget.currentUserType == 'security'
                      ? 'No tenants available to chat with'
                      : 'No security guards available to chat with',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textColor.withOpacityCompat(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: 16),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textColor.withOpacityCompat(0.6),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadRecipients,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecipientCard extends StatelessWidget {
  final ChatParticipant recipient;
  final VoidCallback onTap;

  const _RecipientCard({
    required this.recipient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.dividerColor.withOpacityCompat(0.5),
          ),
        ),
        child: Row(
          children: [
            // Avatar
            _buildAvatar(),
            const SizedBox(width: 12),

            // Name and details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipient.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (recipient.displaySubtitle != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: AppTheme.textColor.withOpacityCompat(0.5),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          recipient.displaySubtitle!,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textColor.withOpacityCompat(0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Arrow
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppTheme.textColor.withOpacityCompat(0.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacityCompat(0.7),
          ],
        ),
      ),
      child: recipient.profilePic != null && recipient.profilePic!.isNotEmpty
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: recipient.profilePic!,
                fit: BoxFit.cover,
                placeholder: (context, url) => _buildInitials(),
                errorWidget: (context, url, error) => _buildInitials(),
              ),
            )
          : _buildInitials(),
    );
  }

  Widget _buildInitials() {
    final initials = recipient.name.isNotEmpty
        ? recipient.name
            .split(' ')
            .map((e) => e.isNotEmpty ? e[0] : '')
            .take(2)
            .join()
            .toUpperCase()
        : '?';

    return Center(
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}
