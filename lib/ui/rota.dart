import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'splash.dart';
import 'linha.dart';

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
    // _obterCoordenadasGPS();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Map traçar Rota")),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            ListTile(
              trailing: Icon(Icons.chevron_left, size: 50),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(Icons.splitscreen),
              title: Text('Splash'),
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => Splash()),
              ),
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Traçar Linhas'),
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => Linha()),
              ),
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Traçar Rotas'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(Icons.exit_to_app),
              title: Text('Sair'),
              onTap: () => SystemNavigator.pop(),
            ),
          ],
        ),
      ),
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
    final pontos = PolylinePoints(apiKey: '');

    final result = await pontos.getRouteBetweenCoordinatesV2(
      request: RoutesApiRequest(
        origin: PointLatLng(_pontoInicial.latitude, _pontoInicial.longitude),
        destination: PointLatLng(
          _pontoClicado!.latitude,
          _pontoClicado!.longitude,
        ),
        travelMode: TravelMode.driving,
      ),
    );

    if (result.routes.isNotEmpty &&
        result.routes.first.polylinePoints != null) {
      final coordenadas = result.routes.first.polylinePoints!
          .map((p) => LatLng(p.latitude, p.longitude))
          .toList();

      if (mounted) {
        setState(() {
          _atualizarLinhas(coordenadas);
        });
      }
    } else {
      if (mounted) {
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
