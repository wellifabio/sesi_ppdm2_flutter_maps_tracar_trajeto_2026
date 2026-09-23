import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'widgets/menu.dart';

class Rota extends StatefulWidget {
  const Rota({super.key});

  @override
  State<Rota> createState() => _RotaState();
}

class _RotaState extends State<Rota> {
  final LatLng _pontoInicial = LatLng(-22.7130000, -46.8180000); //SESI Amparo
  LatLng? _pontoClicado;
  Set<Polyline> _linhas = {};
  String mensagem = 'Destino: Clique em um ponto no mapa';

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Map traçar Rota")),
      drawer: Menu.ops(context),
      body: Center(
        child: Column(
          children: [
            Text(
              'Origem: @${_pontoInicial.latitude}, ${_pontoInicial.longitude}',
            ),
            Text(mensagem),
            Expanded(
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _pontoInicial,
                  zoom: 15.0,
                ),
                onTap: (LatLng latLng) {
                  setState(() {
                    _pontoClicado = latLng;
                    _obterRota();
                    mensagem =
                        'Destino: @${latLng.latitude.toStringAsFixed(7)}, ${latLng.longitude.toStringAsFixed(7)}';
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Latitude: ${latLng.latitude}, Longitude: ${latLng.longitude}',
                      ),
                      duration: Duration(seconds: 3),
                    ),
                  );
                },
                markers: _pontoClicado == null
                    ? {
                        Marker(
                          markerId: MarkerId('_pontoInicial'),
                          position: _pontoInicial,
                          infoWindow: InfoWindow(title: 'Origem'),
                        ),
                      }
                    : {
                        Marker(
                          markerId: MarkerId('_pontoInicial'),
                          position: _pontoInicial,
                          infoWindow: InfoWindow(title: 'Origem'),
                        ),
                        Marker(
                          markerId: MarkerId('clicado'),
                          position: _pontoClicado!,
                          infoWindow: InfoWindow(title: 'Destino'),
                        ),
                      },
                polylines: _linhas,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _atualizarLinhas(List<LatLng> rota) {
    if (_pontoClicado == null) {
      _linhas = {};
      return;
    }
    _linhas = {
      Polyline(
        polylineId: PolylineId('rota_destino'),
        points: rota,
        color: Colors.blue,
        width: 5,
        jointType: JointType.round,
      ),
    };
  }

  Future<void> _obterRota() async {
    final pontos = PolylinePoints.legacy('API_KEYd');

    // ignore: deprecated_member_use
    final result = await pontos.getRouteBetweenCoordinates(
      request: PolylineRequest(
        origin: PointLatLng(_pontoInicial.latitude, _pontoInicial.longitude),
        destination: PointLatLng(
          _pontoClicado!.latitude,
          _pontoClicado!.longitude,
        ),
        mode: TravelMode.driving,
      ),
    );

    if (result.points.isNotEmpty) {
      final coordenadas = result.points
          .map((p) => LatLng(p.latitude, p.longitude))
          .toList();

      if (mounted) {
        setState(() {
          _atualizarLinhas(coordenadas);
        });
      }
    } else {
      if (mounted) {
        debugPrint(result.errorMessage);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erro ao buscar rota na API: ${result.errorMessage ?? 'Sem rota disponível'}',
            ),
          ),
        );
      }
    }
  }
}
