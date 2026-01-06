import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/app_theme.dart';
import 'core/routes/app_routes.dart';
import 'features/splash/presentation/pages/splash_page.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/admin/presentation/bloc/admin_bloc.dart';
import 'features/manager/presentation/bloc/manager_bloc.dart';
import 'features/user/presentation/bloc/user_bloc.dart';
import 'features/security/presentation/bloc/security_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>(
          create: (context) => AuthRepository(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (context) => AuthBloc(
              authRepository: context.read<AuthRepository>(),
            )..add(CheckAuthStatusEvent()),
          ),
          BlocProvider<AdminBloc>(
            create: (context) => AdminBloc(),
          ),
          BlocProvider<ManagerBloc>(
            create: (context) => ManagerBloc(),
          ),
          BlocProvider<UserBloc>(
            create: (context) => UserBloc(),
          ),
          BlocProvider<SecurityBloc>(
            create: (context) => SecurityBloc(),
          ),
        ],
        child: MaterialApp(
          title: 'Apartment Management System',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: const SplashPage(),
          routes: AppRoutes.routes,
        ),
      ),
    );
  }
}

