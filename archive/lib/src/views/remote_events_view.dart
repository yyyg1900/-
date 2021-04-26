import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart';
import 'package:work_schedule/src/event.dart';
import 'package:work_schedule/src/storage/server_api.dart' as api;

// TODO not used

class RemoteEventsView extends StatefulWidget {
  RemoteEventsView({Key? key}) : super(key: key);

  @override
  _RemoteEventViewState createState() => _RemoteEventViewState();
}

class _RemoteEventViewState extends State<RemoteEventsView> {
  @override
  Widget build(BuildContext context) {
    var remoteEvents = api.query().asyncMap((uuid) => api.get(uuid)).toList();
    var t = FutureBuilder(
      future: remoteEvents,
      builder: (context, snapshot) {
        // TODO has error?
        if (!snapshot.hasData) {
          return CircularProgressIndicator();
        }

        return ListView(
            children: (snapshot.requireData as List<Map<String, dynamic>>)
                .map((data) {
          var event = Event.fromMap(data);
          return Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              splashColor: Colors.blue.withAlpha(30),
              child: ListTile(
                  dense: true,
                  leading: Icon(Icons.all_inbox),
                  title: Text(event.name),
                  subtitle: Wrap(children: [
                    Text(DateFormat().format(event.start)),
                    Text("-"),
                    Text(DateFormat().format(event.end)),
                  ])),
              onTap: () async {
                // await showEventEditDialog(
                //   context: context,
                //   defaultContent: event,
                //   onUpdate: (event) =>
                //       setState(() => widget.events.updateEvent(event)),
                // );
                throw UnimplementedError();
              },
            ),
          );
        }).toList());
      },
    );
    return Scaffold(
      appBar: AppBar(title: ListTile(title: Text("${TZDateTime.now(local)}"))),
      body: Center(child: t),
    );
  }
}
