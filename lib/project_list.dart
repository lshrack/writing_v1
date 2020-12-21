import 'package:flutter/material.dart';
import 'database.dart';
import 'count_storage.dart';

class Globals {
  static final projectDbInstance = ProjectDatabaseHelper.instance;
}

class ProjectList extends StatefulWidget {
  @override
  _ProjectListState createState() => _ProjectListState();
}

class _ProjectListState extends State<ProjectList> {
  bool atInit;
  GlobalKey<AnimatedListState> listKey = GlobalKey();

  List<Project> projects = [];

  List<Widget> items = [
    Container(child: Text("hello")),
    Container(child: Text("hi")),
    Container(child: Text("how are you"))
  ];
  @override
  Widget build(BuildContext context) {
    return AnimatedList(
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
                  }),
              Divider()
            ]);
          }
          return Container();
        });
  }

  @override
  void initState() {
    atInit = true;
    ProjectEntry project = ProjectEntry();
    project.name = "Project 1!";
    project.words = "hi";
    project.target = 1000;
    //DatabaseMethods.save(project, projectDbInstance);
    setProjects();
    super.initState();
  }

  Future<void> setProjects() async {
    print("Currently in setProjects()");
    List<Project> updatedProjects =
        await DatabaseMethods.readAllAsEntry(Globals.projectDbInstance);

    if (this.mounted) {
      setState(() {
        projects = updatedProjects;
      });

      if (atInit) {
        for (int i = 0; i < projects.length; i++) {
          listKey.currentState.insertItem(i);
        }
        atInit = false;
      }
    }
  }
}

class Project {
  int id;
  String name;
  int target;
  int wc;
  CountArray counts;
  String countsString;

  Project(
      {this.id = 0,
      this.name = "My Project",
      this.countsString,
      this.target = -1}) {
    counts = CountArray.fromString(countsString);
    wc = counts.getLatestWc();
  }

  String toString() {
    return 'Id: $id, Name: $name, Word Count: ${counts.toString()}, Target: $target';
  }

  ProjectEntry toEntry() {
    return ProjectEntry.withParams(id, name, counts.toString(), target);
  }
}
