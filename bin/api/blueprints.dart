import 'dart:convert';
import 'dart:math';

import 'package:shelf_plus/shelf_plus.dart';

import '../db/blueprints.dart';
import '../tpc_content_hub.dart';

void loadBlueprintsRoutes(RouterPlus router) {
  router.post('/blueprints/upload', (Request request) {
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

    final blueprint = UserBlueprint.create(author, name, code, tag);

    author.registerBlueprint(blueprint);
    author.registerTag(blueprint.tag);

    return Response.ok(blueprint.id);
  });

  router.get('/blueprints/download/<id>', (Request request, String id) {
    if (!UserBlueprint.exists(id)) return Response.notFound('Unable to find requested blueprint');

    final blueprint = UserBlueprint(id);
    blueprint.downloads++;
    blueprint.save();

    return Response.ok(blueprint.code);
  });

  router.delete('/blueprints/delete/<id>', (Request request, String id) {
    if (!UserBlueprint.exists(id)) return Response.notFound('Requested blueprint already does not exist');

    final session = request.headers['session'];

    if (session == null) return Response.badRequest();

    final user = sessions[session];

    if (user == null) return Response.unauthorized('Provided session already expired');

    final blueprint = UserBlueprint(id);

    if (blueprint.author.id != user.id) return Response.forbidden('You are unable to delete a blueprint made by someone else');

    blueprint.author.removeBlueprint(blueprint);

    UserBlueprint.delete(id);

    return Response.ok('Blueprint has been deleted');
  });

  router.get('/blueprints/get/<id>', (Request request, String id) {
    if (!UserBlueprint.exists(id)) return Response.notFound('Requested blueprint does not exist');

    final blueprint = UserBlueprint(id);

    final output = jsonEncode({
      "name": blueprint.name,
      "downloads": blueprint.downloads,
      "author": blueprint.author.id,
      "tag": blueprint.tag,
    });

    return Response.ok(output, headers: {'Content-Type': 'application/json; charset=utf-8'});
  });

  router.get('/top-blueprints', (Request request) {
    var blueprints = UserBlueprint.all();

    if (blueprints.isEmpty) return Response.ok('[]', headers: {'Content-Type': 'application/json; charset=utf-8'});

    blueprints.sort((a, b) {
      return b.downloads.compareTo(a.downloads);
    });

    blueprints = blueprints.sublist(0, min(blueprints.length, 100));

    final blueprintsObj = [];

    for (var bp in blueprints) {
      blueprintsObj.add({
        "name": bp.name,
        "downloads": bp.downloads,
        "author": bp.author.id,
        "id": bp.id,
        "tag": bp.tag,
      });
    }

    final out = jsonEncode(blueprintsObj);

    return Response.ok(out, headers: {'Content-Type': 'application/json; charset=utf-8'});
  });

  router.get('/all-blueprints', (Request request) {
    var blueprints = UserBlueprint.all();

    if (blueprints.isEmpty) return Response.ok('[]', headers: {'Content-Type': 'application/json; charset=utf-8'});

    blueprints.sort((a, b) {
      return b.downloads.compareTo(a.downloads);
    });

    final bpObj = [];

    for (var bp in blueprints) {
      bpObj.add({
        "name": bp.name,
        "downloads": bp.downloads,
        "author": bp.author.id,
        "id": bp.id,
        "tag": bp.tag,
      });
    }

    final out = jsonEncode(bpObj);

    return Response.ok(out, headers: {'Content-Type': 'application/json; charset=utf-8'});
  });
}
