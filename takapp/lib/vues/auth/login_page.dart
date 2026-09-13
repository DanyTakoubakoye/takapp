import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:takapp/controllers/auth_controller.dart';
import 'package:takapp/core/l10n/language_selector.dart';
import 'package:takapp/l10n/app_localizations.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _passwordEnabled = false;
  bool _isSendingReset = false;

  String? _resetMessage;
  bool _resetSuccess = false;

  List<String> _savedEmails = [];
  List<String> _filteredEmails = [];

  static const String _emailsStorageKey = 'takapp_saved_emails';

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_handleEmailTyping);
    _emailFocusNode.addListener(_handleEmailFocusChange);
    _initSavedEmails();
  }

  Future<void> _initSavedEmails() async {
    await _loadSavedEmails();
    _refreshSuggestions();
  }

  Future<void> _loadSavedEmails() async {
    final prefs = await SharedPreferences.getInstance();
    final emails = prefs.getStringList(_emailsStorageKey) ?? [];

    if (!mounted) return;

    setState(() {
      _savedEmails = emails;
    });

    debugPrint('Emails chargés: $_savedEmails');
  }

  Future<void> _saveEmailIfNeeded(String email) async {
    final cleanEmail = email.trim().toLowerCase();

    if (cleanEmail.isEmpty) return;
    if (!_isValidEmail(cleanEmail)) return;

    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_emailsStorageKey) ?? [];

    existing.remove(cleanEmail);
    existing.insert(0, cleanEmail);

    if (existing.length > 10) {
      existing.removeRange(10, existing.length);
    }

    await prefs.setStringList(_emailsStorageKey, existing);

    if (!mounted) return;

    setState(() {
      _savedEmails = existing;
    });

    _refreshSuggestions();
    debugPrint('Emails sauvegardés: $_savedEmails');
  }

  Future<void> _removeSavedEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_emailsStorageKey) ?? [];

    existing.remove(email);

    await prefs.setStringList(_emailsStorageKey, existing);

    if (!mounted) return;

    setState(() {
      _savedEmails = existing;
    });

    _refreshSuggestions();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email.trim());
  }

  List<String> _buildSuggestions(String input) {
    final query = input.trim().toLowerCase();

    if (!_emailFocusNode.hasFocus) return [];

    if (_savedEmails.isEmpty) return [];

    if (query.isEmpty) {
      return _savedEmails.take(5).toList();
    }

    final startsWithMatches = _savedEmails
        .where((email) => email.toLowerCase().startsWith(query))
        .toList();

    final containsMatches = _savedEmails
        .where(
          (email) =>
              !email.toLowerCase().startsWith(query) &&
              email.toLowerCase().contains(query),
        )
        .toList();

    return [...startsWithMatches, ...containsMatches].take(5).toList();
  }

  void _refreshSuggestions() {
    if (!mounted) return;

    setState(() {
      _filteredEmails = _buildSuggestions(_emailController.text);
    });
  }

  void _handleEmailFocusChange() {
    _refreshSuggestions();
  }

  void _handleEmailTyping() {
    final email = _emailController.text.trim();
    final shouldEnablePassword = _isValidEmail(email);

    if (!mounted) return;

    setState(() {
      _passwordEnabled = shouldEnablePassword;
      _filteredEmails = _buildSuggestions(email);
    });
  }

  void _selectEmail(String email) {
    _emailController.value = TextEditingValue(
      text: email,
      selection: TextSelection.collapsed(offset: email.length),
    );

    setState(() {
      _passwordEnabled = _isValidEmail(email);
      _filteredEmails = [];
    });

    FocusScope.of(context).requestFocus(_passwordFocusNode);
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final email = _emailController.text.trim();

    // Sauvegarde dès que l'utilisateur soumet un email valide
    if (_isValidEmail(email)) {
      await _saveEmailIfNeeded(email);
    }

    if (!_formKey.currentState!.validate()) return;

    if (!mounted) return;

    final auth = context.read<AuthController>();
    final password = _passwordController.text.trim();

    final success = await auth.login(email: email, password: password);

    debugPrint('Résultat login success = $success pour email = $email');

    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();

    final errorText = auth.errorText(l10n);

    if (!success && errorText != null) {
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(errorText),
        ),
      );
    }
  }

  Future<void> _sendResetEmail() async {
    if (_isSendingReset) return;

    final l10n = AppLocalizations.of(context);
    final auth = context.read<AuthController>();
    final email = _emailController.text.trim();

    setState(() {
      _resetMessage = null;
      _resetSuccess = false;
    });

    if (email.isEmpty) {
      setState(() {
        _resetSuccess = false;
        _resetMessage = l10n.loginResetNeedsEmail;
      });
      return;
    }

    if (!_isValidEmail(email)) {
      setState(() {
        _resetSuccess = false;
        _resetMessage = l10n.loginResetInvalidEmail;
      });
      return;
    }

    await _saveEmailIfNeeded(email);

    setState(() {
      _isSendingReset = true;
    });

    bool success = false;
    String message;

    try {
      success = await auth.sendPasswordResetEmail(email);

      if (success) {
        message = l10n.loginResetSent(email);
      } else {
        message = auth.errorText(l10n) ?? l10n.loginResetFailed;
      }
    } catch (e) {
      success = false;
      message = l10n.loginResetError('$e');
    }

    if (!mounted) return;

    setState(() {
      _isSendingReset = false;
      _resetSuccess = success;
      _resetMessage = message;
    });
  }

  Widget _buildResetFeedback() {
    if (_resetMessage == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: _resetSuccess
            ? Colors.green.withValues(alpha: 0.12)
            : Colors.red.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _resetSuccess ? Colors.green : Colors.red),
      ),
      child: Text(
        _resetMessage!,
        style: TextStyle(
          color: _resetSuccess ? Colors.green.shade800 : Colors.red.shade800,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEmailSuggestions() {
    if (_filteredEmails.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: _filteredEmails.map((email) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) {
              _selectEmail(email);
            },
            child: ListTile(
              dense: true,
              leading: const Icon(Icons.history),
              title: Text(email),
              trailing: IconButton(
                tooltip: l10n.commonDelete,
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => _removeSavedEmail(email),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.removeListener(_handleEmailTyping);
    _emailFocusNode.removeListener(_handleEmailFocusChange);
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = context.watch<AuthController>();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Align(
                        alignment: Alignment.centerRight,
                        child: LanguageSelector(),
                      ),
                      Container(
                        height: size.width < 500 ? 72 : 84,
                        width: size.width < 500 ? 72 : 84,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.hotel,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'TAKHOTEL',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.loginSubtitle,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _emailController,
                              focusNode: _emailFocusNode,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                labelText: l10n.loginEmailLabel,
                                hintText: l10n.loginEmailHint,
                                prefixIcon: const Icon(Icons.email_outlined),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return l10n.loginEmailRequired;
                                }
                                if (!_isValidEmail(value)) {
                                  return l10n.loginEmailInvalid;
                                }
                                return null;
                              },
                              onTap: _refreshSuggestions,
                              onFieldSubmitted: (_) {
                                if (_passwordEnabled) {
                                  _passwordFocusNode.requestFocus();
                                }
                              },
                            ),
                            _buildEmailSuggestions(),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _passwordController,
                              focusNode: _passwordFocusNode,
                              enabled: _passwordEnabled,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              decoration: InputDecoration(
                                labelText: l10n.loginPasswordLabel,
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (!_passwordEnabled) {
                                  return l10n.loginPasswordEmailFirst;
                                }
                                if (value == null || value.trim().isEmpty) {
                                  return l10n.loginPasswordRequired;
                                }
                                if (value.trim().length < 6) {
                                  return l10n.loginPasswordTooShort;
                                }
                                return null;
                              },
                              onFieldSubmitted: (_) {
                                if (!auth.isLoading) {
                                  _submit();
                                }
                              },
                            ),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _isSendingReset
                                    ? null
                                    : _sendResetEmail,
                                child: _isSendingReset
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        l10n.loginForgotPassword,
                                        style: const TextStyle(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                            _buildResetFeedback(),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: auth.isLoading ? null : _submit,
                                child: auth.isLoading
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.4,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(l10n.loginSubmit),
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
          ),
        ),
      ),
    );
  }
}
