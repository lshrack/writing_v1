//This will be used to store the array of counts and dates for a given project
class CountArray {
  List<Count> counts;

  //The blank constructor can be used to create an array with one Count, with wc 0 and date now
  CountArray.blank() {
    DateTime now = DateTime.now();
    counts = [Count(0, DateTime.utc(now.year, now.month, now.day))];
  }

  //This constructor can be used to create a CountArray when directly passed a List<Count>
  CountArray({this.counts});

  //This constructor parses a String and uses it to form counts
  CountArray.fromString(String x) {
    this.counts = [];
    List<String> parts = x.split("SPLIT");
    int length = int.parse(parts[0]);
    int j = 1;
    for (int i = 0; i < length; i++) {
      if (j + 1 < parts.length) {
        counts.add(Count.fromStrings(parts[j], parts[j + 1]));
        j += 2;
      }
    }
  }

  //This converts the CountArray to a String by combining the length of the array
  //with the String generated by each individual Count
  String toString() {
    String sum = counts.length.toString();
    for (int i = 0; i < counts.length; i++) {
      sum += counts[i].toString();
    }

    return sum;
  }

  //This is used to get the most recent wordcount from a CountArray by comparing each count's date
  int getLatestWc() {
    DateTime latestDate = DateTime.parse("19700101");
    int wc = 0;
    for (int i = 0; i < counts.length; i++) {
      if (counts[i].date.isAfter(latestDate)) {
        wc = counts[i].count;
        latestDate = counts[i].date;
      }
    }

    return wc;
  }

  //This gets the date of the most recent word count
  DateTime getLatestDate() {
    DateTime latestDate = DateTime.parse("19700101");
    for (int i = 0; i < counts.length; i++) {
      if (counts[i].date.isAfter(latestDate)) {
        latestDate = counts[i].date;
      }
    }

    return latestDate;
  }

  //This is used when the count is edited; if it's a new day, it adds a new Count;
  //otherwise, it just deletes today's existing Count and replaces it with the new one
  void editCount(int wc) {
    DateTime now = DateTime.now();
    DateTime latest = getLatestDate();
    for (int i = 0; i < counts.length; i++) {
      if (now.year == latest.year &&
          now.month == latest.month &&
          now.day == latest.day) {
        counts.removeAt(i);
      }
    }

    counts.add(Count(wc, DateTime.now()));
  }
}

//The Count class is used to store a given wc and date pair
class Count {
  int count;
  DateTime date;

  //The main constructor takes in an integer and a DateTime object to create a Count
  Count(this.count, this.date);

  //This constructor will take two strings, a and b, and convert a into an integer for count
  //and b into a DateTime for date
  Count.fromStrings(String a, String b) {
    count = int.parse(a);
    date = DateTime.parse(b);
  }

  //The toString method converts a Count object into a String of form "SPLIT[count]SPLIT[date.toString()]"
  String toString() {
    return ('SPLIT${count}SPLIT${date.toString()}');
  }
}
