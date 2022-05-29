import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timer_builder/timer_builder.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clock-time extension',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      home: const MyHomePage(title: 'Clock-time extension'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

String getSystemTime() {
  var now = DateTime.now();
  return DateFormat("yyyy-MM-dd HH:mm:ss").format(now);
}

String getTimeLapsed(String start, String end) {
  var startTime = DateTime.parse(start);
  var endTime = DateTime.parse(end);
  return endTime.difference(startTime).inSeconds.toString();
}

String getTimeLapsedFormatted(String timeLapsed) {
  int timeLapsedNumber = int.parse(timeLapsed);
  if (timeLapsedNumber >= 3600) {
    return "${(timeLapsedNumber / 3600).ceil()} h";
  } else if (timeLapsedNumber >= 60) {
    return "${(timeLapsedNumber / 60).ceil()} m";
  } else {
    return '$timeLapsed s';
  }
}

String getTotalTime(List<dynamic> timeSlots) {
  int secondsPassed = 0;
  timeSlots.forEach((element) {
    int timeLapsed = int.parse(element["timeLapsed"]);
    secondsPassed += timeLapsed;
  });

  return getTimeLapsedFormatted(secondsPassed.toString());
}

class _MyHomePageState extends State<MyHomePage> {
  bool counting = false;
  String startingTime = "";
  List<dynamic> timeSlots = [];

  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  late SharedPreferences prefs;

  void _incrementCounter() async {
    if (counting) {
      setState(() {
        prefs.setBool('counter', false);
        String endTime = getSystemTime();
        counting = false;
        timeSlots.add(
          {
            "startingTime": startingTime,
            "endTime": endTime,
            "timeLapsed": getTimeLapsed(startingTime, endTime),
          },
        );
        prefs.setString('timeSlots', json.encode(timeSlots));
      });
    } else {
      setState(() {
        counting = true;
        startingTime = getSystemTime();
        prefs.setBool('counter', true);
        prefs.setString('startingTime', startingTime);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _asyncInitialization().then((result) {
      counting = prefs.getBool('counter') ?? false;
      startingTime = prefs.getString('startingTime') ?? '';
      String timeSlotsString = prefs.getString('timeSlots') ?? '[]';
      timeSlots = json.decode(timeSlotsString);
      setState(() {});
    });
  }

  _asyncInitialization() async {
    prefs = await _prefs;
    counting = prefs.getBool('counter') ?? false;
    return counting;
  }

  _getListTiles() {
    List<ListTile> listTileElements = [];
    timeSlots.forEach((element) {
      String timeLapsed = getTimeLapsedFormatted(element["timeLapsed"]);
      listTileElements.add(ListTile(
        title: Text("Time Lapsed: $timeLapsed"),
        subtitle: Text(
            "Starting Time: ${element["startingTime"]}\nEnd time: ${element["endTime"]}"),
      ));
    });
    return listTileElements;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text(widget.title)),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'You have the following items for hours',
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  counting
                      ? TimerBuilder.periodic(const Duration(seconds: 1),
                          builder: (context) {
                          return Text(
                            getSystemTime(),
                            style: const TextStyle(
                                color: Color(0xff2d386b),
                                fontSize: 30,
                                fontWeight: FontWeight.w700),
                          );
                        })
                      : Container(),
                  ..._getListTiles(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Total minutes passed: ${getTotalTime(timeSlots)}"),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
