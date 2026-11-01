import 'package:flutter/material.dart';
import 'api.dart';
import 'main.dart';
import 'poster_wall.dart';

void goHome(BuildContext context) {
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => const MainShell()),
    (route) => false,
  );
}

void snack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}

String? emailCheck(String? v) {
  if (v == null || !v.contains('@') || !v.contains('.')) {
    return 'Sahi email daalo';
  }
  return null;
}

String? passCheck(String? v) {
  if (v == null || v.length < 6) return 'Kam se kam 6 akshar';
  return null;
}

class Spin extends StatelessWidget {
  const Spin({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox(
      height: 20,
      width: 20,
      child: CircularProgressIndicator(strokeWidth: 2));
}

class AuthField extends StatelessWidget {
  final String label;
  final IconData icon;
  final TextEditingController controller;
  final bool obscure;
  final TextInputType? type;
  final String? Function(String?)? validator;
  final Widget? suffix;
  const AuthField({
    super.key,
    required this.label,
    required this.icon,
    required this.controller,
    this.obscure = false,
    this.type,
    this.validator,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: type,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon: suffix,
          filled: true,
          fillColor: const Color(0x99000000),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
        ),
      ),
    );
  }
}

class AuthShell extends StatelessWidget {
  final Widget child;
  final bool back;
  const AuthShell({super.key, required this.child, this.back = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const PosterWall(),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xB3000000), Color(0xE6000000)],
              ),
            ),
          ),
          SafeArea(
            child: Stack(
              children: [
                child,
                if (back)
                  Positioned(
                    left: 4,
                    top: 4,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget authCard(List<Widget> children) {
  return Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: const Color(0xCC0B0B0F),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white12),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    ),
  );
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _hide = true, _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await Api.login(_email.text.trim(), _pass.text);
      if (!mounted) return;
      goHome(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      snack(context, '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _form,
            child: authCard([
              const Text('CINEVORA',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                      color: kRed)),
              const SizedBox(height: 6),
              const Text('Welcome back! Login karo',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 24),
              AuthField(
                  label: 'Email',
                  icon: Icons.email_outlined,
                  controller: _email,
                  type: TextInputType.emailAddress,
                  validator: emailCheck),
              AuthField(
                label: 'Password',
                icon: Icons.lock_outline,
                controller: _pass,
                obscure: _hide,
                validator: passCheck,
                suffix: IconButton(
                  icon: Icon(_hide ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _hide = !_hide),
                ),
              ),
              const SizedBox(height: 4),
              FilledButton(
                onPressed: _loading ? null : _submit,
                style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50)),
                child: _loading ? const Spin() : const Text('Login'),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Naya user?'),
                  TextButton(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RegisterScreen())),
                    child: const Text('Register karo'),
                  ),
                ],
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _pass2 = TextEditingController();
  bool _hide = true, _agree = false, _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pass.dispose();
    _pass2.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (!_agree) {
      snack(context, 'Terms & Privacy Policy accept karo');
      return;
    }
    setState(() => _loading = true);
    try {
      await Api.register(_name.text.trim(), _email.text.trim(), _pass.text);
      if (!mounted) return;
      goHome(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      snack(context, '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      back: true,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
          child: Form(
            key: _form,
            child: authCard([
              const Text('Account banao',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              const Text('CineVora Films me aapka swagat hai',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 20),
              AuthField(
                label: 'Full name',
                icon: Icons.person_outline,
                controller: _name,
                validator: (v) =>
                    (v == null || v.trim().length < 2) ? 'Naam daalo' : null,
              ),
              AuthField(
                  label: 'Email',
                  icon: Icons.email_outlined,
                  controller: _email,
                  type: TextInputType.emailAddress,
                  validator: emailCheck),
              AuthField(
                label: 'Password',
                icon: Icons.lock_outline,
                controller: _pass,
                obscure: _hide,
                validator: passCheck,
                suffix: IconButton(
                  icon: Icon(_hide ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _hide = !_hide),
                ),
              ),
              AuthField(
                label: 'Confirm password',
                icon: Icons.lock_outline,
                controller: _pass2,
                obscure: _hide,
                validator: (v) =>
                    v != _pass.text ? 'Password match nahi hua' : null,
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _agree,
                onChanged: (v) => setState(() => _agree = v ?? false),
                title: const Text('Main Terms & Privacy Policy se sehmat hu',
                    style: TextStyle(fontSize: 13)),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _loading ? null : _submit,
                style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50)),
                child: _loading ? const Spin() : const Text('Create account'),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
