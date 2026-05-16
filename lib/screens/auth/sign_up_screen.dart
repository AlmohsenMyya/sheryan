import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sheryan/core/enums/user_role.dart';
import 'package:sheryan/core/theme/app_colors.dart';
import 'package:sheryan/core/theme/app_design_constants.dart';
import 'package:sheryan/providers/auth/auth_provider.dart';
import 'package:sheryan/screens/auth/sign_in_screen.dart';
import 'package:sheryan/screens/home/home_screen.dart';
import 'package:sheryan/services/auth_service.dart';
import 'package:sheryan/services/points_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sheryan/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class SignupScreen extends ConsumerStatefulWidget {
  final UserRole? role;
  const SignupScreen({super.key, this.role});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final AuthService _auth = AuthService();

  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _phone = TextEditingController();

  String _selectedBlood = 'A+';
  String _selectedCity = ''; 
  UserRole _selectedRole = UserRole.donor;
  DateTime? _lastDonated;
  bool _loading = false;
  bool _obscure = true;

  final List<String> _bloodTypes = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.role != null) {
      _selectedRole = widget.role!;
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final dt = await showDatePicker(
      context: context,
      initialDate: now.subtract(const Duration(days: 90)),
      firstDate: DateTime(2000),
      lastDate: now,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: AppColors.primaryRed,
          ),
        ),
        child: child!,
      ),
    );
    if (dt != null) setState(() => _lastDonated = dt);
  }

  bool _isEmailValid(String email) =>
      RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);

  bool _isPasswordStrong(String password) =>
      password.length >= 6 && RegExp(r'^(?=.*[a-zA-Z])(?=.*\d).+$').hasMatch(password);

  Future<void> _signUp() async {
    final l10n = AppLocalizations.of(context)!;
    if (_name.text.trim().isEmpty ||
        _email.text.trim().isEmpty ||
        _password.text.isEmpty ||
        _phone.text.trim().isEmpty ||
        _selectedCity.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.signupFillAllFields)),
      );
      return;
    }

    if (!_isEmailValid(_email.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.signupValidEmail)),
      );
      return;
    }

    if (!_isPasswordStrong(_password.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.signupPasswordStrong)),
      );
      return;
    }

    if (_phone.text.trim().length != 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.invalidSyrianPhone)),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final fullPhone = '+963${_phone.text.trim()}';
      final lastDonatedString = _lastDonated == null
          ? null
          : DateFormat('yyyy-MM-dd').format(_lastDonated!);

      final ok = await _auth.registerUser(
        name: _name.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
        bloodGroup: _selectedRole == UserRole.donor ? _selectedBlood : '',
        city: _selectedCity,
        role: _selectedRole == UserRole.donor ? 'donor' : 'user',
        phone: fullPhone,
        lastDonated: lastDonatedString,
      );

      setState(() => _loading = false);

      if (ok) {
        // Award account creation points (donor only)
        if (_selectedRole == UserRole.donor) {
          final uid = FirebaseAuth.instance.currentUser?.uid;
          if (uid != null) {
            await PointsService().awardPoints(
              uid: uid,
              event: PointsEvent.accountCreated,
              points: PointsValue.accountCreated,
              descriptionAr: 'مرحباً بك في شريان!',
              descriptionEn: 'Welcome to Sheryan!',
            );
          }
        }
        ref.read(roleProvider.notifier).setRole(_selectedRole);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.accountCreated)));
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.signupFailed)));
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _loading = false);
      if (e.code == 'email-already-in-use') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.emailAlreadyInUse)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.genericError(e.message ?? ''))),
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.genericError(e.toString()))));
    }
  }
  

  Widget _buildTextField(
    TextEditingController c,
    String hint,
    IconData icon, {
    bool obscure = false,
  }) {
    return TextField(
      controller: c,
      obscureText: obscure && _obscure,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        suffixIcon: obscure
            ? IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDonor = _selectedRole == UserRole.donor;
    
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Center(
                  child: Image.asset(
                    'assets/logo.png',
                    height: 60,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.createAccountTitle,
                  style: theme.textTheme.displayMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.fillDetailsCreateAccount,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),

                _buildTextField(_name, l10n.fullName, Icons.person),
                const SizedBox(height: 12),
                _buildTextField(_email, l10n.email, Icons.email),
                const SizedBox(height: 12),
                _buildTextField(_password, l10n.password, Icons.lock, obscure: true),
                const SizedBox(height: 12),
                TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  maxLength: 9,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    hintText: '9XXXXXXXX',
                    prefixIcon: const Icon(Icons.phone),
                    prefixText: l10n.phonePrefix,
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 12),

                // Role dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: AppDesignConstants.borderRadiusMedium,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<UserRole>(
                      value: _selectedRole,
                      dropdownColor: theme.colorScheme.surface,
                      items: [
                        DropdownMenuItem(
                          value: UserRole.donor,
                          child: Text(
                            l10n.roleDonor,
                            style: theme.textTheme.bodyLarge,
                          ),
                        ),
                        DropdownMenuItem(
                          value: UserRole.recipient,
                          child: Text(
                            l10n.roleUser,
                            style: theme.textTheme.bodyLarge,
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => _selectedRole = v!),
                      isExpanded: true,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // City dropdown (Dynamic)
                // داخل ملف SignupScreen في مكان حقل المدينة
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('cities').orderBy('name').snapshots(),
                  builder: (context, snapshot) {
                    List<String> cities = [];
                    if (snapshot.hasData) {
                      cities = snapshot.data!.docs.map((d) => d['name'] as String).toList();
                    }

                    // الحالة الاحترافية: إذا كانت القائمة فارغة، اظهر حقل نصي (للتهيئة لأول مرة)
                    if (cities.isEmpty) {
                      return TextFormField(
                        onChanged: (v) => setState(() => _selectedCity = v),
                        decoration: InputDecoration(
                          labelText: l10n.city,
                          hintText: "Enter your city (Initial Setup)",
                          prefixIcon: const Icon(Icons.location_city),
                        ),
                      );
                    }

                    // الحالة العادية: اظهر قائمة الاختيار
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: AppDesignConstants.borderRadiusMedium,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCity.isEmpty ? null : _selectedCity,
                          hint: Text(l10n.city, style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.textGrey)),
                          dropdownColor: theme.colorScheme.surface,
                          items: cities.map((c) => DropdownMenuItem(value: c, child: Text(c, style: theme.textTheme.bodyLarge))).toList(),
                          onChanged: (v) => setState(() => _selectedCity = v!),
                          isExpanded: true,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),

                if (isDonor) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: AppDesignConstants.borderRadiusMedium,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedBlood,
                        dropdownColor: theme.colorScheme.surface,
                        items: _bloodTypes
                            .map(
                              (b) => DropdownMenuItem(
                                value: b,
                                child: Text(
                                  b,
                                  style: theme.textTheme.bodyLarge,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _selectedBlood = v!),
                        isExpanded: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: AppDesignConstants.borderRadiusMedium,
                    ),
                    child: Text(
                      _lastDonated == null
                          ? l10n.selectLastDonationDate
                          : l10n.lastDonatedOn(DateFormat('yyyy-MM-dd').format(_lastDonated!)),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _signUp,
                    child: _loading
                        ? const CircularProgressIndicator(color: AppColors.textPrimary)
                        : Text(l10n.signUp),
                  ),
                ),

                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    ),
                    child: Text(
                      l10n.alreadyHaveAccountLogin,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
