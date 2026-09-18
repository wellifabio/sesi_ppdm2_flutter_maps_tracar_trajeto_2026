import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_maps_tracar_trajeto/ui/home.dart';

void main() {
  test('deve montar a rota direta entre origem e destino', () {
    const origem = LatLng(-22.7130000, -46.8180000);
    const destino = LatLng(-22.7200000, -46.8300000);

    final rota = Home.calcularRota(origem, destino);

    expect(rota, [origem, destino]);
  });
}
