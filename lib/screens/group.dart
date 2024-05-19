import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class GroupScreen extends StatefulWidget {
  const GroupScreen({
    super.key,
    required this.controller,
    required this.channel,
  });

  final GroupScreenController controller;
  final WebSocketChannel channel;

  @override
  State<StatefulWidget> createState() => GroupScreenState();
}

class GroupScreenState extends State<GroupScreen> {
  String? group_id;

  void createGroup() {
    widget.controller.createGroup();
  }

  @override
  void initState() {
    super.initState();

    widget.controller.listen(
      onCreated: (id) {
        setState(() {
          group_id = id;
        });
      },
      onDeleted: () {},
    );

    createGroup();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Group"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            group_id == null
                ? const Text("Please wait...")
                : QrImageView(
                    data: group_id!,
                    version: QrVersions.auto,
                    size: 200.0,
                  ),
          ],
        ),
      ),
    );
  }
}

class GroupScreenController {
  GroupScreenController({
    required this.onClickCreate,
    required this.onClickDelete,
  });

  final Function onClickCreate;
  final Function onClickDelete;

  late Function onCreated;
  late Function onDeleted;

  void listen({
    required Function(String) onCreated,
    required VoidCallback onDeleted,
  }) {
    this.onCreated = onCreated;
    this.onDeleted = onDeleted;
  }

  void createGroup() {
    onClickCreate();
  }

  void deleteGroup() {
    onClickDelete();
  }

  void notifyCreated(String id) {
    onCreated(id);
  }
}
