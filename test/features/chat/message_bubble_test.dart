import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/features/chat/model/chat_message_model.dart';
import 'package:hudhud_delivery/features/chat/presentation/widgets/message_bubble.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';

void main() {
  testWidgets('MessageBubble aligns sent messages to the right', (tester) async {
    final message = ChatMessageModel(
      id: 1,
      conversationId: 1,
      senderId: 10,
      body: 'Hi',
      type: ChatMessageType.text,
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: MessageBubble(
            message: message,
            isMine: true,
            isGroupedTop: false,
            isGroupedBottom: false,
            currentUserId: 10,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hi'), findsOneWidget);
    final row = tester.widget<Row>(find.byType(Row).first);
    expect(row.mainAxisAlignment, MainAxisAlignment.end);
  });
}
