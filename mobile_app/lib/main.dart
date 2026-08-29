import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/message_repository_impl.dart';
import 'data/repositories/node_repository_impl.dart';
import 'presentation/providers/mesh_state_provider.dart';
import 'presentation/screens/splash/splash_screen.dart';
import 'services/mesh_network_manager.dart';
import 'services/security/identity_service.dart';
import 'services/transport/simulated_transport.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Core Services Setup
  final identityService = IdentityService();
  final messageRepository = MessageRepositoryImpl();
  final nodeRepository = NodeRepositoryImpl();
  final transport = SimulatedMeshTransport();

  // 2. Mesh Network Manager
  final networkManager = MeshNetworkManager(
    identityService: identityService,
    messageRepository: messageRepository,
    nodeRepository: nodeRepository,
    transport: transport,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => MeshStateProvider(networkManager: networkManager),
        ),
      ],
      child: const MeshLinkApp(),
    ),
  );
}

class MeshLinkApp extends StatelessWidget {
  const MeshLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MeshLink',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}
