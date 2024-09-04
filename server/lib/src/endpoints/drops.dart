import 'dart:math';
import 'package:serverpod/serverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:soundscapes_server/src/generated/quad.dart';
import 'package:soundscapes_server/src/generated/drop.dart';

const _scanRadiusInMeters = 1000;
const _metersPerLatDegree = 111320;

class DropsEndpoint extends Endpoint {
  Future<List<Drop>> scan(Session session, LatLng point) async {
    final quads = _getContainingQuads(point, _scanRadiusInMeters).toList();
    final drops = <Drop>[];
    for (var quad in quads) {
      List<Drop> quadDrops;
      final existing = await Quad.db.findFirstRow(session,
          where: (row) => row.lat.equals(quad.lat) & row.lng.equals(quad.lng));
      if (existing == null) {
        quad = await Quad.db.insertRow(session, quad);
        quadDrops =
            await Drop.db.insert(session, _generateQuadDrops(quad).toList());
      } else {
        quad = existing;
        quadDrops = await Drop.db
            .find(session, where: (row) => row.quadId.equals(quad.id!));
      }
      drops.addAll(quadDrops);
    }

    return drops;
  }

  static Iterable<Drop> _generateQuadDrops(Quad quad) sync* {
    final random = Random();
    for (int i = 0; i < 10; i++) {
      final lat = (quad.lat + random.nextDouble()) / 60;
      final lng = (quad.lng + random.nextDouble()) / 60;
      yield Drop(
          lat: lat,
          lng: lng,
          special: random.nextDouble() < 0.10,
          quadId: quad.id!);
    }
  }

  static Iterable<Quad> _getContainingQuads(LatLng center, int radius) sync* {
    final halfSideLat = radius / _metersPerLatDegree;
    final halfSideLng =
        radius / (_metersPerLatDegree * cos(center.latitudeInRad));

    int toMinutes(double coord) => (coord * 60).floor();
    final minLat = toMinutes(center.latitude - halfSideLat);
    final maxLat = toMinutes(center.latitude + halfSideLat);
    final minLng = toMinutes(center.longitude - halfSideLng);
    final maxLng = toMinutes(center.longitude + halfSideLng);

    for (int lat = minLat; lat <= maxLat; lat++) {
      for (int lng = minLng; lng <= maxLng; lng++) {
        yield Quad(lat: lat, lng: lng);
      }
    }
  }
}
