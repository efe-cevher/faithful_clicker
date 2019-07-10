import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Faithful Clicker',
      theme: ThemeData(
          primarySwatch: Colors.yellow
      ),
      home: MyHomePage(title: 'Faithful Clicker'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  String _display = "Do Your Best";
  int _remTime = 0;
  bool _gameOn = false;
  bool _endTime = false;
  bool _canShowTimer = false;
  bool _canShowNewHigh = false;
  List<String> _scores = new List();

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          IconButton(icon: Icon(Icons.list), onPressed: _pushSaved),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Visibility(
              child: Text(
                'NEW HIGH SCORE!',
                style: TextStyle(fontSize: 30, color: Colors.redAccent),
              ),
              maintainSize: true,
              maintainAnimation: true,
              maintainState: true,
              visible: _canShowNewHigh,
            ),
            Visibility(
              child: Text(
                'Time: $_remTime',
                style: TextStyle(fontSize: 20),
              ),
              maintainSize: true,
              maintainAnimation: true,
              maintainState: true,
              visible: _canShowTimer,
            ),
            Text('$_display', style: Theme.of(context).textTheme.display1),
            SizedBox(
              height: 50,
            ),
            Text('$_counter', style: Theme.of(context).textTheme.display3),
            SizedBox(
              height: 100,
            ),
            SizedBox(
                width: 300,
                height: 200, // specific value
                child: RaisedButton(
                  onPressed: _buttonClick,
                  splashColor: Colors.yellowAccent,
                  color: Colors.yellow,
                  child: Text(
                    "Click me!",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w300),
                  ),
                ))
          ],
        ),
      ),
    );
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  void _game() {
    if (!_gameOn) {
      _canShowNewHigh = false;
      _canShowTimer = true;
      _display = "Do Your Best";
      _counter = 0;
      _startGame();
    }
  }

  void _startGame() {
    _gameOn = true;
    setState(() {
      _remTime = 10;
    });

    Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_remTime == 0) {
          timer.cancel();
          _gameOver();
        } else {
          _remTime--;
        }
      });
    });
  }

  void _buttonClick() {
    if (!_endTime) {
      _incrementCounter();
      _game();
    }
  }

  void _gameOver() async {
    _endTime = true;
    _gameOn = false;
    _display = "Game Over";
    _canShowTimer = false;
    _checkHighScore();
    _saveScore(_counter);
    _syncScores();

    Timer(Duration(seconds: 2), () {
      setState(() {
        if (_canShowNewHigh) {
          _display = "Push your limits!";
        } else {
          _display = "Try Again";
        }
      });
      _endTime = false;
    });
  }

  void _checkHighScore() {
    if (_scores.length != 0) {
      List<int> scoreValues = new List();
      for (String score in _scores.sublist(0, _scores.length - 1)) {
        var val = int.parse(score.split(".")[1]);
        scoreValues.add(val);
      }
      final maxVal = scoreValues.reduce(max);
      if (_counter > maxVal) {
        setState(() {
          _canShowNewHigh = true;
        });
      }
    } else {
      _canShowNewHigh = true;
    }
  }

  void _saveScore(int score) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var now = new DateTime.now();
    String date =
    new DateFormat("'Date' dd-MM-yyyy    'Time' hh:mm").format(now);
    String newScore = "$date.$score";

    String scores;
    if (prefs.get("scores") != null) {
      scores = prefs.get("scores");
    } else {
      scores = "";
    }

    prefs.setString("scores", "$newScore,$scores");
  }

  void _syncScores() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String scores = prefs.get("scores");
    if (prefs.get("scores") != null) {
      _scores = scores.split(",");
    } else {
      _scores = [];
    }
  }

  void _pushSaved() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          List<String> scores;
          if (_scores.length == 0) {
            scores = _scores;
          } else {
            scores = _scores.sublist(0, _scores.length - 1);
          }
          final Iterable<ListTile> tiles = scores.map(
                (String score) {
              final scoreView = score.split(".");
              return ListTile(
                title:
                Text(
                  scoreView[0],
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w300),
                ),
                subtitle: Text(
                  scoreView[1],
                  style: TextStyle(fontSize: 36),
                ),
              );
            },
          );
          final List<Widget> divided = ListTile.divideTiles(
            context: context,
            tiles: tiles,
          ).toList();
          return Scaffold(
            // Add 6 lines from here...
            appBar: AppBar(
              title: Text('Scoreboard'),
            ),
            body: ListView(children: divided),
          ); // ... to here.
        },
      ), // ... to here.
    );
  }

  @override
  // ignore: must_call_super
  void initState() {
    _syncScores();
  }
}
