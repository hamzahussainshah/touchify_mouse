import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../shared/models/device_model.dart';

/// Writes to Firestore:
///   users/{uid}                          — user profile
///   users/{uid}/devices/{deviceId}        — phone/tablet running this app
///   users/{uid}/connections/{autoId}      — log of desktop connections
class UserRepository {
  UserRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  /// Upsert profile + capture this phone/tablet under the user's devices.
  /// Called after every successful sign-in.
  Future<void> upsertOnSignIn(User user) async {
    final userDoc = _users.doc(user.uid);
    final now = FieldValue.serverTimestamp();

    await userDoc.set({
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'photoUrl': user.photoURL,
      'signInProvider': user.providerData.isNotEmpty
          ? user.providerData.first.providerId
          : 'unknown',
      'lastSeenAt': now,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final device = await _capturePhoneDevice();
    if (device != null) {
      await userDoc.collection('devices').doc(device['deviceId']).set({
        ...device,
        'lastSeenAt': now,
        'firstSeenAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  /// Append a connection record when the user pairs with a desktop.
  /// No-op if the user isn't signed in (anonymous use is allowed).
  Future<void> logDesktopConnection({
    required String? uid,
    required DeviceModel desktop,
  }) async {
    if (uid == null) return;
    await _users.doc(uid).collection('connections').add({
      'desktopId': desktop.id,
      'desktopName': desktop.name,
      'desktopOs': desktop.os,
      'desktopIp': desktop.ipAddress,
      'desktopPort': desktop.port,
      'connectedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<Map<String, dynamic>?> _capturePhoneDevice() async {
    try {
      final pkg = await PackageInfo.fromPlatform();
      final info = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final a = await info.androidInfo;
        return {
          'deviceId': a.id,
          'platform': 'android',
          'model': a.model,
          'manufacturer': a.manufacturer,
          'osVersion': a.version.release,
          'sdkInt': a.version.sdkInt,
          'isPhysicalDevice': a.isPhysicalDevice,
          'appVersion': pkg.version,
          'buildNumber': pkg.buildNumber,
        };
      }
      if (Platform.isIOS) {
        final i = await info.iosInfo;
        return {
          'deviceId': i.identifierForVendor ?? 'unknown',
          'platform': 'ios',
          'model': i.utsname.machine,
          'manufacturer': 'Apple',
          'osVersion': i.systemVersion,
          'isPhysicalDevice': i.isPhysicalDevice,
          'appVersion': pkg.version,
          'buildNumber': pkg.buildNumber,
        };
      }
    } catch (_) {
      // Device info is best-effort; sign-in must not fail because we
      // couldn't read the model.
    }
    return null;
  }
}
