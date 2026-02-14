import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../utils/theme.dart';

// ═══════════════════════════════════════════════════════════════════
// TASK 1: Login Screen                                    ~30 min
// ═══════════════════════════════════════════════════════════════════
//
// WHAT YOU'LL LEARN:
//   - StatefulWidget vs StatelessWidget (and when to use which)
//   - TextEditingController for form fields
//   - Form validation with GlobalKey<FormState>
//   - Async operations in UI (loading state, error handling)
//   - Navigation with GoRouter
//
// REFERENCE: Look at register_screen.dart — it's the same pattern
//   but with an extra field. Your login screen is simpler.
//
// REQUIREMENTS:
//   1. Email field with validation (non-empty, contains @)
//   2. Password field with validation (non-empty, min 6 chars)
//   3. "Sign In" button that:
//      - Validates the form
//      - Shows a loading spinner while authenticating
//      - Calls authService.signIn(email, password)
//      - Shows error in a SnackBar if auth fails
//      - On success: GoRouter's redirect handles navigation (you
//        don't need to manually navigate)
//   4. Link to register page: context.go('/register')
//   5. App icon/title at the top for branding
//
// HINTS:
//   - Use ConsumerStatefulWidget (not StatefulWidget) because you
//     need ref.read(authServiceProvider) for the auth call
//   - Remember to dispose() your TextEditingControllers
//   - The loading state is local to this widget (use setState)
//   - Look at how register_screen.dart handles the try/catch
//
// ═══════════════════════════════════════════════════════════════════

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  // TODO: Create form key, controllers, loading state

  @override
  void dispose() {
    // TODO: Dispose controllers
    super.dispose();
  }

  Future<void> _signIn() async {
    // TODO: Implement sign in
    // 1. Validate form
    // 2. Set loading = true
    // 3. Call authService.signIn()
    // 4. Catch errors → show SnackBar
    // 5. Set loading = false in finally block
  }

  @override
  Widget build(BuildContext context) {
    // TODO: Build the login form UI
    //
    // Structure should be:
    //   Scaffold
    //     SafeArea
    //       Center
    //         SingleChildScrollView  (prevents keyboard overflow)
    //           Form
    //             Column
    //               Icon (Icons.security, size 64)
    //               Text "miAlarm"
    //               TextFormField (email)
    //               TextFormField (password, obscureText: true)
    //               ElevatedButton (Sign In / loading spinner)
    //               TextButton (link to register)

    return const Scaffold(
      body: Center(
        child: Text('TODO: Build login screen'),
      ),
    );
  }
}
