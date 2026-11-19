import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:card_design/view/login_view.dart';
import 'package:card_design/viewmodel/login_viewmodel.dart';
import 'package:card_design/viewmodel/register_viewmodel.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  static const Color _bgColor = Color(0xFFFFFFFF);
  static const Color _primaryColor = Color(0xFF4D41DF);
  static const Color _primaryContainer = Color(0xFF675DF9);
  static const Color _secondaryColor = Color(0xFF564CC6);
  static const Color _secondaryContainer = Color(0xFF8C84FF);
  static const Color _onSurface = Color(0xFF1A1B1E);
  static const Color _onSurfaceVariant = Color(0xFF464555);
  static const Color _outline = Color(0xFF777587);
  static const Color _surfaceLow = Color(0xFFF4F3F7);
  static const Color _surfaceHigh = Color(0xFFE9E7EB);
  static const Color _surfaceHighest = Color(0xFFE3E2E6);
  static const Color _errorColor = Color(0xFFBA1A1A);

  static const String _logoUrl =
      'https://lh3.googleusercontent.com/aida/ALJJyrD1UFzkkZYm7XQJghRL2WUJBFi1bID3MkQgXjUxNZjOAOXbzdldkmw879pbeem8xv-iBk3Z4ASBpKHVDmvrv_oGqpgpcCvrrDNxgTTLqq5chriydUhZcMlCpf4MugPMUSRjrZtvKWXMcmFLdulpKOMEGOTkD3Uv-ovbb-O71bWf5B5CzNPbegB0IP0JHJFHlC6dg5aRXTVVh9VTob3qdfUdyCKdXWRyUZgvsLeyZ4vz';

  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _nameFocus = FocusNode();
  final _usernameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTerms = false;

  String _usernameInput = '';
  String _passwordInput = '';

  @override
  void initState() {
    super.initState();
    for (final node in [
      _nameFocus,
      _usernameFocus,
      _emailFocus,
      _passwordFocus,
      _confirmPasswordFocus,
    ]) {
      node.addListener(() {
        if (mounted) setState(() {});
      });
    }
    _usernameController.addListener(() {
      if (mounted) {
        setState(() => _usernameInput = _usernameController.text.trim());
      }
    });
    _passwordController.addListener(() {
      if (mounted) {
        setState(() => _passwordInput = _passwordController.text);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocus.dispose();
    _usernameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  bool _isUsernameTaken(String username) {
    final normalized = username.trim().toLowerCase();
    if (normalized.isEmpty) return false;
    LoginViewModel.ensureStorageLoaded();
    return LoginViewModel.localAccounts.values.any(
      (acc) => (acc['username']?.toString() ?? '').toLowerCase() == normalized,
    );
  }

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if ([name, username, email, password, confirmPassword]
        .any((value) => value.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua field wajib diisi.')),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password minimal 6 karakter.')),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konfirmasi password tidak cocok.')),
      );
      return;
    }

    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Harap setujui Terms of Service dan Privacy Policy terlebih dahulu.',
          ),
        ),
      );
      return;
    }

    final vm = context.read<RegisterViewModel>();
    final success = await vm.register(
      name: name,
      username: username,
      email: email,
      password: password,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(vm.successMessage ?? 'Registrasi berhasil.')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginView()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(vm.errorMessage ?? 'Registrasi gagal.')),
      );
    }
  }

  void _showPolicyDialog(String title, String body) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: const TextStyle(
            color: _onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: Text(
          body,
          style: const TextStyle(color: _onSurfaceVariant, fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Tutup',
              style: TextStyle(
                color: _primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderLogo() {
    return Stack(
      alignment: Alignment.topCenter,
      clipBehavior: Clip.none,
      children: [
        // Ambient glow behind logo
        Container(
          width: 112,
          height: 112,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                _primaryColor.withValues(alpha: 0.14),
                _primaryColor.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 80,
                height: 80,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _bgColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    _logoUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: const LinearGradient(
                            colors: [_primaryColor, _primaryContainer],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Z',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                bottom: -4,
                right: -4,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [_primaryColor, _secondaryContainer],
                      begin: Alignment.bottomLeft,
                      end: Alignment.topRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _primaryColor.withValues(alpha: 0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    Widget? labelTrailing,
    required TextEditingController controller,
    required FocusNode focusNode,
    required IconData prefixIcon,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    bool obscureText = false,
    Widget? suffixIcon,
    ValueChanged<String>? onSubmitted,
  }) {
    final isFocused = focusNode.hasFocus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _onSurfaceVariant,
                  letterSpacing: 0.12,
                ),
              ),
              ?labelTrailing,
            ],
          ),
        ),
        const SizedBox(height: 6),
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: isFocused ? _bgColor : _surfaceLow,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isFocused
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
            border: isFocused
                ? Border.all(
                    color: _primaryColor.withValues(alpha: 0.25),
                    width: 1,
                  )
                : null,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
          child: Row(
            children: [
              Icon(
                prefixIcon,
                size: 20,
                color: isFocused ? _primaryColor : _outline,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType: keyboardType,
                  textInputAction: textInputAction,
                  obscureText: obscureText,
                  onSubmitted: onSubmitted,
                  style: const TextStyle(
                    fontSize: 15,
                    color: _onSurface,
                  ),
                  cursorColor: _primaryColor,
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: TextStyle(
                      fontSize: 15,
                      color: _outline.withValues(alpha: 0.7),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
              ?suffixIcon,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordStrengthMeter() {
    final len = _passwordInput.length;
    int activeBars = 0;
    Color barColor = _surfaceHighest;
    String label = 'Weak';
    Color labelColor = _outline;
    FontWeight labelWeight = FontWeight.w500;

    if (len > 0 && len < 6) {
      activeBars = 1;
      barColor = _errorColor;
      label = 'Weak';
      labelColor = _errorColor;
    } else if (len >= 6 && len < 8) {
      activeBars = 2;
      barColor = _secondaryContainer;
      label = 'Fair';
      labelColor = _secondaryColor;
    } else if (len >= 8 && len < 10) {
      activeBars = 3;
      barColor = _primaryColor;
      label = 'Good';
      labelColor = _primaryColor;
    } else if (len >= 10) {
      activeBars = 4;
      barColor = _primaryColor;
      label = 'Strong';
      labelColor = _primaryColor;
      labelWeight = FontWeight.w600;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 4, right: 4),
      child: Column(
        children: [
          Row(
            children: List.generate(4, (index) {
              final isActive = index < activeBars;
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 4,
                  margin: EdgeInsets.only(right: index < 3 ? 6 : 0),
                  decoration: BoxDecoration(
                    color: isActive ? barColor : _surfaceHighest,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 13, color: _outline),
                  SizedBox(width: 4),
                  Text(
                    'Min. 8 characters',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: _outline,
                    ),
                  ),
                ],
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: labelWeight,
                  color: labelColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget? _buildUsernameBadge() {
    if (_usernameInput.length < 3) return null;
    final taken = _isUsernameTaken(_usernameInput);
    return Text(
      taken ? 'Taken' : 'Available',
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: taken ? _errorColor : _primaryColor,
      ),
    );
  }

  Widget _buildPasswordToggle({
    required bool obscure,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      tooltip: 'Toggle password visibility',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      onPressed: onPressed,
      icon: Icon(
        obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        size: 20,
        color: obscure ? _outline : _primaryColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<RegisterViewModel>().isLoading;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: _bgColor),
      child: Scaffold(
        backgroundColor: _bgColor,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Branding Header
                    Column(
                      children: [
                        _buildHeaderLogo(),
                        const SizedBox(height: 16),
                        const Text(
                          'Join ZieSocial',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            height: 1.33,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.36,
                            color: _onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const SizedBox(
                          width: 300,
                          child: Text(
                            'Connect, share moments, and chat with friends around the world.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              color: _onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Form Inputs
                    _buildInputField(
                      label: 'Full Name',
                      controller: _nameController,
                      focusNode: _nameFocus,
                      prefixIcon: Icons.person_outline_rounded,
                      hintText: 'Alex Morgan',
                    ),
                    const SizedBox(height: 16),

                    _buildInputField(
                      label: 'Username',
                      labelTrailing: _buildUsernameBadge(),
                      controller: _usernameController,
                      focusNode: _usernameFocus,
                      prefixIcon: Icons.alternate_email_rounded,
                      hintText: 'alexmorgan',
                    ),
                    const SizedBox(height: 16),

                    _buildInputField(
                      label: 'Email Address',
                      controller: _emailController,
                      focusNode: _emailFocus,
                      prefixIcon: Icons.mail_outline_rounded,
                      hintText: 'alex.morgan@example.com',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),

                    _buildInputField(
                      label: 'Password',
                      controller: _passwordController,
                      focusNode: _passwordFocus,
                      prefixIcon: Icons.lock_outline_rounded,
                      hintText: 'Create a strong password',
                      obscureText: _obscurePassword,
                      suffixIcon: _buildPasswordToggle(
                        obscure: _obscurePassword,
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                    ),
                    _buildPasswordStrengthMeter(),
                    const SizedBox(height: 16),

                    _buildInputField(
                      label: 'Confirm Password',
                      controller: _confirmPasswordController,
                      focusNode: _confirmPasswordFocus,
                      prefixIcon: Icons.lock_reset_rounded,
                      hintText: 'Repeat your password',
                      obscureText: _obscureConfirmPassword,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) {
                        if (!isLoading) _register();
                      },
                      suffixIcon: _buildPasswordToggle(
                        obscure: _obscureConfirmPassword,
                        onPressed: () {
                          setState(
                            () => _obscureConfirmPassword =
                                !_obscureConfirmPassword,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Terms and Conditions Checkbox
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          setState(() => _agreedToTerms = !_agreedToTerms);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                width: 20,
                                height: 20,
                                margin: const EdgeInsets.only(top: 1),
                                decoration: BoxDecoration(
                                  color: _agreedToTerms
                                      ? _primaryColor
                                      : _surfaceHigh,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: _agreedToTerms
                                    ? const Icon(
                                        Icons.check_rounded,
                                        size: 15,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    const Text(
                                      'I agree to the ',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: _onSurfaceVariant,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => _showPolicyDialog(
                                        'Terms of Service',
                                        'Dengan mendaftar di ZieSocial, Anda setuju untuk menjaga etika berkomunitas dan tidak mengunggah konten yang melanggar hukum.',
                                      ),
                                      child: const Text(
                                        'Terms of Service',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                          color: _primaryColor,
                                        ),
                                      ),
                                    ),
                                    const Text(
                                      ' and ',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: _onSurfaceVariant,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => _showPolicyDialog(
                                        'Privacy Policy',
                                        'Data profil, postingan, dan cerita Anda disimpan secara lokal pada perangkat Anda dan digunakan untuk pengalaman ZieSocial.',
                                      ),
                                      child: const Text(
                                        'Privacy Policy',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                          color: _primaryColor,
                                        ),
                                      ),
                                    ),
                                    const Text(
                                      '.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: _onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Primary CTA Button (Gradient Pill)
                    Container(
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        gradient: LinearGradient(
                          colors: isLoading
                              ? [
                                  _primaryColor.withValues(alpha: 0.7),
                                  _primaryContainer.withValues(alpha: 0.7),
                                ]
                              : const [_primaryColor, _primaryContainer],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _primaryColor.withValues(alpha: 0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: isLoading ? null : _register,
                          child: Center(
                            child: isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Create Account',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Login Redirection Footer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Already have an account?',
                          style: TextStyle(
                            fontSize: 13,
                            color: _onSurfaceVariant,
                          ),
                        ),
                        TextButton(
                          onPressed: isLoading
                              ? null
                              : () => Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const LoginView(),
                                    ),
                                  ),
                          style: TextButton.styleFrom(
                            foregroundColor: _primaryColor,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Log In',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
