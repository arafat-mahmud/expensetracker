import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import '../config/admin_config.dart';
import '../models/account_model.dart';
import '../services/access_gate.dart';
import '../services/account_service.dart';

/// Follows the signed-in user's account status and the app configuration
/// live from Firestore, decides what the user may see, and opens or closes
/// the [AccessGate] for cloud sync.
///
/// Cost: one read for each of the two documents when the app opens (none
/// on resume within 30 minutes), plus one per change.
class AccountProvider extends ChangeNotifier with WidgetsBindingObserver {
  AccountProvider({AccountService? service, FirebaseAuth? auth})
      : _service = service ?? AccountService(),
        _auth = auth ?? FirebaseAuth.instance {
    WidgetsBinding.instance.addObserver(this);
    _onUserChanged(_auth.currentUser);
    _authSubscription = _auth.authStateChanges().listen(_onUserChanged);
  }

  final AccountService _service;
  final FirebaseAuth _auth;
  late final StreamSubscription<User?> _authSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _accountListener;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _configListener;

  User? _user;
  AppAccount? _account;
  AppConfig _config = const AppConfig();
  bool _accountLoaded = false;
  bool _configLoaded = false;
  bool _registrationTried = false;

  User? get user => _user;
  AppAccount? get account => _account;
  AppConfig get config => _config;
  bool get isAdmin => AdminConfig.isAdmin(_user);

  AccessState get state => resolveAccess(
        signedIn: _user != null,
        isAdmin: isAdmin,
        loaded: _accountLoaded && _configLoaded,
        config: _config,
        account: _account,
      );

  bool isEnabled(AppFeature feature) =>
      resolveFeature(feature, _config, _account);

  void _onUserChanged(User? user) {
    if (user?.uid == _user?.uid) return;
    _stopListening();
    _user = user;
    _account = null;
    _config = const AppConfig();
    _accountLoaded = false;
    _configLoaded = false;
    _registrationTried = false;
    if (user != null) _listen();
    _changed();
  }

  void _listen() {
    final uid = _user!.uid;
    _configListener = _service.watchConfig().listen(
      (snapshot) {
        _config = AppConfig.fromMap(snapshot.data());
        // A document missing from the cache may simply not be cached yet
        _configLoaded = snapshot.exists || !snapshot.metadata.isFromCache;
        _registerIfNew();
        _changed();
      },
      onError: (Object e) => debugPrint('⚠️ [ACCOUNT] Config: $e'),
    );
    _accountListener = _service.watchAccount(uid).listen(
      (snapshot) {
        final data = snapshot.data();
        _account = data == null ? null : AppAccount.fromMap(snapshot.id, data);
        _accountLoaded = data != null || !snapshot.metadata.isFromCache;
        _registerIfNew();
        _changed();
      },
      onError: (Object e) => debugPrint('⚠️ [ACCOUNT] Account: $e'),
    );
  }

  /// First sign-in: the server has confirmed there is no account yet
  void _registerIfNew() {
    final user = _user;
    if (user == null ||
        _registrationTried ||
        !_accountLoaded ||
        !_configLoaded ||
        _account != null) {
      return;
    }
    _registrationTried = true;
    _service
        .register(user, approved: isAdmin || !_config.requireApproval)
        .catchError((Object e) => debugPrint('⚠️ [ACCOUNT] Register: $e'));
  }

  void _changed() {
    AccessGate.cloudAllowed.value =
        state == AccessState.approved && isEnabled(AppFeature.cloudSync);
    notifyListeners();
  }

  void _stopListening() {
    _accountListener?.cancel();
    _accountListener = null;
    _configListener?.cancel();
    _configListener = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_user == null) return;
    if (state == AppLifecycleState.paused) {
      // Nothing is read in the background
      _stopListening();
    } else if (state == AppLifecycleState.resumed && _accountListener == null) {
      _listen();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSubscription.cancel();
    _stopListening();
    super.dispose();
  }
}
