
import 'package:bashabondhu_home_rental_management_system/features/auth/presentation/screens/sign_up_screen.dart';
import 'package:flutter/material.dart';

import '../../../../app/extensions/utility_extension.dart';
import '../../../../app/validators.dart';
import '../widgets/app_logo.dart';


class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  static const String name = '/sign-in';

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  
  String? _selectedUserType;
   bool _isPasswordObscured = true;
  final TextEditingController _emailTEController = TextEditingController();
  final TextEditingController _passwordTEController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              autovalidateMode: .onUserInteraction,
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  AppLogo(width: 100, height: 100),
                  const SizedBox(height: 16),
                  Text('Sign In', style: context.textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    context.localizations.signInSubTitle,
                    style: context.textTheme.labelLarge,
                  ),

                  const SizedBox(height: 24),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedUserType,
                    decoration: const InputDecoration(
                      hintText: 'Select User Type',
                    ),
                    items: ['House Owner', 'Tenant']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedUserType = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a user type';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailTEController,
                    textInputAction: TextInputAction.next,
                    keyboardType: .emailAddress,
                    decoration: InputDecoration(hintText: 'Email'),
                    validator: Validators.validateEmail,
                  ),
                
                  const SizedBox(height: 8),
                   TextFormField(
                    controller: _passwordTEController,
                    textInputAction: TextInputAction.done,
                    obscureText: _isPasswordObscured,
                    obscuringCharacter: '*',
                    decoration: InputDecoration(
                      hintText: 'Password',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordObscured
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordObscured = !_isPasswordObscured;
                          });
                        },
                      ),
                    ),
                    validator: Validators.validatePassword,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _onTapSignInButton,
                    child: const Text('Sign In'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        context.localizations.doNotHaveAnAccount,
                        style: context.textTheme.labelLarge,
                      ),
                      TextButton(
                        onPressed: _onTapSignUpNavigation,
                        child: Text(context.localizations.signUp),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onTapSignInButton() {
    if (_formKey.currentState!.validate()) {
      // TODO: Implement actual sign in logic
    }
  }

  void _onTapSignUpNavigation() {
    Navigator.pushReplacementNamed(context, SignUpScreen.name);
  }

 

  @override
  void dispose() {
    _emailTEController.dispose();
    _passwordTEController.dispose();
    super.dispose();
  }
}