import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import 'main_app.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.secondary.withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.sensors,
                      size: 80,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Smart Insole',
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Advanced Gait Analysis & Pressure Monitoring',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              // Tab Bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  tabs: const [
                    Tab(text: 'Sign In'),
                    Tab(text: 'Create Account'),
                  ],
                ),
              ),
              
              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _SignInTab(authService: _authService),
                    _CreateAccountTab(authService: _authService),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignInTab extends StatefulWidget {
  final AuthService authService;
  
  const _SignInTab({required this.authService});

  @override
  State<_SignInTab> createState() => _SignInTabState();
}

class _SignInTabState extends State<_SignInTab> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  Future<void> _signInWithGoogle() async {
    setState(() => _loading = true);
    final success = await widget.authService.signInWithGoogle();
    setState(() => _loading = false);
    
    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainApp()),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google sign-in failed')),
      );
    }
  }

  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _loading = true);
    final success = await widget.authService.signInWithEmail(
      email: _emailController.text,
      password: _passwordController.text,
    );
    setState(() => _loading = false);
    
    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainApp()),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid email or password')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Google Sign-In Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: _loading ? null : _signInWithGoogle,
                icon: Image.network(
                  'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                  width: 24,
                  height: 24,
                ),
                label: Text(
                  'Continue with Google',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Divider
            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey.shade300)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'or',
                    style: GoogleFonts.poppins(color: Colors.grey.shade600),
                  ),
                ),
                Expanded(child: Divider(color: Colors.grey.shade300)),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Email Field
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Please enter your email';
                if (!value.contains('@')) return 'Please enter a valid email';
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Password Field
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Please enter your password';
                if (value.length < 6) return 'Password must be at least 6 characters';
                return null;
              },
            ),
            
            const SizedBox(height: 24),
            
            // Sign In Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: _loading ? null : _signInWithEmail,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Sign In',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateAccountTab extends StatefulWidget {
  final AuthService authService;
  
  const _CreateAccountTab({required this.authService});

  @override
  State<_CreateAccountTab> createState() => _CreateAccountTabState();
}

class _CreateAccountTabState extends State<_CreateAccountTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _loading = false;

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _loading = true);
    final success = await widget.authService.createLocalAccount(
      name: _nameController.text,
      email: _emailController.text,
      password: _passwordController.text,
    );
    setState(() => _loading = false);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created successfully!')),
      );
      // Switch to sign-in tab
      DefaultTabController.of(context).animateTo(0);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create account')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Name Field
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Full Name',
                prefixIcon: const Icon(Icons.person_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Please enter your name';
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Email Field
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Please enter your email';
                if (!value.contains('@')) return 'Please enter a valid email';
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Password Field
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Please enter a password';
                if (value.length < 6) return 'Password must be at least 6 characters';
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Confirm Password Field
            TextFormField(
              controller: _confirmPasswordController,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: const Icon(Icons.lock_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Please confirm your password';
                if (value != _passwordController.text) return 'Passwords do not match';
                return null;
              },
            ),
            
            const SizedBox(height: 24),
            
            // Create Account Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: _loading ? null : _createAccount,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Create Account',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
