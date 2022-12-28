import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'user.dart';

class UserBlueprint {
  late User author;
  late String name;
  late String code;
  late int downloads;
  late String tag;
  String id;

  late File f;

  static UserBlueprint create(User author, String name, String code, String tag) {
    final id = uuid.v4();

    final f = File(path.join('db', 'blueprints', '$id.json'));
    f.createSync(recursive: true);

    f.writeAsStringSync(jsonEncode({
      "author": author.id,
      "name": name,
      "code": code,
      "downloads": 0,
      "tag": tag,
    }));

    return UserBlueprint(id);
  }

  static List<UserBlueprint> all() {
    final dir = Directory(path.join('db', 'blueprints'));
    if (!dir.existsSync()) return [];
    final l = <UserBlueprint>[];

    final items = dir.listSync();

    for (var item in items) {
      if (item is File && path.extension(item.path) == ".json") {
        final filename = path.split(item.path).last;
        final id = filename.substring(0, filename.length - 5);

        l.add(UserBlueprint(id));
      }
    }

    return l;
  }

  static bool exists(String id) {
    final f = File(path.join('db', 'blueprints', '$id.json'));
    return f.existsSync();
  }

  static void delete(String id) {
    final f = File(path.join('db', 'blueprints', '$id.json'));

    if (f.existsSync()) f.deleteSync();
  }

  UserBlueprint(this.id) {
    f = File(path.join('db', 'blueprints', '$id.json'));

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
