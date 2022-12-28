import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'user.dart';

class UserLevel {
  late User author;
  late String name;
  late String code;
  late int downloads;
  late String tag;
  String id;

  late File f;

  static UserLevel create(User author, String name, String code, String tag) {
    final id = uuid.v4();

    final f = File(path.join('db', 'levels', '$id.json'));
    f.createSync(recursive: true);

    f.writeAsStringSync(jsonEncode({
      "author": author.id,
      "name": name,
      "code": code,
      "downloads": 0,
      "tag": tag,
    }));

    return UserLevel(id);
  }

  static List<UserLevel> all() {
    final dir = Directory(path.join('db', 'levels'));
    if (!dir.existsSync()) return [];
    final l = <UserLevel>[];

    final items = dir.listSync();

    for (var item in items) {
      if (item is File && path.extension(item.path) == ".json") {
        final filename = path.split(item.path).last;
        final id = filename.substring(0, filename.length - 5);

        l.add(UserLevel(id));
      }
    }

    return l;
  }

  static bool exists(String id) {
    final f = File(path.join('db', 'levels', '$id.json'));
    return f.existsSync();
  }

  static void delete(String id) {
    final f = File(path.join('db', 'levels', '$id.json'));

    if (f.existsSync()) f.deleteSync();
  }

  UserLevel(this.id) {
    f = File(path.join('db', 'levels', '$id.json'));

    final m = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;

    author = User(m['author']);
    name = m['name'];
    code = m['code'];
    downloads = (m['downloads'] as num).toInt();
    tag = m['tag'];
  }

  void save() {
    f.writeAsStringSync(jsonEncode({
      "author": author.id,
      "name": name,
      "code": code,
      "downloads": downloads,
      "tag": tag,
    }));
  }
}
