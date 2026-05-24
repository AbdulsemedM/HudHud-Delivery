import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hudhud_delivery/app/services/auth_service.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/features/chat/bloc/chat_room_bloc.dart';
import 'package:hudhud_delivery/features/chat/bloc/conversations_bloc.dart';
import 'package:hudhud_delivery/features/chat/data/chat_data_provider.dart';
import 'package:hudhud_delivery/features/chat/data/chat_repository.dart';
import 'package:hudhud_delivery/features/chat/model/chat_conversation_detail_result.dart';

ChatRepository createChatRepository() {
  return ChatRepository(
    dataProvider: ChatDataProvider(apiService: ApiService.instance),
  );
}

ConversationsBloc createConversationsBloc({AuthService? authService}) {
  final auth = authService ?? AuthService();
  return ConversationsBloc(
    repository: createChatRepository(),
    currentUserId: auth.currentUser?.id,
  );
}

ChatRoomBloc createChatRoomBloc({AuthService? authService}) {
  final auth = authService ?? AuthService();
  return ChatRoomBloc(
    repository: createChatRepository(),
    currentUserId: auth.currentUser?.id,
  );
}

BlocProvider<ConversationsBloc> conversationsBlocProvider({
  required Widget child,
}) {
  return BlocProvider(
    create: (_) => createConversationsBloc()..add(const LoadConversationsEvent()),
    child: child,
  );
}

BlocProvider<ChatRoomBloc> chatRoomBlocProvider({
  required int conversationId,
  ChatConversationDetailResult? initialDetail,
  required Widget child,
}) {
  return BlocProvider(
    create: (_) => createChatRoomBloc()
      ..add(
        OpenChatRoomEvent(
          conversationId,
          initialDetail: initialDetail,
        ),
      ),
    child: child,
  );
}
