import 'package:faui/FauiPhrases.dart';
import 'package:faui/DefaultScreenBuilder.dart';
import 'package:faui/FauiUser.dart';
import 'package:faui/src/06_auth/AuthConnector.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'FauiAuthState.dart';
import 'FauiExceptionAnalyser.dart';

var uuid = new Uuid();

class FauiAuthScreen extends StatefulWidget {
  final VoidCallback onExit;
  final String firebaseApiKey;
  final bool startWithRegistration;
  final Map<FauiPhrases, String> phrases;
  final Widget Function({
    @required BuildContext context,
    @required String title,
    @required Widget content,
    @required VoidCallback close,
  }) builder;

  FauiAuthScreen(
      {@required this.onExit,
      @required this.firebaseApiKey,
      this.startWithRegistration})
      : this.builder = DefaultScreenBuilder.builder,
        this.phrases = Map<FauiPhrases, String>();

  FauiAuthScreen.custom({
    @required this.onExit,
    @required this.firebaseApiKey,
    @required this.builder,
    @required this.phrases,
    this.startWithRegistration,
  });

  @override
  _FauiAuthScreenState createState() => _FauiAuthScreenState();
}

enum AuthScreen {
  signIn,
  createAccount,
  forgotPassword,
  verifyEmail,
  resetPassword,
}

class _FauiAuthScreenState extends State<FauiAuthScreen> {
  AuthScreen _authScreen = AuthScreen.signIn;
  String _error;
  String _email;

  @override
  void initState() {
    super.initState();

    if (this.widget.startWithRegistration) {
      this._authScreen = AuthScreen.createAccount;
    }
  }

  void switchScreen(AuthScreen authScreen, String email) {
    setState(() {
      this._authScreen = authScreen;
      this._error = null;
      this._email = email;
    });
  }

  void afterAuthorized(BuildContext context, FauiUser user) {
    FauiAuthState.user = user;
    this.widget.onExit();
  }

  @override
  Widget build(BuildContext context) {
    return this.widget.builder(
        context: context,
        title: _getScreenTitle(),
        content: _getScreen(context),
        close: this.widget.onExit);
  }

  String _getScreenTitle() {
    switch (this._authScreen) {
      case AuthScreen.signIn:
        return widget.phrases[FauiPhrases.SignInTitle] ?? 'Sign In';
      case AuthScreen.createAccount:
        return widget.phrases[FauiPhrases.CreateAccountTitle] ??
            'Create Account';
      case AuthScreen.forgotPassword:
        return widget.phrases[FauiPhrases.ForgotPassordTitle] ??
            'Forgot Password';
      case AuthScreen.verifyEmail:
        return widget.phrases[FauiPhrases.VerifyEmailTitle] ?? 'Verify Email';
      case AuthScreen.resetPassword:
        return widget.phrases[FauiPhrases.ResetPasswordTitle] ??
            'Reset Password';
      default:
        throw "Unexpected screen $_authScreen";
    }
  }

  Widget _getScreen(BuildContext context) {
    switch (this._authScreen) {
      case AuthScreen.signIn:
        return _buildSignInScreen(context);
      case AuthScreen.createAccount:
        return _buildCreateAccountScreen(context);
      case AuthScreen.forgotPassword:
        return _buildForgotPasswordScreen(context, this._email);
      case AuthScreen.verifyEmail:
        return _buildVerifyEmailScreen(context, this._email);
      case AuthScreen.resetPassword:
        return _buildResetPasswordScreen(context, this._email);
      default:
        throw "Unexpected screen $_authScreen";
    }
  }

  static Widget _buildError(BuildContext context, String error) {
    return Text(
      error ?? "",
      style: TextStyle(color: Theme.of(context).errorColor),
    );
  }

  Widget _buildCreateAccountScreen(BuildContext context) {
    final TextEditingController emailController =
        new TextEditingController(text: this._email);
    return Column(children: <Widget>[
      TextField(
        autofocus: true,
        controller: emailController,
        decoration: InputDecoration(
          labelText: widget.phrases[FauiPhrases.EmailTextField] ?? "EMail",
        ),
      ),
      _buildError(context, _error),
      RaisedButton(
        autofocus: true,
        child: Text(widget.phrases[FauiPhrases.CreateAccountButton] ??
            'Create Account'),
        onPressed: () async {
          try {
            await AuthConnector.registerUser(
              apiKey: this.widget.firebaseApiKey,
              email: emailController.text,
            );

            await AuthConnector.sendResetLink(
              apiKey: this.widget.firebaseApiKey,
              email: emailController.text,
            );

            this.switchScreen(AuthScreen.verifyEmail, emailController.text);
          } catch (e) {
            this.setState(() {
              this._error = FauiExceptionAnalyser.toUiMessage(e);
              this._email = emailController.text;
            });
          }
        },
      ),
      FlatButton(
        child: Text(widget.phrases[FauiPhrases.HaveAccountLink] ??
            'Have account? Sign in.'),
        onPressed: () {
          this.switchScreen(AuthScreen.signIn, emailController.text);
        },
      ),
    ]);
  }

  Widget _buildSignInScreen(BuildContext context) {
    final TextEditingController emailController =
        new TextEditingController(text: this._email);
    final TextEditingController passwordController =
        new TextEditingController();

    return Column(
      children: <Widget>[
        TextField(
          autofocus: true,
          controller: emailController,
          decoration: InputDecoration(
            labelText: widget.phrases[FauiPhrases.EmailTextField] ?? "EMail",
          ),
        ),
        TextField(
          controller: passwordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText:
                widget.phrases[FauiPhrases.PasswordTextField] ?? "Password",
          ),
        ),
        _buildError(context, _error),
        RaisedButton(
          child: Text(widget.phrases[FauiPhrases.SignInButton] ?? 'Sign In'),
          onPressed: () async {
            try {
              FauiUser user = await AuthConnector.signInUser(
                apiKey: this.widget.firebaseApiKey,
                email: emailController.text,
                password: passwordController.text,
              );
              this.afterAuthorized(context, user);
            } catch (e) {
              this.setState(() {
                this._error = FauiExceptionAnalyser.toUiMessage(e);
                this._email = emailController.text;
              });
            }
          },
        ),
        FlatButton(
          child: Text(widget.phrases[FauiPhrases.CreateAccountLink] ??
              'Create Account'),
          onPressed: () {
            this.switchScreen(AuthScreen.createAccount, emailController.text);
          },
        ),
        FlatButton(
          child: Text(widget.phrases[FauiPhrases.ForgotPassordLink] ??
              'Forgot Password?'),
          onPressed: () {
            this.switchScreen(AuthScreen.forgotPassword, emailController.text);
          },
        ),
      ],
    );
  }

  Widget _buildVerifyEmailScreen(BuildContext context, String email) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Text(
          widget.phrases[FauiPhrases.WeSentVerificationEmailMessage] ??
              "We sent verification link to $email",
          textAlign: TextAlign.center,
        ),
        RaisedButton(
          child: Text(widget.phrases[FauiPhrases.SignInButton] ?? 'Sign In'),
          onPressed: () {
            this.switchScreen(AuthScreen.signIn, email);
          },
        ),
      ],
    );
  }

  Widget _buildResetPasswordScreen(BuildContext context, String email) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Text(
          widget.phrases[FauiPhrases.WeSentLinkToResetPasswordMEssage] ??
              "We sent the link to reset your password to $email",
          textAlign: TextAlign.center,
        ),
        RaisedButton(
          child: Text(widget.phrases[FauiPhrases.SignInButton] ?? 'Sign In'),
          onPressed: () {
            this.switchScreen(AuthScreen.signIn, email);
          },
        ),
      ],
    );
  }

  Widget _buildForgotPasswordScreen(BuildContext context, String email) {
    final TextEditingController emailController =
        new TextEditingController(text: this._email);

    return Column(
      children: <Widget>[
        TextField(
          autofocus: true,
          controller: emailController,
          decoration: InputDecoration(
            labelText: widget.phrases[FauiPhrases.EmailTextField] ?? "EMail",
          ),
        ),
        _buildError(context, _error),
        RaisedButton(
          child: Text(widget.phrases[FauiPhrases.SendPasswordResetLinkButton] ??
              'Send Password Reset Link'),
          onPressed: () async {
            try {
              await AuthConnector.sendResetLink(
                apiKey: this.widget.firebaseApiKey,
                email: emailController.text,
              );
              this.switchScreen(AuthScreen.resetPassword, emailController.text);
            } catch (e) {
              this.setState(() {
                this._error = FauiExceptionAnalyser.toUiMessage(e);
                this._email = emailController.text;
              });
            }
          },
        ),
        FlatButton(
          child: Text(widget.phrases[FauiPhrases.SignInLink] ?? 'Sign In'),
          onPressed: () {
            this.switchScreen(AuthScreen.signIn, email);
          },
        ),
        FlatButton(
          child: Text(widget.phrases[FauiPhrases.CreateAccountLink] ??
              'Create Account'),
          onPressed: () {
            this.switchScreen(AuthScreen.createAccount, email);
          },
        ),
      ],
    );
  }
}
