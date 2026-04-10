import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'pages/login_page.dart';
import 'pages/admin_page.dart';
import 'pages/guru_page.dart';
// import 'pages/wali_kelas_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      home: const AuthCheck(),
    );
  }
}

class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  bool isLoading = true;
  String? role;
  String? name;

  @override
  void initState() {
    super.initState();
    checkLogin();
  }

  Future<void> checkLogin() async {
    final loggedIn = await AuthService.isLoggedIn();
    final userRole = await AuthService.getRole();
    final userName = await AuthService.getName();

    if (!mounted) return;

    if (!loggedIn || userRole == null || userName == null) {
      setState(() {
        isLoading = false;
        role = null;
        name = null;
      });
      return;
    }

    setState(() {
      role = userRole;
      name = userName;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (role == null) {
      return const LoginPage();
    }

    switch (role) {
      case "admin":
        return AdminPage(nama: name ?? "-", role: role ?? "-");
      case "guru":
        return GuruPage(nama: name ?? "-", role: role ?? "-");
      // case "wali":
      //   return const WaliKelasPage();

      default:
        return const LoginPage();
    }
  }
}
