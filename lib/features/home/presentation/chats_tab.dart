import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:page_transition/page_transition.dart';

import '../../../app/functions.dart';
import '../../../core/constants/assets_manager.dart';
import '../../../core/constants/mosaed_colors.dart';
import '../../../core/network/failure.dart';
import '../../chat/data/chat_repository.dart';
import '../../chat/data/models/chat_conversation.dart';
import '../../chat/presentation/chat_screen.dart';
import 'widgets/chats_conversation_list.dart';
import 'widgets/chats_empty_state.dart';
import 'widgets/chats_error_state.dart';
import 'widgets/chats_filter.dart';
import 'widgets/chats_filter_bar.dart';
import 'widgets/chats_page_title.dart';
import 'widgets/chats_search_bar.dart';

class ChatsTab extends StatefulWidget {
  const ChatsTab({super.key});

  @override
  State<ChatsTab> createState() => ChatsTabState();
}

class ChatsTabState extends State<ChatsTab> {
  final _searchController = TextEditingController();

  List<ChatConversation> _conversations = [];
  ChatFilter _filter = ChatFilter.all;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;
  String _query = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => reload());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// سوالفي = provider conversations API مرة واحدة.
  Future<void> reload({bool more = false}) async {
    if (!mounted) return;
    if (more) {
      if (!_hasMore || _loadingMore || _loading) return;
      setState(() => _loadingMore = true);
    } else {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final page = await context.read<ChatRepository>().getConversations(
            limit: 20,
            offset: more ? _conversations.length : 0,
          );
      if (!mounted) return;
      setState(() {
        _conversations =
            more ? [..._conversations, ...page.results] : page.results;
        _hasMore = page.hasMore;
        _loading = false;
        _loadingMore = false;
        _error = null;
      });
    } on ServerFailure catch (e) {
      if (!mounted) return;
      setState(() {
        if (!more) _conversations = [];
        _loading = false;
        _loadingMore = false;
        _error = e.errMessage;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (!more) _conversations = [];
        _loading = false;
        _loadingMore = false;
        _error = 'mosaedChatsLoadError'.tr();
      });
    }
  }

  List<ChatConversation> get _filtered {
    var list = _conversations;
    switch (_filter) {
      case ChatFilter.active:
        list = list
            .where((c) => c.status == ChatConversationStatus.active)
            .toList();
        break;
      case ChatFilter.unread:
        list = list.where((c) => c.hasUnread).toList();
        break;
      case ChatFilter.completed:
        list = list
            .where((c) => c.status == ChatConversationStatus.completed)
            .toList();
        break;
      case ChatFilter.all:
        break;
    }
    if (_query.isEmpty) return list;
    final q = _query.toLowerCase();
    return list.where((c) {
      return c.displayPeerName.toLowerCase().contains(q) ||
          c.requestTitle.toLowerCase().contains(q) ||
          (c.lastMessage?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  Future<void> _openChat(ChatConversation conversation) async {
    final peerName = conversation.displayPeerName.isNotEmpty
        ? conversation.displayPeerName
        : 'mosaedClient'.tr();
    await AppFunctions.navigateTo(
      context,
      ChatScreen(
        requestId: conversation.requestId,
        requestTitle: conversation.requestTitle.isNotEmpty
            ? conversation.requestTitle
            : null,
        peerName: peerName,
        peerImage:
            conversation.hasPeerImage ? conversation.peerImage : null,
        price: conversation.price,
      ),
      PageTransitionType.rightToLeft,
    );
    if (mounted) reload();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final showSearchEmpty = _query.isNotEmpty && filtered.isEmpty && !_loading;
    final showEmpty = _query.isEmpty &&
        _conversations.isEmpty &&
        !_loading &&
        _error == null;
    final showError = _error != null && _conversations.isEmpty && !_loading;

    return ColoredBox(
      color: MosaedColors.background,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ChatsPageTitle('mosaedMyChats'.tr()),
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
              child: ChatsSearchBar(
                controller: _searchController,
                query: _query,
                onClear: () => _searchController.clear(),
              ),
            ),
            SizedBox(height: 12.h),
            ChatsFilterBar(
              filter: _filter,
              onChanged: (f) => setState(() => _filter = f),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: MosaedColors.brand,
                      ),
                    )
                  : showError
                      ? ChatsErrorState(
                          error: _error!,
                          onRetry: reload,
                        )
                      : showSearchEmpty
                          ? ChatsEmptyState(
                              onRefresh: reload,
                              image: ImageAssets.chatsSearchEmpty,
                              titleKey: 'mosaedNoSearchResults',
                              bodyKey: 'mosaedNoSearchResultsHint',
                            )
                          : showEmpty
                              ? ChatsEmptyState(
                                  onRefresh: reload,
                                  image: ImageAssets.chatsEmpty,
                                  titleKey: 'mosaedNoChatsYetTitle',
                                  bodyKey: 'mosaedNoChatsYetBody',
                                )
                              : NotificationListener<ScrollNotification>(
                                  onNotification: (n) {
                                    if (n.metrics.extentAfter < 240) {
                                      reload(more: true);
                                    }
                                    return false;
                                  },
                                  child: ChatsConversationList(
                                    conversations: filtered,
                                    onRefresh: reload,
                                    onOpenChat: _openChat,
                                    loadingMore: _loadingMore,
                                  ),
                                ),
            ),
          ],
        ),
      ),
    );
  }
}
