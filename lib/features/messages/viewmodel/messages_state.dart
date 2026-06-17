import '../models/chat_model.dart';

abstract class MessagesState {}

class MessagesInitial extends MessagesState {}

class MessagesLoading extends MessagesState {}

class MessagesSuccess extends MessagesState {
  final List<ChatModel> chats;
  final String searchQuery;

  MessagesSuccess({required this.chats, this.searchQuery = ''});

  List<ChatModel> get filteredChats {
    if (searchQuery.isEmpty) return chats;
    final q = searchQuery.toLowerCase();
    return chats.where((c) => c.displayName.toLowerCase().contains(q)).toList();
  }
}

class MessagesFailure extends MessagesState {
  final String error;
  MessagesFailure(this.error);
}
