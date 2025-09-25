import 'package:flutter/material.dart';
import 'dart:async';

class PomodoroTimerPage extends StatefulWidget {
  @override
  _PomodoroTimerPageState createState() => _PomodoroTimerPageState();
}

class _PomodoroTimerPageState extends State<PomodoroTimerPage> {
  int workMinutes = 25;
  int breakMinutes = 5;
  int maxWork = 25;
  int maxBreak = 10;
  int secondsLeft = 25 * 60;
  bool isWork = true;
  Timer? timer;
  bool isPaused = false;

  void startTimer() {
    timer?.cancel();
    isPaused = false;
    timer = Timer.periodic(Duration(seconds: 1), (t) {
      if (secondsLeft > 0) {
        setState(() {
          secondsLeft--;
        });
      } else {
        setState(() {
          isWork = !isWork;
          secondsLeft = (isWork ? workMinutes : breakMinutes) * 60;
        });
      }
    });
    setState(() {});
  }

  void stopTimer() {
    timer?.cancel();
    timer = null;
    isPaused = true;
    setState(() {});
  }

  void resetTimer() {
    stopTimer();
    setState(() {
      isWork = true;
      secondsLeft = workMinutes * 60;
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  String get timeString {
    int min = secondsLeft ~/ 60;
    int sec = secondsLeft % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isWork ? Color(0xFFFFF3E0) : Color(0xFFE3F2FD),
      appBar: AppBar(
        backgroundColor: isWork ? Colors.orange : Colors.blue,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 24),
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isWork ? Colors.orange[100] : Colors.blue[100],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    Text(
                      isWork ? 'Work Time' : 'Break Time',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 160,
                          height: 160,
                          child: CircularProgressIndicator(
                            value:
                                secondsLeft /
                                ((isWork ? workMinutes : breakMinutes) * 60),
                            strokeWidth: 10,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isWork ? Colors.orange : Colors.blue,
                            ),
                          ),
                        ),
                        Text(
                          timeString,
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Column(
                          children: [
                            Text(
                              'Work',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(
                              width: 80,
                              child: Slider(
                                value: workMinutes.toDouble(),
                                min: 1,
                                max: maxWork.toDouble(),
                                divisions: maxWork - 1,
                                label: '$workMinutes min',
                                onChanged: (v) {
                                  setState(() {
                                    workMinutes = v.toInt();
                                    if (isWork) secondsLeft = workMinutes * 60;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        SizedBox(width: 16),
                        Column(
                          children: [
                            Text(
                              'Break',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(
                              width: 80,
                              child: Slider(
                                value: breakMinutes.toDouble(),
                                min: 1,
                                max: maxBreak.toDouble(),
                                divisions: maxBreak - 1,
                                label: '$breakMinutes min',
                                onChanged: (v) {
                                  setState(() {
                                    breakMinutes = v.toInt();
                                    if (!isWork)
                                      secondsLeft = breakMinutes * 60;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isWork ? Colors.orange[50] : Colors.blue[50],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      isWork ? Icons.edit : Icons.coffee,
                      color: isWork ? Colors.orange : Colors.blue,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isWork
                            ? 'This is your work time\nLet\'s focus on getting things done'
                            : 'This is your break time\nLet\'s breathe and relax for a bit',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              if (isWork)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    minimumSize: Size(180, 48),
                  ),
                  onPressed: () {
                    stopTimer();
                    setState(() {
                      isWork = false;
                      secondsLeft = breakMinutes * 60;
                    });
                  },
                  child: Text('I need a break'),
                )
              else
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    minimumSize: Size(180, 48),
                  ),
                  onPressed: () {
                    stopTimer();
                    setState(() {
                      isWork = true;
                      secondsLeft = workMinutes * 60;
                    });
                  },
                  child: Text('Start working again'),
                ),
              SizedBox(height: 12),
              OutlinedButton(
                style: OutlinedButton.styleFrom(minimumSize: Size(180, 48)),
                onPressed: () {
                  resetTimer();
                },
                child: Text('End this session'),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  foregroundColor: Colors.black,
                  minimumSize: Size(180, 48),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('Back'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(
          (timer != null && timer!.isActive && !isPaused)
              ? Icons.pause
              : Icons.play_arrow,
        ),
        backgroundColor: isWork ? Colors.orange : Colors.blue,
        onPressed: () {
          if (timer == null || !timer!.isActive || isPaused) {
            startTimer();
          } else {
            stopTimer();
          }
        },
      ),
    );
  }
}
