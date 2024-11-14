import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

class StreamChatApp extends StatelessWidget {

  // Attributes :
  final StreamChatClient client;
  final Channel channel;

  const StreamChatApp({ Key? key, required this.client, required this.channel });


  @override
  Widget build(BuildContext context) {
    //
    return MaterialApp(
      builder: (context, child) {
        return StreamChat(client: client, child: child);
      },
      home: StreamChannel(
        channel: channel,
        child: Container(),
      )
    );
  }

}


class ChannelPage extends StatelessWidget {
  const ChannelPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: StreamChannelHeader(

      ),
      body: Column(
        children: [
          Expanded(
              child: StreamMessageListView()
          ),
          StreamMessageInput()
        ],
      )
    );
  }
}