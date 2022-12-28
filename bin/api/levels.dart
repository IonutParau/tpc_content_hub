import 'dart:convert';
import 'dart:math';

import 'package:shelf_plus/shelf_plus.dart';

import '../db/levels.dart';
import '../tpc_content_hub.dart';

void loadLevelsRoutes(RouterPlus router) {
  router.post('/levels/upload', (Request request) {
    final session = request.headers['session'];
    final name = request.headers['name'];
    final code = request.headers['code'];
    final tag = request.headers['tag'];

    if (session == null || name == null || code == null || tag == null) {
      return Response.badRequest();
    }

    final author = sessions[session];

    if (author == null) {
      return Response.unauthorized('Specified Session ID expired or never existed');
    }

    final level = UserLevel.create(author, name, code, tag);

    author.registerLevel(level);

    return Response.ok(level.id);
  });

  router.get('/levels/download/<id>', (Request request, String id) {
    if (!UserLevel.exists(id)) return Response.notFound('Unable to find requested level');

    final level = UserLevel(id);
    level.downloads++;
    level.save();

    return Response.ok(level.code);
  });

  router.delete('/levels/delete/<id>', (Request request, String id) {
    if (!UserLevel.exists(id)) return Response.notFound('Requested level already does not exist');

    final session = request.headers['session'];

    if (session == null) return Response.badRequest();

    final user = sessions[session];

    if (user == null) return Response.unauthorized('Provided session already expired');

    final level = UserLevel(id);

    if (level.author.id != user.id) return Response.forbidden('You are unable to delete a level made by someone else');

    level.author.removeLevel(level);

    UserLevel.delete(id);

    return Response.ok('Level has been deleted');
  });

  router.get('/levels/get/<id>', (Request request, String id) {
    if (!UserLevel.exists(id)) return Response.notFound('Requested level does not exist');

    final level = UserLevel(id);

    final output = jsonEncode({
      "name": level.name,
      "downloads": level.downloads,
      "author": level.author.id,
      "tag": level.tag,
    });

    return Response.ok(output, headers: {'Content-Type': 'application/json; charset=utf-8'});
  });

  router.get('/top-levels', (Request request) {
    var levels = UserLevel.all();

    if (levels.isEmpty) return Response.ok('[]', headers: {'Content-Type': 'application/json; charset=utf-8'});

    levels.sort((a, b) {
      return b.downloads.compareTo(a.downloads);
    });

    levels = levels.sublist(0, min(levels.length, 100));

    final levelsObj = [];

    for (var level in levels) {
      levelsObj.add({
        "name": level.name,
        "downloads": level.downloads,
        "author": level.author.id,
        "id": level.id,
        "tag": level.tag,
      });
    }

    final out = jsonEncode(levelsObj);

    return Response.ok(out, headers: {'Content-Type': 'application/json; charset=utf-8'});
  });

  router.get('/all-levels', (Request request) {
    var levels = UserLevel.all();

    if (levels.isEmpty) return Response.ok('[]', headers: {'Content-Type': 'application/json; charset=utf-8'});

    levels.sort((a, b) {
      return b.downloads.compareTo(a.downloads);
    });

    final levelsObj = [];

    for (var level in levels) {
      levelsObj.add({
        "name": level.name,
        "downloads": level.downloads,
        "author": level.author.id,
        "id": level.id,
        "tag": level.tag,
      });
    }

    final out = jsonEncode(levelsObj);

    return Response.ok(out, headers: {'Content-Type': 'application/json; charset=utf-8'});
  });
}
