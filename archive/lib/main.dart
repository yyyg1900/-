import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/intl_standalone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart';
import 'package:work_schedule/src/config.dart';
import 'package:work_schedule/src/event.dart';
import 'package:work_schedule/src/misc.dart';
import 'package:work_schedule/src/notification.dart';
import 'package:work_schedule/src/views/events_view.dart';
import 'package:work_schedule/src/views/remote_events_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  assertSuccess((await (notificationManager.initialize(
      androidAppIcon: 'mipmap/ic_launcher')))!);
  tz.initializeTimeZones();
  setLocalLocation(getLocation(await FlutterNativeTimezone.getLocalTimezone()));
  Intl.systemLocale = await findSystemLocale();
  Intl.defaultLocale = Intl.systemLocale;
  await loadConfiguration();
  await loadEvents();
  runApp(AppRoot());
}

/// 应用程序的逻辑根
class AppRoot extends StatelessWidget {
  AppRoot() : super();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'work_schedule',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: "Noto Sans CJK",
      ),
      home: EventsView(events),
      // home: RemoteEventsView(),
      localizationsDelegates: [
        // AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale.fromSubtags(
            languageCode: 'zh', scriptCode: 'Hans', countryCode: 'CN'),
      ],
    );
  }
}
