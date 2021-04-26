import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart';
import 'package:work_schedule/src/event.dart';

/// 事件编辑界面。
class EditEventView extends StatefulWidget {
  final Event event;

  const EditEventView(this.event, {Key? key}) : super(key: key);

  @override
  _EditEventViewState createState() => _EditEventViewState.fromEventData(event);
}

class _EditEventViewState extends State<EditEventView> {
  final int localId;
  final String uuid;
  final TextEditingController name;
  final TextEditingController detail;
  final formKey = GlobalKey<FormState>();
  TZDateTime start;
  TZDateTime end;

  _EditEventViewState.fromEventData(Event event)
      : localId = event.localId,
        uuid = event.uuid,
        name = TextEditingController(text: event.name),
        detail = TextEditingController(text: event.detail),
        start = event.start,
        end = event.end;

  @override
  Widget build(BuildContext context) {
    var pickDateTime = (TZDateTime initialDate) async {
      var date = await showDatePicker(
        context: context,
        firstDate: DateTime(2000, 1, 1),
        lastDate: DateTime(2099, 12, 31),
        initialDate: initialDate,
      );
      if (date == null) {
        return null;
      }
      var time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
      );
      if (time == null) {
        return null;
      }
      var newDate = TZDateTime(
        local,
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      return newDate;
    };
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            children: [
              Card(
                child: Padding(
                  padding: EdgeInsets.all(9.0),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: name,
                        decoration: InputDecoration(hintText: "Name"),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return "Name cannot be empty";
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: detail,
                        maxLines: null,
                        decoration: InputDecoration(hintText: "Details"),
                      ),
                    ],
                  ),
                ),
              ),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(9.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          Text("起始时间"),
                          TextButton(
                            child: Text(DateFormat().format(start)),
                            onPressed: () => pickDateTime(start).then((value) {
                              if (value != null) {
                                setState(() {
                                  start = value;
                                });
                              }
                            }),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text("终止时间"),
                          TextButton(
                            child: Text(DateFormat().format(end)),
                            onPressed: () => pickDateTime(end).then((value) {
                              if (value != null) {
                                setState(() {
                                  end = value;
                                });
                              }
                            }),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      persistentFooterButtons: [
        TextButton(
          child: Text("Save"),
          onPressed: () {
            if (formKey.currentState!.validate()) {
              Navigator.pop(
                context,
                Event(
                  uuid,
                  localId,
                  name.text,
                  detail.text,
                  start,
                  end,
                ),
              );
            }
          },
        ),
        TextButton(
          child: Text("Discard"),
          onPressed: () {
            Navigator.pop(context, null);
          },
        ),
      ],
    );
  }
}

Future<void> showEventEditDialog({
  required BuildContext context,
  required Event defaultContent,
  required FutureOr<void> Function(Event) onUpdate,
}) async {
  var newEvent = await Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => EditEventView(defaultContent)),
  );
  if (newEvent != null) {
    await onUpdate(newEvent);
  }
}
