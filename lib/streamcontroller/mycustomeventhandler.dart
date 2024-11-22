import 'package:stream_chat_flutter/stream_chat_flutter.dart';

class MyCustomEventHandler extends StreamChannelListEventHandler {
  @override
  void onConnectionRecovered(
      Event event,
      StreamChannelListController controller,
      ) {
    print('Messages non lus : ${event.unreadMessages}');
    // Write your own custom implementation here
  }
}