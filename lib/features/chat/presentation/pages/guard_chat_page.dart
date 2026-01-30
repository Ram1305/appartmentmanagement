import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/app_theme.dart';
import '../../../../core/models/guard_message_model.dart';
import '../bloc/guard_chat_bloc.dart';
import '../bloc/guard_chat_event.dart';
import '../bloc/guard_chat_state.dart';
import 'widgets/chat_input.dart';
import 'widgets/message_bubble.dart';

class GuardChatPage extends StatefulWidget {
  final String? conversationId;
  final String recipientId;
  final String recipientName;
  final String? recipientProfilePic;
  final String? recipientSubtitle;
  final String currentUserType;

  const GuardChatPage({
    super.key,
    this.conversationId,
    required this.recipientId,
    required this.recipientName,
    this.recipientProfilePic,
    this.recipientSubtitle,
    required this.currentUserType,
  });

  @override
  State<GuardChatPage> createState() => _GuardChatPageState();
}

class _GuardChatPageState extends State<GuardChatPage> {
  final ScrollController _scrollController = ScrollController();
  String? _currentConversationId;

  @override
  void initState() {
    super.initState();
    _currentConversationId = widget.conversationId;

    if (_currentConversationId != null) {
      _loadConversation();
    }

    _scrollController.addListener(_onScroll);
  }

  void _loadConversation() {
    final bloc = context.read<GuardChatBloc>();

    // Join conversation room
    bloc.add(JoinConversation(conversationId: _currentConversationId!));

    // Load messages
    bloc.add(LoadMessages(conversationId: _currentConversationId!));

    // Mark messages as read
    bloc.add(MarkMessagesAsRead(conversationId: _currentConversationId!));
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      // Load more messages when scrolled to top (since list is reversed)
      final state = context.read<GuardChatBloc>().state;
      if (state.hasMoreMessages &&
          !state.isLoadingMessages &&
          _currentConversationId != null) {
        context.read<GuardChatBloc>().add(LoadMessages(
              conversationId: _currentConversationId!,
              page: state.currentPage + 1,
            ));
      }
    }
  }

  @override
  void dispose() {
    if (_currentConversationId != null) {
      context.read<GuardChatBloc>().add(
            LeaveConversation(conversationId: _currentConversationId!),
          );
    }
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Connection banner
          BlocBuilder<GuardChatBloc, GuardChatState>(
            buildWhen: (prev, curr) => prev.isConnected != curr.isConnected,
            builder: (context, state) {
              if (!state.isConnected) {
                return Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                  color: AppTheme.errorColor,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wifi_off, color: Colors.white, size: 14),
                      SizedBox(width: 6),
                      Text(
                        'Connecting...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Messages list
          Expanded(
            child: BlocConsumer<GuardChatBloc, GuardChatState>(
              listenWhen: (prev, curr) {
                // Listen for new messages to auto-scroll
                return prev.messages.length < curr.messages.length;
              },
              listener: (context, state) {
                // Auto-scroll to bottom on new message
                if (_scrollController.hasClients) {
                  Future.delayed(const Duration(milliseconds: 100), () {
                    _scrollController.animateTo(
                      0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  });
                }

                // Update conversation ID if it was created
                if (_currentConversationId == null &&
                    state.currentConversationId != null) {
                  _currentConversationId = state.currentConversationId;
                }
              },
              builder: (context, state) {
                if (state.isLoadingMessages && state.messages.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                    ),
                  );
                }

                if (state.messagesError != null && state.messages.isEmpty) {
                  return _buildErrorState(state.messagesError!);
                }

                if (state.messages.isEmpty && _currentConversationId == null) {
                  return _buildEmptyState();
                }

                return _buildMessagesList(state);
              },
            ),
          ),

          // Typing indicator
          BlocBuilder<GuardChatBloc, GuardChatState>(
            buildWhen: (prev, curr) => prev.typingUsers != curr.typingUsers,
            builder: (context, state) {
              final typingUser =
                  state.typingUsers[_currentConversationId ?? ''];
              if (typingUser != null) {
                return TypingIndicator(userName: typingUser);
              }
              return const SizedBox.shrink();
            },
          ),

          // Chat input
          BlocBuilder<GuardChatBloc, GuardChatState>(
            buildWhen: (prev, curr) =>
                prev.isSendingMessage != curr.isSendingMessage,
            builder: (context, state) {
              return ChatInput(
                onSend: _sendMessage,
                onTypingStart: () {
                  if (_currentConversationId != null) {
                    context.read<GuardChatBloc>().add(
                          StartTyping(conversationId: _currentConversationId!),
                        );
                  }
                },
                onTypingStop: () {
                  if (_currentConversationId != null) {
                    context.read<GuardChatBloc>().add(
                          StopTyping(conversationId: _currentConversationId!),
                        );
                  }
                },
                isSending: state.isSendingMessage,
              );
            },
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.primaryColor,
      leadingWidth: 40,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          // Profile picture
          _buildAvatar(),
          const SizedBox(width: 12),
          // Name and subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.recipientName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.recipientSubtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    widget.recipientSubtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacityCompat(0.8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacityCompat(0.2),
        border: Border.all(
          color: Colors.white.withOpacityCompat(0.3),
          width: 2,
        ),
      ),
      child: widget.recipientProfilePic != null &&
              widget.recipientProfilePic!.isNotEmpty
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: widget.recipientProfilePic!,
                fit: BoxFit.cover,
                placeholder: (context, url) => _buildInitials(),
                errorWidget: (context, url, error) => _buildInitials(),
              ),
            )
          : _buildInitials(),
    );
  }

  Widget _buildInitials() {
    final initials = widget.recipientName.isNotEmpty
        ? widget.recipientName
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
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildMessagesList(GuardChatState state) {
    final messages = state.messages;

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      itemCount: messages.length + (state.isLoadingMessages ? 1 : 0),
      itemBuilder: (context, index) {
        if (state.isLoadingMessages && index == messages.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                ),
              ),
            ),
          );
        }

        // Reverse index because list is reversed
        final messageIndex = messages.length - 1 - index;
        final message = messages[messageIndex];
        final isMe = message.senderType == widget.currentUserType;

        // Determine if message is first/last in a group
        final prevMessage =
            messageIndex > 0 ? messages[messageIndex - 1] : null;
        final nextMessage = messageIndex < messages.length - 1
            ? messages[messageIndex + 1]
            : null;

        final isFirstInGroup = prevMessage == null ||
            prevMessage.senderType != message.senderType ||
            _isDifferentDay(prevMessage.createdAt, message.createdAt);

        final isLastInGroup = nextMessage == null ||
            nextMessage.senderType != message.senderType ||
            _isDifferentMinuteGroup(message.createdAt, nextMessage.createdAt);

        // Show date separator
        Widget? dateSeparator;
        if (prevMessage == null ||
            _isDifferentDay(prevMessage.createdAt, message.createdAt)) {
          dateSeparator = DateSeparator(date: message.createdAt);
        }

        return Column(
          children: [
            if (dateSeparator != null) dateSeparator,
            MessageBubble(
              message: message,
              isMe: isMe,
              isFirstInGroup: isFirstInGroup,
              isLastInGroup: isLastInGroup,
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
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacityCompat(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 50,
                color: AppTheme.primaryColor.withOpacityCompat(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Start the conversation',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Send a message to ${widget.recipientName}',
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
            ElevatedButton(
              onPressed: () {
                if (_currentConversationId != null) {
                  context.read<GuardChatBloc>().add(
                        LoadMessages(conversationId: _currentConversationId!),
                      );
                }
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage(String message) {
    context.read<GuardChatBloc>().add(SendMessage(
          conversationId: _currentConversationId,
          recipientId: widget.recipientId,
          message: message,
        ));

    // If this is a new conversation, we need to refresh to get the conversation ID
    if (_currentConversationId == null) {
      context.read<GuardChatBloc>().add(
            GetOrCreateConversation(recipientId: widget.recipientId),
          );
    }
  }

  bool _isDifferentDay(DateTime a, DateTime b) {
    return a.year != b.year || a.month != b.month || a.day != b.day;
  }

  bool _isDifferentMinuteGroup(DateTime a, DateTime b) {
    // Group messages within 2 minutes of each other
    return b.difference(a).inMinutes > 2;
  }
}
