// Copyright 2021 Invertase Limited. All rights reserved.
// Use of this source code is governed by a BSD-style license
// that can be found in the LICENSE file.

// ignore_for_file: require_trailing_commas

library firebase_auth_desktop;

import 'dart:async';

import 'package:firebase_auth_dart/firebase_auth_dart.dart' as auth_dart;
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_dart/firebase_core_dart.dart' as core_dart;

import 'src/confirmation_result.dart';
import 'src/firebase_auth_user.dart';
import 'src/firebase_auth_user_credential.dart';
import 'src/recaptcha_verifier.dart';
import 'src/utils/desktop_utils.dart';

/// A Dart only implmentation of `FirebaseAuth` for managing Firebase users.
class FirebaseAuthDesktop extends FirebaseAuthPlatform {
  /// Entry point for the [FirebaseAuthDesktop] class.
  FirebaseAuthDesktop({required FirebaseApp app})
      : _app = core_dart.Firebase.app(app.name),
        super(appInstance: app) {
    // Create a app instance broadcast stream for both delegate listener events
    _userChangesListeners[app.name] =
        StreamController<UserPlatform?>.broadcast();
    _authStateChangesListeners[app.name] =
        StreamController<UserPlatform?>.broadcast();
    _idTokenChangesListeners[app.name] =
        StreamController<UserPlatform?>.broadcast();

    _authDart!.authStateChanges().map((auth_dart.User? dartUser) {
      if (dartUser == null) {
        return null;
      }
      return User(this, dartUser);
    }).listen((User? user) {
      _authStateChangesListeners[app.name]!.add(user);
    });

    _authDart!.idTokenChanges().map((auth_dart.User? dartUser) {
      if (dartUser == null) {
        return null;
      }
      return User(this, dartUser);
    }).listen((User? user) {
      _idTokenChangesListeners[app.name]!.add(user);
      _userChangesListeners[app.name]!.add(user);
    });
  }

  FirebaseAuthDesktop._()
      : _app = null,
        super(appInstance: null);

  /// Called by PluginRegistry to register this plugin as the implementation for Desktop
  static void registerWith() {
    FirebaseAuthPlatform.instance = FirebaseAuthDesktop.instance;
    RecaptchaVerifierFactoryPlatform.instance =
        RecaptchaVerifierFactoryDesktop.instance;
  }

  /// Stub initializer to allow creating an instance without
  /// registering delegates or listeners.
  ///
  // ignore: prefer_constructors_over_static_methods
  static FirebaseAuthDesktop get instance {
    return FirebaseAuthDesktop._();
  }

  /// Instance of auth from Identity Provider API service.
  auth_dart.FirebaseAuth? get _authDart =>
      _app == null ? null : auth_dart.FirebaseAuth.instanceFor(app: _app!);

  final core_dart.FirebaseApp? _app;

  @override
  UserPlatform? get currentUser {
    final dartCurrentUser = _authDart!.currentUser;

    if (dartCurrentUser == null) {
      return null;
    }

    return User(this, _authDart!.currentUser!);
  }

  static final Map<String, StreamController<UserPlatform?>>
      _userChangesListeners = <String, StreamController<UserPlatform?>>{};

  static final Map<String, StreamController<UserPlatform?>>
      _authStateChangesListeners = <String, StreamController<UserPlatform?>>{};

  static final Map<String, StreamController<UserPlatform?>>
      _idTokenChangesListeners = <String, StreamController<UserPlatform?>>{};

  @override
  FirebaseAuthPlatform delegateFor({required FirebaseApp app}) {
    return FirebaseAuthDesktop(app: app);
  }

  @override
  FirebaseAuthPlatform setInitialValues({
    Map<String, dynamic>? currentUser,
    String? languageCode,
  }) {
    return this;
  }

  @override
  Future<UserCredentialPlatform> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      return UserCredential(
        this,
        await _authDart!.signInWithEmailAndPassword(email, password),
      );
    } catch (e) {
      throw getFirebaseAuthException(e);
    }
  }

  @override
  Future<List<String>> fetchSignInMethodsForEmail(String email) async {
    try {
      return await _authDart!.fetchSignInMethodsForEmail(email);
    } catch (e) {
      throw getFirebaseAuthException(e);
    }
  }

  @override
  Future<void> applyActionCode(String code) {
    // TODO: implement applyActionCode
    throw UnimplementedError();
  }

  @override
  Future<ActionCodeInfo> checkActionCode(String code) {
    // TODO: implement checkActionCode
    throw UnimplementedError();
  }

  @override
  Future<void> sendPasswordResetEmail(String email,
      [ActionCodeSettings? actionCodeSettings]) async {
    try {
      await _authDart!.sendPasswordResetEmail(
          email: email, continueUrl: actionCodeSettings?.url);
    } catch (e) {
      throw getFirebaseAuthException(e);
    }
  }

  @override
  Future<void> confirmPasswordReset(String code, String newPassword) async {
    try {
      await _authDart!.confirmPasswordReset(code, newPassword);
    } catch (e) {
      throw getFirebaseAuthException(e);
    }
  }

  @override
  Future<UserCredentialPlatform> createUserWithEmailAndPassword(
      String email, String password) async {
    try {
      return UserCredential(
        this,
        await _authDart!.createUserWithEmailAndPassword(email, password),
      );
    } catch (e) {
      throw getFirebaseAuthException(e);
    }
  }

  @override
  Future<UserCredentialPlatform> getRedirectResult() {
    // TODO: implement getRedirectResult
    throw UnimplementedError();
  }

  @override
  Stream<UserPlatform?> authStateChanges() async* {
    yield currentUser;
    yield* _authStateChangesListeners[app.name]!.stream;
  }

  @override
  Stream<UserPlatform?> idTokenChanges() async* {
    yield currentUser;
    yield* _idTokenChangesListeners[app.name]!.stream;
  }

  @override
  Stream<UserPlatform?> userChanges() async* {
    yield currentUser;
    yield* _userChangesListeners[app.name]!.stream;
  }

  @override
  void sendAuthChangesEvent(String appName, UserPlatform? userPlatform) {
    assert(_userChangesListeners[appName] != null);

    _userChangesListeners[appName]!.add(userPlatform);
  }

  @override
  bool isSignInWithEmailLink(String emailLink) {
    throw UnimplementedError();
  }

  @override
  // TODO: implement languageCode
  String? get languageCode => throw UnimplementedError();

  @override
  Future<void> sendSignInLinkToEmail(
      String email, ActionCodeSettings actionCodeSettings) async {
    try {
      await _authDart!.sendSignInLinkToEmail(email);
    } catch (e) {
      throw getFirebaseAuthException(e);
    }
  }

  @override
  Future<void> setLanguageCode(String? languageCode) {
    // TODO: implement setLanguageCode
    throw UnimplementedError();
  }

  @override
  Future<void> setPersistence(Persistence persistence) {
    // TODO: implement setPersistence
    throw UnimplementedError();
  }

  @override
  Future<void> setSettings(
      {bool? appVerificationDisabledForTesting,
      String? userAccessGroup,
      String? phoneNumber,
      String? smsCode,
      bool? forceRecaptchaFlow}) {
    // TODO: implement setSettings
    throw UnimplementedError();
  }

  @override
  Future<UserCredentialPlatform> signInAnonymously() async {
    try {
      return UserCredential(
        this,
        await _authDart!.signInAnonymously(),
      );
    } catch (e) {
      throw getFirebaseAuthException(e);
    }
  }

  @override
  Future<UserCredentialPlatform> signInWithCredential(
      AuthCredential credential) async {
    try {
      return UserCredential(
        this,
        await _authDart!
            .signInWithCredential(mapAuthCredentialFromPlatform(credential)),
      );
    } catch (e) {
      throw getFirebaseAuthException(e);
    }
  }

  @override
  Future<UserCredentialPlatform> signInWithCustomToken(String token) {
    // TODO: implement signInWithCustomToken
    throw UnimplementedError();
  }

  @override
  Future<UserCredentialPlatform> signInWithEmailLink(
      String email, String emailLink) async {
    try {
      return UserCredential(
        this,
        await _authDart!.signInWithEmailLink(email, emailLink),
      );
    } catch (e) {
      throw getFirebaseAuthException(e);
    }
  }

  @override
  Future<ConfirmationResultPlatform> signInWithPhoneNumber(String phoneNumber,
      RecaptchaVerifierFactoryPlatform applicationVerifier) async {
    try {
      final recaptchaVerifier = applicationVerifier.delegate;

      return ConfirmationResultDesktop(
        this,
        await _authDart!.signInWithPhoneNumber(phoneNumber, recaptchaVerifier),
      );
    } catch (e) {
      throw getFirebaseAuthException(e);
    }
  }

  @override
  Future<UserCredentialPlatform> signInWithPopup(AuthProvider provider) {
    // TODO: implement signInWithPopup
    throw UnimplementedError();
  }

  @override
  Future<void> signInWithRedirect(AuthProvider provider) {
    // TODO: implement signInWithRedirect
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() async {
    try {
      await _authDart!.signOut();
    } catch (e) {
      throw getFirebaseAuthException(e);
    }
  }

  @override
  Future<void> useAuthEmulator(String host, int port) async {
    try {
      await _authDart!.useAuthEmulator(host: host, port: port);

      return;
    } catch (e) {
      throw getFirebaseAuthException(e);
    }
  }

  @override
  Future<String> verifyPasswordResetCode(String code) async {
    try {
      return await _authDart!.verifyPasswordResetCode(code);
    } catch (e) {
      throw getFirebaseAuthException(e);
    }
  }

  @override
  Future<void> verifyPhoneNumber(
      {required String phoneNumber,
      required PhoneVerificationCompleted verificationCompleted,
      required PhoneVerificationFailed verificationFailed,
      required PhoneCodeSent codeSent,
      required PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout,
      Duration timeout = const Duration(seconds: 30),
      int? forceResendingToken,
      String? autoRetrievedSmsCodeForTesting}) {
    throw UnimplementedError(
        'verifyPhoneNumber() is not implemented for Web and Desktop based platforms.');
  }
}
