import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'user.dart';

class UserServer {
  late User author;
  late String name;
  late String ip;
  late int joins;
  late String tag;
  String id;

  late File f;

  static UserServer create(User author, String name, String ip, String tag) {
    final id = uuid.v4();

    final f = File(path.join('db', 'servers', '$id.json'));
    f.createSync(recursive: true);

    f.writeAsStringSync(jsonEncode({
      "author": author.id,
      "name": name,
      "ip": ip,
      "joins": 0,
      "tag": tag,
    }));

    return UserServer(id);
  }

  static List<UserServer> all() {
    final dir = Directory(path.join('db', 'servers'));
    if (!dir.existsSync()) return [];
    final l = <UserServer>[];

    final items = dir.listSync();

    for (var item in items) {
      if (item is File && path.extension(item.path) == ".json") {
        final filename = path.split(item.path).last;
        final id = filename.substring(0, filename.length - 5);

        l.add(UserServer(id));
      }
    }

    return l;
  }

  static bool exists(String id) {
    final f = File(path.join('db', 'servers', '$id.json'));
    return f.existsSync();
  }

  static void delete(String id) {
    final f = File(path.join('db', 'servers', '$id.json'));

    if (f.existsSync()) f.deleteSync();
  }

  UserServer(this.id) {
    f = File(path.join('db', 'servers', '$id.json'));

    final m = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;

    author = User(m['author']);
    name = m['name'];
    ip = m['ip'];
    joins = (m['joins'] as num).toInt();
    tag = m['tag'];
  }

  void save() {
    f.writeAsStringSync(jsonEncode({
      "author": author.id,
      "name": name,
      "ip": ip,
      "joins": joins,
      "tag": tag,
    }));
  }
}
