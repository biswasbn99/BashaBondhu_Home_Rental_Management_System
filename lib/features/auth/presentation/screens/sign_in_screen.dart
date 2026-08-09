
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
  final TextEditingController _emailTEController = TextEditingController();
  final TextEditingController _passwordTEController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: .all(24),
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
                    obscureText: true,
                    obscuringCharacter: '*',
                    decoration: InputDecoration(hintText: 'Password'),
                    validator: Validators.validatePassword,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _onTapSignUpButton,
                    child: Text('Sign Up'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: .center,
                    children: [
                      Text(
                        context.localizations.doNotHaveAnAccount,
                        style: context.textTheme.labelLarge,
                      ),
                      TextButton(
                        onPressed: _onTapSignInButton,
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

  void _onTapSignUpButton() {}
  void _onTapSignInButton() {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>SignUpScreen()));
  }

 

  @override
  void dispose() {
    _emailTEController.dispose();
    _passwordTEController.dispose();
    super.dispose();
  }
}