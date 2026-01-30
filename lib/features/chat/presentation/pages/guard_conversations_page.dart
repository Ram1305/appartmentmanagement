import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/app_theme.dart';
import '../../../../core/models/conversation_model.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/websocket_service.dart';
import '../bloc/guard_chat_bloc.dart';
import '../bloc/guard_chat_event.dart';
import '../bloc/guard_chat_state.dart';
import 'guard_chat_page.dart';
import 'select_recipient_page.dart';
import 'widgets/conversation_card.dart';

class GuardConversationsPage extends StatefulWidget {
  final String token;
  final String odId;
  final String userType;

  const GuardConversationsPage({
    super.key,
    required this.token,
    required this.odId,
    required this.userType,
  });

  @override
  State<GuardConversationsPage> createState() => _GuardConversationsPageState();
}

class _GuardConversationsPageState extends State<GuardConversationsPage> {
  late GuardChatBloc _chatBloc;

  @override
  void initState() {
    super.initState();

    // Initialize WebSocket connection
    WebSocketService().connect(
      token: widget.token,
      odId: widget.odId,
      userType: widget.userType,
    );

    // Initialize BLoC and load conversations
    _chatBloc = GuardChatBloc(
      apiService: ApiService(),
      webSocketService: WebSocketService(),
    );
    _chatBloc.add(const LoadConversations());
  }

  @override
  void dispose() {
    _chatBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _chatBloc,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: _buildAppBar(),
        body: _buildBody(),
        floatingActionButton: _buildFAB(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Messages',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      backgroundColor: AppTheme.primaryColor,
      elevation: 0,
      actions: [
        BlocBuilder<GuardChatBloc, GuardChatState>(
          builder: (context, state) {
            if (state.totalUnreadCount > 0) {
              return Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    state.totalUnreadCount > 99
                        ? '99+'
                        : '${state.totalUnreadCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildBody() {
    return BlocBuilder<GuardChatBloc, GuardChatState>(
      builder: (context, state) {
        // Connection status banner
        Widget connectionBanner = const SizedBox.shrink();
        if (!state.isConnected && state.conversations.isNotEmpty) {
          connectionBanner = Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: AppTheme.errorColor.withOpacityCompat(0.9),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.wifi_off, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text(
                  'Connecting...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        if (state.isLoadingConversations && state.conversations.isEmpty) {
          return Column(
            children: [
              connectionBanner,
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  ),
                ),
              ),
            ],
          );
        }

        if (state.conversationsError != null && state.conversations.isEmpty) {
          return Column(
            children: [
              connectionBanner,
              Expanded(
                child: _buildErrorState(state.conversationsError!),
              ),
            ],
          );
        }

        if (state.conversations.isEmpty) {
          return Column(
            children: [
              connectionBanner,
              Expanded(
                child: _buildEmptyState(),
              ),
            ],
          );
        }

        return Column(
          children: [
            connectionBanner,
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  _chatBloc.add(const RefreshConversations());
                  // Wait for refresh to complete
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                color: AppTheme.primaryColor,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.conversations.length,
                  itemBuilder: (context, index) {
                    final conversation = state.conversations[index];
                    final typingUser = state.typingUsers[conversation.id];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ConversationCard(
                        conversation: conversation,
                        currentUserType: state.userType,
                        typingUserName: typingUser,
                        onTap: () => _openChat(conversation, state.userType),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
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
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacityCompat(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 60,
                color: AppTheme.primaryColor.withOpacityCompat(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No conversations yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.userType == 'security'
                  ? 'Start a conversation with a tenant by tapping the + button'
                  : 'Start a conversation with security by tapping the + button',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textColor.withOpacityCompat(0.6),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _navigateToSelectRecipient,
              icon: const Icon(Icons.add),
              label: const Text('Start Chat'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withOpacityCompat(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 50,
                color: AppTheme.errorColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textColor.withOpacityCompat(0.6),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _chatBloc.add(const RefreshConversations()),
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

  Widget? _buildFAB() {
    return BlocBuilder<GuardChatBloc, GuardChatState>(
      builder: (context, state) {
        return FloatingActionButton(
          onPressed: _navigateToSelectRecipient,
          backgroundColor: AppTheme.primaryColor,
          elevation: 4,
          child: const Icon(
            Icons.chat_bubble_outline,
            color: Colors.white,
          ),
        );
      },
    );
  }

  void _openChat(ConversationModel conversation, String userType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: _chatBloc,
          child: GuardChatPage(
            conversationId: conversation.id,
            recipientId: conversation.getOtherParticipantId(userType),
            recipientName: conversation.getDisplayName(userType),
            recipientProfilePic: conversation.getDisplayProfilePic(userType),
            recipientSubtitle: conversation.getDisplaySubtitle(userType),
            currentUserType: userType,
          ),
        ),
      ),
    ).then((_) {
      // Refresh conversations when returning from chat
      _chatBloc.add(const RefreshConversations());
    });
  }

  void _navigateToSelectRecipient() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: _chatBloc,
          child: SelectRecipientPage(
            currentUserType: widget.userType,
            onRecipientSelected: (recipient) {
              Navigator.pop(context);
              _openChatWithRecipient(recipient);
            },
          ),
        ),
      ),
    );
  }

  void _openChatWithRecipient(ChatParticipant recipient) {
    // Check if conversation already exists
    final state = _chatBloc.state;
    ConversationModel? existingConversation;

    for (final conv in state.conversations) {
      final otherParticipantId = conv.getOtherParticipantId(state.userType);
      if (otherParticipantId == recipient.id) {
        existingConversation = conv;
        break;
      }
    }

    if (existingConversation != null) {
      _openChat(existingConversation, state.userType);
    } else {
      // Navigate to chat page - it will create conversation on first message
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BlocProvider.value(
            value: _chatBloc,
            child: GuardChatPage(
              conversationId: null,
              recipientId: recipient.id,
              recipientName: recipient.name,
              recipientProfilePic: recipient.profilePic,
              recipientSubtitle: recipient.displaySubtitle,
              currentUserType: state.userType,
            ),
          ),
        ),
      ).then((_) {
        _chatBloc.add(const RefreshConversations());
      });
    }
  }
}
