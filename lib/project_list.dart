import 'package:flutter/material.dart';
import 'database.dart';
import 'count_storage.dart';
import 'dart:async';
import 'package:validators/validators.dart';

//Variables to be accessed from all classes
class Globals {
  static final projectDbInstance = ProjectDatabaseHelper.instance;
}

//Contains AnimatedList that stores project, as well as Add Project button
class ProjectList extends StatefulWidget {
  @override
  _ProjectListState createState() => _ProjectListState();
}

class _ProjectListState extends State<ProjectList> {
  //Variables that control the projects in the AnimatedList - multiple methods require access
  GlobalKey<AnimatedListState> listKey = GlobalKey();
  List<Project> projects = [];

  //Returns column with AnimatedList and Add Project button
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      AnimatedList(
          shrinkWrap: true,
          key: listKey,
          initialItemCount: 0,
          itemBuilder: (context, i, animation) {
            final index = i;
            if (index < projects.length) {
              final project = projects[index];
              return Column(children: [
                ListTile(
                    title: Text(project.name, style: TextStyle(fontSize: 18)),
                    subtitle: Text("Word Count: ${project.wc}"),
                    trailing: Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      print("I was tapped!");
                      projectPage(context, project);
                    }),
                Divider()
              ]);
            }
            return Container();
          }),

      //Add Project button
      FlatButton(
          onPressed: () async {
            ProjectEntry project = ProjectEntry();
            project.name = "My Project";
            project.words = CountArray.blank().toString();
            project.target = -1;
            project.id =
                await DatabaseMethods.save(project, Globals.projectDbInstance);
            projectPage(context, project.toProject(), added: true);
          },
          child: Row(children: [Icon(Icons.add), Text("Add Project")]))
    ]);
  }

  @override
  void initState() {
    setProjects(atInit: true);
    super.initState();
  }

  //This resets the projects array to whatever is in the database
  //The three input bools reflect possible states: atInit, added, and deleted
  Future<void> setProjects(
      {bool atInit = false, bool added = false, bool deleted = false}) async {
    print("Currently in setProjects()");
    List<Project> updatedProjects =
        await DatabaseMethods.readAllAsProject(Globals.projectDbInstance);

    if (this.mounted) {
      setState(() {
        projects = updatedProjects;
      });

      //If this is our first time building the list, increment listkey for every value in projects
      if (atInit) {
        for (int i = 0; i < projects.length; i++) {
          listKey.currentState.insertItem(i);
        }
      }

      //If we've added a project, increment listkey by one
      if (added) {
        listKey.currentState.insertItem(projects.length - 1);
      }

      //If we've deleted a project, decrement listkey by one
      if (deleted) {
        listKey.currentState.removeItem(0,
            (BuildContext context, Animation<double> animation) {
          return Container();
        });
      }
    }
  }

  //This builds the project page that is accessed when adding a project or clicking an existing one
  Future<void> projectPage(BuildContext context, Project project,
      {added = false}) async {
    final result = await Navigator.of(context)
        .push(MaterialPageRoute<bool>(builder: (BuildContext context) {
      return ProjectPage(project);
    }));

    //Runs setProjects - if added was true (if the function was evoked by the Add Project button)
    //then we'll send that value to the function so listKey can be incremented
    setProjects(added: added, deleted: result);
  }
}

//This is the object definition for Projects (not entries in the database, just Projects)
class Project {
  int id;
  String name;
  int target;
  int wc;
  CountArray counts;
  String countsString;

  //Constructor takes all parameters except counts and wc, which it determines from countsString
  Project(
      {this.id = 0,
      this.name = "My Project",
      this.countsString,
      this.target = -1}) {
    counts = CountArray.fromString(countsString);
    wc = counts.getLatestWc();
  }

  //This creates a string describing a given Project
  String toString() {
    return 'Id: $id, Name: $name, Word Count: ${counts.toString()}, Target: $target';
  }

  //This is used to convert a Project into the ProjectEntry format used in the database.
  ProjectEntry toEntry() {
    return ProjectEntry.withParams(id, name, counts.toString(), target);
  }

  void edit(int which, String newVal) {
    //Editing project name
    if (which == 0) name = newVal;

    //Editing project total wordcount
    if (which == 1) {
      wc = int.parse(newVal);
      counts.editCount(wc);

      countsString = counts.toString();
      print(countsString);
    }

    //Editing project target wordcount
    if (which == 2) target = int.parse(newVal);

    //Adding words
    if (which == 3) {
      wc = wc + int.parse(newVal);

      counts.editCount(wc);

      countsString = counts.toString();
      print(countsString);
    }
  }
}

//This will manage the page for a given project, which will be entered as a parameter
//It is created as its own stateful widget to enable setState after changes
class ProjectPage extends StatefulWidget {
  final Project project;
  ProjectPage(this.project);
  @override
  _ProjectPageState createState() => _ProjectPageState();
}

class _ProjectPageState extends State<ProjectPage> {
  //This part will return the actual project page
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text(widget.project.name), actions: [
          //This button will be for editing the project title
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              genericDialog(
                context: context,
                curr: widget.project,
                hint: "Project Name",
                title: "Edit Project Name",
                currVal: widget.project.name,
                which: 0,
              ).then((onValue) {
                if (onValue != null) {
                  Project newProject = onValue;
                  DatabaseMethods.editItem(
                      Globals.projectDbInstance, newProject.toEntry());
                  setState(() {});
                } else
                  print("Value Unchanged");
              });
            },
          )
        ]),
        //This has the page return false, UNLESS you exit by deleting the project, in which case
        //it'll return true, prompting listkey to be decremented so the project list can keep up
        body: WillPopScope(
          onWillPop: () async {
            Navigator.pop(context, false);
            return false;
          },
          child: Center(
            child: Column(
              children: [
                //Total Wordcount - Label and Edit Button
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Text("Word Count: ${widget.project.wc}"),
                  IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () {
                        genericDialog(
                          context: context,
                          curr: widget.project,
                          hint: "Total Wordcount",
                          title: "Edit Total Wordcount",
                          currVal: widget.project.wc.toString(),
                          which: 1,
                          intInput: true,
                        ).then((onValue) {
                          if (onValue != null) {
                            Project newProject = onValue;
                            DatabaseMethods.editItem(Globals.projectDbInstance,
                                newProject.toEntry());
                            setState(() {});
                          } else
                            print("Value Unchanged");
                        });
                      })
                ]),
                //Target Wordcount - label and edit button
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Text("Target Word Count: ${widget.project.target}"),
                  IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () {
                        print("Edit Target Tapped");
                        genericDialog(
                          context: context,
                          curr: widget.project,
                          hint: "Target Wordcount",
                          title: "Edit Target",
                          currVal: widget.project.target.toString(),
                          which: 2,
                          intInput: true,
                        ).then((onValue) {
                          if (onValue != null) {
                            Project newProject = onValue;
                            DatabaseMethods.editItem(Globals.projectDbInstance,
                                newProject.toEntry());
                            setState(() {});
                          } else
                            print("Value Unchanged");
                        });
                      })
                ]),
                //Add Words button
                FlatButton(
                    onPressed: () {
                      genericDialog(
                              context: context,
                              curr: widget.project,
                              hint: "Words to Add",
                              title: "Add Words",
                              currVal: "",
                              which: 3,
                              intInput: true,
                              buttonText: "ADD")
                          .then((onValue) {
                        if (onValue != null) {
                          Project newProject = onValue;
                          DatabaseMethods.editItem(
                              Globals.projectDbInstance, newProject.toEntry());
                          setState(() {});
                        } else
                          print("Value Unchanged");
                      });
                    },
                    child: Text("Add Words")),
                //Sprint button
                FlatButton(
                  onPressed: () {
                    print("Sprint Tapped");
                  },
                  child: Text("Sprint"),
                ),
                //Delete project button
                FlatButton(
                  onPressed: () {
                    print("Delete Project Tapped");
                    return showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Text("Delete Project?"),
                                  IconButton(
                                      icon: (Icon(Icons.close)),
                                      onPressed: () {
                                        Navigator.of(context,
                                                rootNavigator: true)
                                            .pop();
                                      }),
                                ]),
                            content: Text(
                                "Are you sure you want to delete the project?"),
                            actions: <Widget>[
                              FlatButton(
                                  child: Text("YES"),
                                  onPressed: () {
                                    Navigator.of(context, rootNavigator: true)
                                        .pop(widget.project);
                                  })
                            ],
                          );
                        }).then((onValue) {
                      if (onValue != null) {
                        DatabaseMethods.deleteItem(
                            onValue.id, Globals.projectDbInstance);
                        Navigator.pop(context, true);
                      }
                    });
                  },
                  child: Text("Delete Project"),
                )
              ],
            ),
          ),
        ));
  }

  //Builds and returns dialog for inputting values
  genericDialog(
      {BuildContext context,
      Project curr,
      String title,
      String hint,
      String currVal,
      bool intInput = false,
      String buttonText = "SAVE",
      int which = 0}) {
    return showDialog(
        context: context,
        builder: (context) {
          return GenericDialog(
              context, curr, title, hint, currVal, intInput, buttonText, which);
        });
  }
}

//Stateful widget for creating Dialogs
class GenericDialog extends StatefulWidget {
  final BuildContext context;
  final Project curr;
  final String title;
  final String hint;
  final String currVal;
  final bool intInput;
  final String buttonText;
  final int which;

  GenericDialog(
    this.context,
    this.curr,
    this.title,
    this.hint,
    this.currVal,
    this.intInput,
    this.buttonText,
    this.which,
  );
  @override
  _GenericDialogState createState() => _GenericDialogState();
}

class _GenericDialogState extends State<GenericDialog> {
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
            IconButton(
                icon: (Icon(Icons.close)),
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).pop();
                }),
          ]),
      //Dialog body
      content: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
        TextField(
            onChanged: (String text) {
              if (text == "")
                validInput = false;
              else if (widget.intInput && !isNumeric(text))
                validInput = false;
              else
                validInput = true;

              setState(() {});
            },
            controller: _controller,
            decoration: InputDecoration(
              hintText: widget.hint,
            ))
      ]),
      //Button at bottom of dialog
      actions: <Widget>[
        FlatButton(
            child: Text(widget.buttonText,
                style:
                    TextStyle(color: validInput ? Colors.blue : Colors.grey)),
            onPressed: () {
              if (!validInput) {
                print("Invalid Input");
              } else if (_controller.text != widget.currVal) {
                widget.curr.edit(widget.which, _controller.text);
                Navigator.of(context, rootNavigator: true).pop(widget.curr);
              } else
                Navigator.of(context, rootNavigator: true).pop();
            })
      ],
    );
  }

  @override
  void initState() {
    _controller = TextEditingController(text: widget.currVal);
    validInput = true;
    super.initState();
  }
}
