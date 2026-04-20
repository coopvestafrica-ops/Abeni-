import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../models/app_user.dart';
import '../services/firebase_service.dart';

/// Handles authentication.
/// Uses Firebase when initialized; otherwise a local in-memory mock so the
/// UI is fully functional in demo mode.
class AuthRepository {
  AuthRepository();

  AppUser? _mockUser;
  final _mockAuthController = StreamController<AppUser?>.broadcast();

  bool get _useFirebase => FirebaseService.isInitialized;

  Stream<AppUser?> authStateChanges() {
    if (_useFirebase) {
      return fb.FirebaseAuth.instance.authStateChanges().asyncMap((user) async {
        if (user == null) return null;
        try {
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get()
              .timeout(const Duration(seconds: 8));
          final data = doc.data();
          if (data != null) {
            return AppUser.fromMap({...data, 'id': user.uid});
          }
        } catch (_) {
          // Firestore may be offline or not yet provisioned; fall back to
          // the minimal user object from the auth record.
        }
        return AppUser(
          id: user.uid,
          email: user.email ?? '',
          fullName: user.displayName ?? '',
          phone: '',
          deliveryAddress: '',
        );
      });
    }
    return _mockAuthController.stream;
  }

  AppUser? get currentUser => _mockUser;

  Future<AppUser> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String deliveryAddress,
  }) async {
    if (_useFirebase) {
      final cred = await fb.FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      await cred.user!.updateDisplayName(fullName);
      final user = AppUser(
        id: cred.user!.uid,
        email: email,
        fullName: fullName,
        phone: phone,
        deliveryAddress: deliveryAddress,
      );
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.id)
            .set(user.toMap())
            .timeout(const Duration(seconds: 10));
      } catch (_) {
        // Auth succeeded; ignore Firestore write failures so the user can
        // still sign in. Profile will be retried on next update.
      }
      return user;
    }
    _mockUser = AppUser(
      id: 'demo-${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      fullName: fullName,
      phone: phone,
      deliveryAddress: deliveryAddress,
    );
    _mockAuthController.add(_mockUser);
    return _mockUser!;
  }

  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    if (_useFirebase) {
      final cred = await fb.FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(cred.user!.uid)
            .get()
            .timeout(const Duration(seconds: 8));
        final data = doc.data();
        if (data != null) {
          return AppUser.fromMap({...data, 'id': cred.user!.uid});
        }
      } catch (_) {
        // Firestore may be offline — continue with auth-only user.
      }
      return AppUser(
        id: cred.user!.uid,
        email: email,
        fullName: cred.user!.displayName ?? '',
        phone: '',
        deliveryAddress: '',
      );
    }
    _mockUser = AppUser(
      id: 'demo-user',
      email: email,
      fullName: 'Demo Customer',
      phone: '+234 000 000 0000',
      deliveryAddress: '123 Demo Street, Lagos',
    );
    _mockAuthController.add(_mockUser);
    return _mockUser!;
  }

  Future<void> signOut() async {
    if (_useFirebase) {
      await fb.FirebaseAuth.instance.signOut();
    } else {
      _mockUser = null;
      _mockAuthController.add(null);
    }
  }

  Future<AppUser> updateProfile(AppUser user) async {
    if (_useFirebase) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.id)
          .set(user.toMap(), SetOptions(merge: true))
          .timeout(const Duration(seconds: 10));
    } else {
      _mockUser = user;
      _mockAuthController.add(user);
    }
    return user;
  }
}
