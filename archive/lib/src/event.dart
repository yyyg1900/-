import 'dart:collection';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart';
import 'package:work_schedule/src/misc.dart';
import 'package:work_schedule/src/notification.dart';
import 'package:work_schedule/src/storage/database.dart';

/// 一个事件。纯数据类型。
class Event {
  final String uuid;

  final int localId;
  final String name;
  final String detail;
  final TZDateTime start;
  final TZDateTime end;

  const Event(
    this.uuid,
    this.localId,
    this.name,
    this.detail,
    this.start,
    this.end,
  );

  Event.fromMap(Map<String, dynamic> value)
      : uuid = value["uuid"],
        localId = value["localId"],
        name = value["name"],
        detail = value["detail"],
        start = TZDateTime.fromMillisecondsSinceEpoch(local, value["start"]),
        end = TZDateTime.fromMillisecondsSinceEpoch(local, value["end"]);

  Map<String, dynamic> toMap() {
    return {
      "uuid": uuid,
      "localId": localId,
      "name": name,
      "detail": detail,
      "start": start.millisecondsSinceEpoch,
      "end": end.millisecondsSinceEpoch,
    };
  }
}

/// 一个运行时事件。包含数据与其他运行时项。
class _RuntimeEvent {
  Event _event;
  late NativeNotification _notification;
  int get localId => _event.localId;
  String get uuid => _event.uuid;
  String get name => _event.name;
  String get detail => _event.detail;
  TZDateTime get start => _event.start;
  TZDateTime get end => _event.end;
  Event get data => _event;

  _RuntimeEvent(this._event) {
    _notification = notificationManager.createNotification(localId);
    _updateNotification();
  }

  void updateEvent(Event event) {
    _event = event;
    _updateNotification();
  }

  void dispose() {
    _notification.cancel();
  }

  Future<void> _updateNotification() async {
    _notification.title = name;
    _notification.body = detail.isNotEmpty ? detail : "No details provided";
    _notification.payload = uuid;

    var now = TZDateTime.now(local);
    var preStart = start.subtract(Duration(minutes: 15));
    if (end.isAfter(now)) {
      var android = AndroidNotificationDetails(
        "event",
        "Event Channel",
        "Channel used to notify events",
        importance: Importance.high,
        priority: Priority.high,
        autoCancel: false,
        ongoing: true,
        channelAction: AndroidNotificationChannelAction.createIfNotExists,
        onlyAlertOnce: true,
        timeoutAfter: end
            .difference(preStart.isAfter(now) ? preStart : now)
            .inMilliseconds,
        showWhen: true,
        when: start.millisecondsSinceEpoch,
      );
      await (preStart.isAfter(now)
          ? _notification.zonedSchedule(
              scheduledDate: preStart,
              android: android,
              androidAllowWhileIdle: true)
          : _notification.show(android: android));
    } else {
      await _notification.cancel();
    }
  }
}

late final EventCollection _events;
EventCollection get events => _events;

Future<void> loadEvents() async {
  await initDatabase();
  _events = EventCollection._internal();
  for (var entry in await database.query()) {
    var event = _RuntimeEvent(Event.fromMap(entry));
    _events._inner[event.uuid] = event;
    assertSuccess(_events._timeSorted.add(event));
  }
}

/// 一个事件集合。同时存储数据和运行时对象，但只允许数据操作。
class EventCollection extends Iterable<Event> {
  final Map<String, _RuntimeEvent> _inner = {};
  final SplayTreeSet<_RuntimeEvent> _timeSorted = SplayTreeSet((lhs, rhs) {
    var cmpStart = lhs.start.compareTo(rhs.start);
    if (cmpStart != 0) {
      return cmpStart;
    }
    var cmpName = lhs.name.compareTo(rhs.name);
    if (cmpName != 0) {
      return cmpName;
    }
    return lhs.uuid.compareTo(rhs.uuid);
  });

  EventCollection._internal();

  void addEvent(Event event) {
    var rtEvent = _RuntimeEvent(event);
    _inner[event.uuid] = rtEvent;
    assertSuccess(_timeSorted.add(rtEvent));
    database.insert(event.toMap());
  }

  void removeEvent(String uuid) {
    var event = _inner.remove(uuid)!;
    assertSuccess(_timeSorted.remove(event));
    event.dispose();
    database.delete(event.uuid);
  }

  void updateEvent(Event event) {
    _inner[event.uuid]!.updateEvent(event);
    database.update(event.toMap());
  }

  void addOrUpdateEvent(Event event) {
    if (_inner.containsKey(event.uuid)) {
      updateEvent(event);
    } else {
      addEvent(event);
    }
  }

  @override
  Iterator<Event> get iterator =>
      _timeSorted.map((element) => element.data).iterator;
}
