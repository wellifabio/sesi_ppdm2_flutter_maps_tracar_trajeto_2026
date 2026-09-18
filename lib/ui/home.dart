import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'splash.dart';

class Home extends StatefulWidget {
  final Future<Position?> Function()? locationProvider;

  const Home({super.key, this.locationProvider});

  static List<LatLng> calcularRota(LatLng origem, LatLng destino) {
    return [origem, destino];
  }

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  Position? p;
  LatLng inicio = LatLng(-22.7130000, -46.8180000); //SESI Amparo
  LatLng? _pontoClicado;
  Set<Polyline> _rotas = {};
  bool isLoading = false;
  String mensagem = 'Destino: ';

  void atualizarRota() {
    if (_pontoClicado == null) {
      _rotas = {};
      return;
    }

    final pontos = Home.calcularRota(inicio, _pontoClicado!);
    _rotas = {
      Polyline(
        polylineId: const PolylineId('rota_destino'),
        points: pontos,
        color: Colors.blue,
        width: 5,
        jointType: JointType.round,
      ),
    };
  }

  @override
  void initState() {
    super.initState();
    // obterP();
  }

  Future<void> obterP() async {
    try {
      final provider = widget.locationProvider ?? obterCoordenadasGPS;
      p = await provider();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
          if (p != null) {
            inicio = LatLng(p!.latitude, p!.longitude);
          }
          if (_pontoClicado != null) {
            atualizarRota();
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Home")),
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
              title: Text('Home'),
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
            isLoading
                ? CircularProgressIndicator()
                : Text(
                    'Origem: @${p?.latitude ?? 'N/A'}, ${p?.longitude ?? 'N/A'}',
                  ),
            Text(mensagem),
            Expanded(
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: inicio,
                  zoom: 15.0,
                ),
                onTap: (LatLng latLng) {
                  setState(() {
                    _pontoClicado = latLng;
                    atualizarRota();
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
                    ? {Marker(markerId: MarkerId('inicio'), position: inicio)}
                    : {
                        Marker(markerId: MarkerId('inicio'), position: inicio),
                        Marker(
                          markerId: MarkerId('clicado'),
                          position: _pontoClicado!,
                        ),
                      },
                polylines: _rotas,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Position?> obterCoordenadasGPS() async {
    bool servicoAtivo;
    LocationPermission permissao;
    servicoAtivo = await Geolocator.isLocationServiceEnabled();
    if (!servicoAtivo) {
      return Future.error('O serviço de localização está desativado.');
    }
    permissao = await Geolocator.checkPermission();
    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();
      if (permissao == LocationPermission.denied) {
        if (!mounted) return null;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Permissão de localização negada.')),
        );
        return null;
      }
    }
    if (permissao == LocationPermission.deniedForever) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Permissão negada permanentemente. Altere nas configurações.',
          ),
        ),
      );
      return null;
    }
    Position position = await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(),
    );
    return position;
  }
}
