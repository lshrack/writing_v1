class CountArray {
  List<Count> counts;

  CountArray.blank() {
    DateTime now = DateTime.now();
    counts = [Count(0, DateTime.utc(now.year, now.month, now.day))];
  }

  CountArray({this.counts});

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

  void addCount(count) {
    counts.add(count);
  }

  String toString() {
    String sum = counts.length.toString();
    for (int i = 0; i < counts.length; i++) {
      sum += counts[i].toString();
    }

    return sum;
  }

  int getLatestWc() {
    DateTime latestDate = DateTime.parse("19700101");
    int wc = 0;
    for (int i = 0; i < counts.length; i++) {
      if (counts[i].date.isAfter(latestDate)) {
        wc = counts[i].count;
      }
    }

    return wc;
  }
}

class Count {
  int count;
  DateTime date;

  Count(this.count, this.date);
  Count.fromStrings(String a, String b) {
    count = int.parse(a);
    date = DateTime.parse(b);
  }

  String toString() {
    return ('SPLIT${count}SPLIT${date.toString()}');
  }
}
