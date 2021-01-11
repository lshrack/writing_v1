import 'package:flutter/material.dart';
import 'project_list.dart';
import 'dart:async';
import 'package:validators/validators.dart';
import 'database.dart';

//This class will build the actual page for sprints
class SprintPage extends StatefulWidget {
  final Project project;
  SprintPage(this.project);
  @override
  _SprintPageState createState() => _SprintPageState();
}

class _SprintPageState extends State<SprintPage> {
  int state;

  int time;

  int initialProjectWC;
  int startingWordCount;
  int wordsAdded;

  TextEditingController timeController;
  TextEditingController startingWCController;

  DateTime end;
  DateTime now;
  Timer timer;

  @override
  Widget build(BuildContext context) {
    //First page of sprint - lets user enter initial wordcount and time
    if (state == 0) {
      return Scaffold(
          appBar: AppBar(title: Text("Sprint")),
          body: Center(
              child: Column(
            children: [
              Padding(
                  padding: EdgeInsets.all(20),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                            padding: EdgeInsets.all(5),
                            child:
                                Text("Time: ", style: TextStyle(fontSize: 20))),
                        Container(
                            constraints:
                                BoxConstraints(maxWidth: 80, maxHeight: 30),
                            child: TextField(
                                controller: timeController,
                                style: TextStyle(
                                  fontSize: 20,
                                ))),
                        Padding(
                            padding: EdgeInsets.all(5),
                            child: Text("minutes",
                                style: TextStyle(fontSize: 20))),
                      ])),
              Padding(
                  padding: EdgeInsets.all(20),
                  child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Padding(
                            padding: EdgeInsets.all(5),
                            child: Text("Words in Working Document: ",
                                style: TextStyle(fontSize: 20))),
                        Container(
                            constraints:
                                BoxConstraints(maxWidth: 100, maxHeight: 30),
                            child: TextField(
                                controller: startingWCController,
                                style: TextStyle(fontSize: 20)))
                      ])),
              //Button to start sprint
              FlatButton(
                onPressed: () {
                  print("Sprint Started");
                  state = 1;

                  time = int.parse(timeController.text);
                  startingWordCount = int.parse(startingWCController.text);
                  startTimer();
                  setState(() {});
                },
                child: Text("Start Sprint"),
              )
            ],
          )));
    }
    //Second page of sprint - displays timer, starting word count, and end sprint early button
    if (state == 1) {
      Duration difference = end.difference(now);
      String timerString = "";
      if (difference.inHours != 0) {
        timerString += difference.inHours.toString() + ":";
        if (difference.inMinutes.remainder(60) < 10) timerString += "0";
      }
      timerString += difference.inMinutes.remainder(60).toString() + ":";
      if (difference.inSeconds.remainder(60) < 10) timerString += "0";
      timerString += difference.inSeconds.remainder(60).toString();

      return Scaffold(
          appBar: AppBar(title: Text("Sprint")),
          body: Center(
              child: Column(
            children: [
              Text(timerString),
              Text("Starting WC: $startingWordCount"),
              FlatButton(
                child: Text("End Sprint Early"),
                onPressed: () {
                  finishDialog(
                          context: context,
                          title: "End Early",
                          cancelButton: true)
                      .then((onValue) {
                    if (onValue != null) {
                      state = 2;
                      if (timer.isActive) timer.cancel();
                      wordsAdded = onValue - startingWordCount;
                      widget.project.edit(3, wordsAdded.toString());

                      DatabaseMethods.editItem(
                          Globals.projectDbInstance, widget.project.toEntry());
                      if (this.mounted) setState(() {});
                    }
                  });
                },
              )
            ],
          )));
    }
    //Third sprint page - shows how many words were added as well as total project word count
    if (state == 2) {
      return Scaffold(
          appBar: AppBar(title: Text("Sprint")),
          body: Center(
              child: Column(
            children: [
              Text("Words Added: $wordsAdded"),
              Text("Total Words: ${initialProjectWC + wordsAdded}"),
              Text("Time: $time")
            ],
          )));
    } else
      return Container();
  }

  @override
  void initState() {
    state = 0;
    startingWordCount = 0;
    time = 15;
    wordsAdded = 0;
    initialProjectWC = widget.project.wc;
    timeController = TextEditingController(text: time.toString());
    startingWCController =
        TextEditingController(text: startingWordCount.toString());
    super.initState();
  }

  //Starts timer when user starts the sprint
  void startTimer() {
    now = DateTime.now();
    end = now.add(Duration(minutes: time));
    timer = Timer.periodic(
      Duration(
        seconds: 1,
      ),
      (timer) {
        setState(() {
          // Updates the current date time.
          now = DateTime.now();

          // If the auction has now taken place, then cancels the timer.
          if (end.isBefore(now)) {
            timer.cancel();
            finishDialog(
                    context: context, title: "Time's Up!", cancelButton: false)
                .then((onValue) {
              state = 2;

              onValue != null ? wordsAdded = onValue : wordsAdded = 0;
              widget.project.edit(3, wordsAdded.toString());
              DatabaseMethods.editItem(
                  Globals.projectDbInstance, widget.project.toEntry());
              if (this.mounted) setState(() {});
            });
          }
        });
      },
    );
  }

  @override
  void dispose() {
    if (timer != null && timer.isActive) {
      timer.cancel();
    }
    super.dispose();
  }

  //Displays the dialog that allows the user to enter their final word count
  finishDialog({BuildContext context, String title, bool cancelButton}) {
    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return FinishDialog(
              context: context, title: title, cancelButton: cancelButton);
        });
  }
}

//Dialog that displays to allow user to enter their final word count
class FinishDialog extends StatefulWidget {
  final BuildContext context;
  final String title;
  final bool cancelButton;

  FinishDialog(
      {this.context, this.title = "Time's Up!", this.cancelButton = false});

  @override
  _FinishDialogState createState() => _FinishDialogState();
}

class _FinishDialogState extends State<FinishDialog> {
  TextEditingController _controller;
  bool validInput;
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      //Dialog title
      title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(widget.title),
          ]),
      //Dialog body
      content: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
        TextField(
            onChanged: (String text) {
              if (text == "")
                validInput = false;
              else if (!isNumeric(text))
                validInput = false;
              else if (int.parse(text) < 0)
                validInput = false;
              else
                validInput = true;

              setState(() {});
            },
            controller: _controller,
            decoration: InputDecoration(
              hintText: "Final Word Count",
            ))
      ]),
      //Button at bottom of dialog
      actions: <Widget>[
        widget.cancelButton
            ? FlatButton(
                child: Text("CANCEL"),
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).pop();
                },
              )
            : Container(),
        FlatButton(
            child: Text("SAVE",
                style:
                    TextStyle(color: validInput ? Colors.blue : Colors.grey)),
            onPressed: () {
              if (!validInput) {
                print("Invalid Input");
              } else {
                Navigator.of(context, rootNavigator: true)
                    .pop(int.parse(_controller.text));
              }
            })
      ],
    );
  }

  @override
  void initState() {
    _controller = TextEditingController();
    validInput = false;
    super.initState();
  }
}
