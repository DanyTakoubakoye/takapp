import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:takapp/controllers/auth_controller.dart';
import 'package:takapp/controllers/comptabilite_controller.dart';
import 'package:takapp/controllers/gerante_handover_controller.dart';
import 'package:takapp/controllers/handover_controller.dart';
import 'package:takapp/controllers/order_controller.dart';
import 'package:takapp/controllers/owner_dashboard_controller.dart';
import 'package:takapp/controllers/payment_controller.dart';
import 'package:takapp/controllers/serveur_controller.dart';
import 'package:takapp/core/themes/app_theme.dart';
import 'package:takapp/firebase_options.dart';
import 'package:takapp/services/auth_service.dart';
import 'package:takapp/services/comptabilite_service.dart';
import 'package:takapp/services/cuisine_service.dart';
import 'package:takapp/services/gerante_handover_service.dart';
import 'package:takapp/services/handover_service.dart';
import 'package:takapp/services/order_service.dart';
import 'package:takapp/services/owner_dashboard_service.dart';
import 'package:takapp/services/payment_service.dart';
import 'package:takapp/vues/commun/home_router.dart';
import 'package:takapp/services/pdf_service.dart';
import 'package:takapp/services/printer_service.dart';
import 'package:takapp/services/notification_service.dart';
import 'package:takapp/core/app_navigator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final authService = AuthService();
  final authController = AuthController(authService);
  await authController.initialize();
  final notificationService = NotificationService();
  await notificationService.init();

  runApp(MyApp(authController: authController));
}

class MyApp extends StatelessWidget {
  final AuthController authController;

  const MyApp({super.key, required this.authController});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthController>.value(value: authController),
        Provider<OrderService>(create: (_) => OrderService()),
        Provider<CuisineService>(create: (_) => CuisineService()),
        Provider<PaymentService>(create: (_) => PaymentService()),
        Provider<HandoverService>(create: (_) => HandoverService()),
        Provider<PdfService>(create: (_) => PdfService()),
        Provider<PrinterService>(create: (_) => PrinterService()),
        Provider<PdfService>(create: (_) => PdfService()),
        Provider<PrinterService>(create: (_) => PrinterService()),
        Provider<GeranteHandoverService>(
          create: (_) => GeranteHandoverService(),
        ),
        Provider<ComptabiliteService>(create: (_) => ComptabiliteService()),
        Provider<OwnerDashboardService>(create: (_) => OwnerDashboardService()),
        ChangeNotifierProxyProvider<OrderService, OrderController>(
          create: (context) => OrderController(context.read<OrderService>()),
          update: (context, orderService, previous) =>
              previous ?? OrderController(orderService),
        ),
        ChangeNotifierProxyProvider<PaymentService, PaymentController>(
          create: (context) =>
              PaymentController(context.read<PaymentService>()),
          update: (context, paymentService, previous) =>
              previous ?? PaymentController(paymentService),
        ),
        ChangeNotifierProvider(create: (_) => ServeurController()),
        ChangeNotifierProxyProvider<HandoverService, HandoverController>(
          create: (context) =>
              HandoverController(context.read<HandoverService>()),
          update: (context, handoverService, previous) =>
              previous ?? HandoverController(handoverService),
        ),
        ChangeNotifierProxyProvider<
          GeranteHandoverService,
          GeranteHandoverController
        >(
          create: (context) =>
              GeranteHandoverController(context.read<GeranteHandoverService>()),
          update: (context, service, previous) =>
              previous ?? GeranteHandoverController(service),
        ),
        ChangeNotifierProxyProvider<
          ComptabiliteService,
          ComptabiliteController
        >(
          create: (context) =>
              ComptabiliteController(context.read<ComptabiliteService>()),
          update: (context, service, previous) =>
              previous ?? ComptabiliteController(service),
        ),
        ChangeNotifierProxyProvider<
          OwnerDashboardService,
          OwnerDashboardController
        >(
          create: (context) =>
              OwnerDashboardController(context.read<OwnerDashboardService>()),
          update: (context, service, previous) =>
              previous ?? OwnerDashboardController(service),
        ),
      ],
      child: MaterialApp(
        navigatorKey: appNavigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'TAKHOTEL',
        theme: AppTheme.lightTheme,
        home: const HomeRouter(),
      ),
    );
  }
}
