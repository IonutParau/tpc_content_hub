import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;
import 'dart:io';

import 'package:uuid/uuid.dart';

import 'blueprints.dart';
import 'levels.dart';
import 'servers.dart';

final uuid = Uuid();

class User {
  Map<String, dynamic> map = {};
  String id;
  late File f;

  static bool exists(String id) {
    return File(path.join('db', 'users', '$id.json')).existsSync();
  }

  static void delete(User user) {
    final f = File(path.join('db', 'users', '${user.id}.json'));

    if (f.existsSync()) {
      f.deleteSync();
    }
  }

  static User create(String name, String password) {
    final hash = sha256.convert(utf8.encode(password)).toString();

    final map = {
      "name": name,
      "passhash": hash,
      "bio": "Hi! I am new to this hub",
      "levels": [],
      "blueprints": [],
      "servers": [],
      "tags": [],
    };

    final id = uuid.v4();

    final f = File(path.join('db', 'users', '$id.json'));

    f.createSync(recursive: true);

    f.writeAsStringSync(jsonEncode(map));

    return User(id);
  }

  static final Map<String, User> _nameLookupCache = {};

  static List<User> all() {
    final dir = Directory(path.join('db', 'users'));

    if (!dir.existsSync()) return [];

    final items = dir.listSync();

    final users = <User>[];

    for (var item in items) {
      if (item is File && path.extension(item.path) == ".json") {
        final filename = path.split(item.path).last;
        final id = filename.substring(0, filename.length - 5);
        users.add(User(id));
      }
    }

    return users;
  }

  static User? lookByName(String name) {
    if (_nameLookupCache.containsKey(name)) return _nameLookupCache[name];

    final users = User.all();

    for (var user in users) {
      if (user.name == name) {
        return user;
      }
    }

    return null;
  }

  String get name => map['name'];
  set name(String newname) {
    map['name'] = name;
    save();
  }

  String get bio => map['bio'];
  set bio(String newbio) {
    map['bio'] = newbio;
    save();
  }

  User(this.id) {
    f = File(path.join('db', 'users', '$id.json'));

    try {
      final str = f.readAsStringSync();
      map = jsonDecode(str);
    } catch (e) {
      map = {};
    }

    _finalizer.attach(this, f.watch().listen(_handleFileEvent));
  }

  static final _finalizer = Finalizer<StreamSubscription>((ss) => ss.cancel());

  void _handleFileEvent(FileSystemEvent event) {
    if (event is FileSystemModifyEvent) {
      if (event.contentChanged) {
        try {
          final str = f.readAsStringSync();
          map = jsonDecode(str);
        } catch (e) {
          map = {};
        }
      }
    }
  }

  void registerTag(String tag) {
    if (!map["tags"].contains(tag)) map["tags"].add(tag);
    save();
  }

  void registerLevel(UserLevel level) {
    map['levels'].add(level.id);
    registerTag(level.tag);
  }

  void registerBlueprint(UserBlueprint blueprint) {
    map['blueprints'].add(blueprint.id);
    registerTag(blueprint.tag);
  }

  void registerServer(UserServer server) {
    map['servers'].add(server.id);
    registerTag(server.tag);
  }

  void removeLevel(UserLevel level) {
    (map['levels'] as List).remove(level.id);
    save();
  }

  void removeBlueprint(UserBlueprint blueprint) {
    (map['blueprints'] as List).remove(blueprint.id);
    save();
  }

  void removeServer(UserServer server) {
    (map['servers'] as List).remove(server.id);
    save();
  }

  void save() {
    if (!f.existsSync()) f.createSync(recursive: true);
    f.writeAsStringSync(jsonEncode(map));
  }

  void load() {
    try {
      map = jsonDecode(f.readAsStringSync());
    } catch (e) {
      map = {};
    }
  }

  bool validate(String pass) {
    final hash = sha256.convert(utf8.encode(pass)).toString();

    return map['passhash'] == hash;
  }

  void changePassword(String newpass) {
    final hash = sha256.convert(utf8.encode(newpass)).toString();

    map['passhash'] = hash;
    save();
  }
}
