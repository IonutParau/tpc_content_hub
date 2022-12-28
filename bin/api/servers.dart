import 'dart:convert';
import 'dart:math';

import 'package:shelf_plus/shelf_plus.dart';

import '../db/servers.dart';
import '../tpc_content_hub.dart';

void loadServersRoutes(RouterPlus router) {
  router.post('/servers/upload', (Request request) {
    final session = request.headers['session'];
    final name = request.headers['name'];
    final ip = request.headers['ip'];
    final tag = request.headers['tag'];

    if (session == null || name == null || ip == null || tag == null) {
      return Response.badRequest();
    }

    final author = sessions[session];

    if (author == null) {
      return Response.unauthorized('Specified Session ID expired or never existed');
    }

    final server = UserServer.create(author, name, ip, tag);

    author.registerServer(server);

    return Response.ok(server.id);
  });

  router.get('/servers/join/<id>', (Request request, String id) {
    if (!UserServer.exists(id)) return Response.notFound('Unable to find requested server');

    final server = UserServer(id);
    server.joins++;
    server.save();

    return Response.ok(server.ip);
  });

  router.delete('/servers/delete/<id>', (Request request, String id) {
    if (!UserServer.exists(id)) return Response.notFound('Requested server already does not exist');

    final session = request.headers['session'];

    if (session == null) return Response.badRequest();

    final user = sessions[session];

    if (user == null) return Response.unauthorized('Provided session already expired');

    final server = UserServer(id);

    if (server.author.id != user.id) return Response.forbidden('You are unable to delete a server posted by someone else');

    server.author.removeServer(server);

    UserServer.delete(id);

    return Response.ok('Server has been deleted');
  });

  router.get('/servers/get/<id>', (Request request, String id) {
    if (!UserServer.exists(id)) return Response.notFound('Requested server does not exist');

    final blueprint = UserServer(id);

    final output = jsonEncode({
      "name": blueprint.name,
      "joins": blueprint.joins,
      "author": blueprint.author.id,
      "tag": blueprint.tag,
    });

    return Response.ok(output, headers: {'Content-Type': 'application/json; charset=utf-8'});
  });

  router.get('/top-servers', (Request request) {
    var servers = UserServer.all();

    if (servers.isEmpty) return Response.ok('[]', headers: {'Content-Type': 'application/json; charset=utf-8'});

    servers.sort((a, b) {
      return b.joins.compareTo(a.joins);
    });

    servers = servers.sublist(0, min(servers.length, 100));

    final serversObj = [];

    for (var bp in servers) {
      serversObj.add({
        "name": bp.name,
        "joins": bp.joins,
        "author": bp.author.id,
        "id": bp.id,
        "tag": bp.tag,
      });
    }

    final out = jsonEncode(serversObj);

    return Response.ok(out, headers: {'Content-Type': 'application/json; charset=utf-8'});
  });

  router.get('/all-servers', (Request request) {
    var servers = UserServer.all();

    if (servers.isEmpty) return Response.ok('[]', headers: {'Content-Type': 'application/json; charset=utf-8'});

    servers.sort((a, b) {
      return b.joins.compareTo(a.joins);
    });

    final bpObj = [];

    for (var bp in servers) {
      bpObj.add({
        "name": bp.name,
        "joins": bp.joins,
        "author": bp.author.id,
        "id": bp.id,
        "tag": bp.tag,
      });
    }

    final out = jsonEncode(bpObj);

    return Response.ok(out, headers: {'Content-Type': 'application/json; charset=utf-8'});
  });
}
