import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:get/instance_manager.dart';
import 'package:shorts_app/controller/api/api_controller.dart';
import 'package:shorts_app/controller/auth/main_auth_controller.dart';
import 'package:shorts_app/firebase_options.dart';
import 'package:shorts_app/screen/home/home_screen.dart';
import 'package:shorts_app/screen/navigation/navigation.dart';
import 'package:shorts_app/screen/onboard/splash_screen.dart';
import 'package:shorts_app/service/authentication.dart';
import 'package:shorts_app/service/calling_service.dart';
import 'package:shorts_app/service/chat_service.dart';
import 'package:shorts_app/service/deep_link_service.dart';
import 'package:shorts_app/service/notificationService.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  Get.put(ApiController(), permanent: true);

  await Get.putAsync(() async => AuthenticationService());
  Get.put(MainAuthController(), permanent: true);

  final chatService = Get.put(ChatService());
  Get.put(CallingService());
  Get.put(DeepLinkService());

  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser != null) {
    chatService.connect(currentUser.uid);
  }

  await NotificationService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      initialBinding: HomeBinding(),
      home: const AuthChecker(), 
    );
  }
}

class AuthChecker extends StatefulWidget {
  const AuthChecker({super.key});

  @override
  State<AuthChecker> createState() => _AuthCheckerState();
}

class _AuthCheckerState extends State<AuthChecker> {
  final AuthenticationService auth = Get.find();
  bool servicesInitialized = false;

  @override
  void initState() {
    super.initState();
    servicesIfNeeded();
  }

  void servicesIfNeeded() {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user != null && !servicesInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          final chatService = Get.find<ChatService>();
          final callingService = Get.find<CallingService>();

          chatService.connect(user.uid);
          callingService.init(sharedSocket: chatService.socket, userId: user.uid);

          setState(() {
            servicesInitialized = true;
          });
          print('Services initialized for user: ${user.uid}');
        } catch (e) {
          print('error: $e');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final user = auth.user.value;


      if (user == null) {
        if (servicesInitialized) {
          setState(() {
            servicesInitialized = false;
          });
        }
        return const SplashScreen();
      } else {
        if (!servicesInitialized) {
          servicesIfNeeded();
        }
        return Navigation();
      }
    });
  }
}