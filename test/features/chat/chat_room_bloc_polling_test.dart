import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/features/chat/bloc/chat_room_bloc.dart';

void main() {
  test('pause and resume polling events are defined', () {
    expect(const PauseChatPollingEvent(), isA<ChatRoomEvent>());
    expect(const ResumeChatPollingEvent(), isA<ChatRoomEvent>());
  });
}
