import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_video_call/flutter_video_call.dart';
import 'package:uuid/uuid.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final String _platformVersion = 'Unknown';
  final _flutterVideoCallPlugin = FlutterVideoCall();

  @override
  void initState() {
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: GestureDetector(child: Text('Running on: $_platformVersion\n'),
          onTap: (){
            var uuid = const Uuid();
            CallEvent callEvent = CallEvent(
              sessionId: uuid.v1(),
              callType: 1,
              callerId: 123456,
              callerName: 'Caller Name caling...',
              opponentsIds: {1}.toSet(),
            );
            FlutterVideoCall.showCallNotification(callEvent);
          },),
        ),
      ),
    );
  }
}
