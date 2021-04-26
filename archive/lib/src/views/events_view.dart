import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart';
import 'package:uuid/uuid.dart';
import 'package:work_schedule/src/config.dart';
import 'package:work_schedule/src/views/edit_event_view.dart';
import 'package:work_schedule/src/event.dart';
import 'package:work_schedule/src/storage/server_api.dart' as api;

class EventsView extends StatefulWidget {
  final EventCollection events;
  EventsView(this.events, {Key? key}) : super(key: key);

  @override
  _EventViewState createState() => _EventViewState();
}

class _EventViewState extends State<EventsView> {
  @override
  Widget build(BuildContext context) {
    var eventCards = widget.events
        .map(
          (event) => Dismissible(
            key: Key(event.uuid),
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                splashColor: Colors.blue.withAlpha(30),
                child: ListTile(
                    dense: true,
                    leading: Icon(Icons.timelapse),
                    title: Text(event.name),
                    subtitle: Wrap(children: [
                      Text(DateFormat().format(event.start)),
                      Text("-"),
                      Text(DateFormat().format(event.end)),
                    ])),
                onTap: () async {
                  await showEventEditDialog(
                    context: context,
                    defaultContent: event,
                    onUpdate: (event) =>
                        setState(() => widget.events.updateEvent(event)),
                  );
                },
              ),
            ),
            onDismissed: (direction) =>
                setState(() => widget.events.removeEvent(event.uuid)),
          ),
        )
        .toList();
    return Scaffold(
      appBar: AppBar(title: ListTile(title: Text("${TZDateTime.now(local)}"))),
      body: Center(
        child: RefreshIndicator(
          child: ListView(children: eventCards),
          onRefresh: () async {
            await api.query().asyncMap((uuid) async {
              var value = await api.get(uuid);
              var event = Event.fromMap(value);
              widget.events.addOrUpdateEvent(event);
              setState(() {});
            }).drain();
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () async {
          var now = TZDateTime.now(local);
          var start = TZDateTime(local, now.year, now.month, now.day, now.hour)
              .add(Duration(hours: 1));
          var event = Event(
            Uuid().v4(),
            await config.nextId(),
            "",
            "",
            start,
            start.add(Duration(minutes: 30)),
          );
          await showEventEditDialog(
            context: context,
            defaultContent: event,
            onUpdate: (event) => setState(() => widget.events.addEvent(event)),
          );
        },
      ),
      persistentFooterButtons: [
        TextButton(
          child: Text("Magic Button (DEV ONLY)"),
          onPressed: () async {
            debugPrint("magic!");
            widget.events.forEach((e) => debugPrint(e.toMap().toString()));
            var result = api.query();
            result.forEach((uuid) async {
              var info = await api.get(uuid);
              var event = Event.fromMap(info);
              debugPrint("$uuid: $event");
            });
          },
        ),
      ],
    );
  }
}
