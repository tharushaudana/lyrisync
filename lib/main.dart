import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:lyrisync/screens/group.dart';
import 'package:lyrisync/screens/qrscan.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:dio/dio.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  final String ws_address = "ws://192.168.108.31:8000";

  late GroupScreenController groupScreenController;

  late WebSocketChannel channel;
  StreamSubscription? channelListenSubscription;
  bool is_connected = false;
  String group_id = "test";

  String? member_id = null;

  final dio = Dio();

  void get_qr() async {
    final response = await dio.get(ws_address);
    print(response);
  }

  void connect_ws() async {
    channel = WebSocketChannel.connect(
      Uri.parse(ws_address),
    );

    try {
      await channel.ready;
    } catch (e) {
      print("Timedout!");
    }

    print("gggggggggggggggggggggggggggg");

    setState(() {
      is_connected = true;
    });

    channelListenSubscription = channel.stream.listen(
      (message) {
        print(message);
        process_msg(message);
      },
      onDone: () {
        print("fffffffffffffffffff");
        setState(() {
          is_connected = false;
        });
      },
    );
  }

  void disconnect_ws() async {
    await channel.sink.close();
    if (channelListenSubscription != null) {
      channelListenSubscription!.cancel();
    }
    setState(() {
      is_connected = false;
    });
  }

  void process_msg(msg) {
    final Map json = jsonDecode(msg);
    final type = json.keys.first;
    final value = json.values.first;

    switch (type) {
      case "memberID":
        member_id = value;
        break;
      case "groupID":
        groupScreenController.notifyCreated(value);
        break;
      default:
    }
  }

  void send_ws_msg(String action, {Object? data}) async {
    if (!is_connected) return;
    channel.sink.add(jsonEncode({
      "action": action,
      "data": data,
    }));
  }

  @override
  void initState() {
    groupScreenController = GroupScreenController(
      onClickCreate: () {
        send_ws_msg("create_group");
      },
      onClickDelete: () {
        send_ws_msg("delete_group");
      },
    );

    super.initState();
  }

  @override
  void dispose() {
    if (channelListenSubscription != null) {
      channelListenSubscription!.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (is_connected)
              Text(
                "CONNECTED",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            const SizedBox(height: 50),
            /*FilledButton(
              onPressed: () {
                get_qr();
              },
              child: Text("Get QR"),
            ),*/
            /*QrImageView(
              data: group_id,
              version: QrVersions.auto,
              size: 200.0,
            ),*/
            FilledButton(
              onPressed: () {
                if (is_connected) {
                  disconnect_ws();
                } else {
                  connect_ws();
                }
              },
              child: Text(!is_connected ? "Connect WS" : "Disconnect"),
            ),
            /*FilledButton(
              onPressed: () {
                send_ws_msg();
              },
              child: Text("Send WS"),
            )*/
            if (is_connected)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(10),
                margin: EdgeInsets.only(top: 20),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.black,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    FilledButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GroupScreen(
                              controller: groupScreenController,
                              channel: channel,
                            ),
                          ),
                        );
                      },
                      child: const Text("Create Group"),
                    ),
                    FilledButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => QrScanScreen(
                              onScan: (id) {
                                send_ws_msg("add_to_group", data: {
                                  "groupID": id,
                                });
                              },
                            ),
                          ),
                        );
                      },
                      child: const Text("Join to Group"),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
