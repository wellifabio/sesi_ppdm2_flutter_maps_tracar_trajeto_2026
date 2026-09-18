import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import 'splash.dart';

class Home extends StatefulWidget {
  const new({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  Position? p;

  @override
  initState() async {
    p = await obterCoordenadasGPS();
    super.initState();
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (p != null)
              CircularProgressIndicator()
            else
              Text(
                'Você está em \nlatitude: $p.latitude \nlongitude: $p.longitude',
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
