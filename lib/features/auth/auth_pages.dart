import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/firebase_gate.dart';
import '../../core/widgets.dart';
import '../../data/local_store.dart';

void openLogin(BuildContext context) {
  Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => const LoginPage()));
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    final ok = runStore(context, () {
      context.read<LocalAppStore>().login(
        email: _email.text,
        password: _password.text,
      );
    });
    if (ok && mounted) Navigator.of(context).pop();
  }

  void _providerUnavailable(String provider) {
    showAppFeedback(
      context,
      '$provider is not completed. ${FirebaseGate.status}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const BrandWordmark(width: 140)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Sign in', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Preview account: ${LocalAppStore.fixtureEmail} · ${LocalAppStore.fixturePassword}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Text(betaNotice, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 20),
          AppTextField(
            label: 'Email',
            controller: _email,
            fieldKey: const Key('email'),
          ),
          const SizedBox(height: 12),
          AppTextField(
            label: 'Password',
            controller: _password,
            obscure: true,
            fieldKey: const Key('password'),
          ),
          const SizedBox(height: 16),
          AppButton(
            key: const Key('sign-in'),
            label: 'Sign in',
            onPressed: _submit,
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ForgotPasswordPage(),
                ),
              );
            },
            child: const Text('Forgot password'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const RegisterPage()),
              );
            },
            child: const Text('Create an account'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => _providerUnavailable('Google Sign-In'),
            child: const Text('Continue with Google'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => _providerUnavailable('Facebook login'),
            child: const Text('Continue with Facebook'),
          ),
        ],
      ),
    );
  }
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    final ok = runStore(context, () {
      context.read<LocalAppStore>().register(
        email: _email.text,
        password: _password.text,
        displayName: _name.text,
        username: _username.text,
      );
    });
    if (!ok || !mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const VerifyEmailPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('An account cannot choose an administrator role.'),
          const SizedBox(height: 16),
          AppTextField(label: 'Display name', controller: _name),
          const SizedBox(height: 12),
          AppTextField(label: 'Username', controller: _username),
          const SizedBox(height: 12),
          AppTextField(label: 'Email', controller: _email),
          const SizedBox(height: 12),
          AppTextField(label: 'Password', controller: _password, obscure: true),
          const SizedBox(height: 16),
          AppButton(label: 'Create account', onPressed: _submit),
        ],
      ),
    );
  }
}

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  bool _requested = false;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<LocalAppStore>();
    return Scaffold(
      appBar: AppBar(title: const Text('Reset password')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const AppCard(
            child: Text(
              'Local adapter only. No email is sent. A real reset requires Firebase Authentication.',
            ),
          ),
          const SizedBox(height: 16),
          AppTextField(label: 'Email', controller: _email),
          const SizedBox(height: 12),
          AppButton(
            label: 'Request code',
            onPressed: () {
              final ok = runStore(
                context,
                () => store.requestPasswordReset(_email.text),
              );
              if (ok) setState(() => _requested = true);
            },
          ),
          if (_requested && store.pendingResetCode != null) ...[
            const SizedBox(height: 16),
            Text('Local code (not emailed): ${store.pendingResetCode}'),
            const SizedBox(height: 12),
            AppTextField(label: 'Code', controller: _code),
            const SizedBox(height: 12),
            AppTextField(
              label: 'New password',
              controller: _password,
              obscure: true,
            ),
            const SizedBox(height: 12),
            AppButton(
              label: 'Update password',
              onPressed: () {
                final ok = runStore(context, () {
                  store.completePasswordReset(
                    code: _code.text,
                    newPassword: _password.text,
                  );
                });
                if (ok && mounted) {
                  showAppFeedback(
                    context,
                    'Password updated. Sign in with the new password.',
                  );
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        ],
      ),
    );
  }
}

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<LocalAppStore>();
    return Scaffold(
      appBar: AppBar(title: const Text('Verify email')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const AppCard(
            child: Text(
              'Local adapter only. This code was not emailed. Firebase Authentication is required to send it.',
            ),
          ),
          const SizedBox(height: 12),
          Text('Code: ${store.pendingVerificationCode ?? '—'}'),
          const SizedBox(height: 12),
          AppTextField(
            label: 'Verification code',
            controller: _code,
            fieldKey: const Key('verify-code'),
          ),
          const SizedBox(height: 12),
          AppButton(
            label: 'Confirm email',
            onPressed: () {
              final ok = runStore(
                context,
                () => store.confirmEmail(_code.text),
              );
              if (ok && context.mounted) Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
