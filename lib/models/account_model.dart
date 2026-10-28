import 'package:cloud_firestore/cloud_firestore.dart';

/// Where an account stands with the administrator
enum AccountStatus {
  pending,
  approved,
  blocked;

  static AccountStatus parse(Object? value) => AccountStatus.values.firstWhere(
        (status) => status.name == value,
        orElse: () => AccountStatus.pending,
      );
}

/// Features the administrator can switch off, for everyone or for one user
enum AppFeature { savings, statement, cloudSync }

/// What the signed-in user may see right now
enum AccessState { signedOut, loading, maintenance, pending, blocked, approved }

/// One document in /accounts/{uid}, managed by the administrator
class AppAccount {
  const AppAccount({
    required this.uid,
    required this.email,
    this.displayName = '',
    this.photoUrl,
    this.status = AccountStatus.pending,
    this.createdAt,
    this.statusChangedAt,
    this.blockedReason,
    this.features = const {},
  });

  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final AccountStatus status;
  final DateTime? createdAt;
  final DateTime? statusChangedAt;
  final String? blockedReason;

  /// Per-user overrides of the app-wide feature switches
  final Map<AppFeature, bool> features;

  factory AppAccount.fromMap(String uid, Map<String, dynamic> data) {
    return AppAccount(
      uid: uid,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
      status: AccountStatus.parse(data['status']),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      statusChangedAt: (data['statusChangedAt'] as Timestamp?)?.toDate(),
      blockedReason: data['blockedReason'] as String?,
      features: _parseFeatures(data['features']),
    );
  }

  AppAccount copyWith({
    AccountStatus? status,
    String? blockedReason,
    Map<AppFeature, bool>? features,
  }) {
    return AppAccount(
      uid: uid,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
      status: status ?? this.status,
      createdAt: createdAt,
      statusChangedAt: status == null ? statusChangedAt : DateTime.now(),
      blockedReason: (status ?? this.status) == AccountStatus.blocked
          ? (blockedReason ?? this.blockedReason)
          : null,
      features: features ?? this.features,
    );
  }
}

/// The /config/app document: maintenance mode and app-wide switches
class AppConfig {
  const AppConfig({
    this.maintenance = false,
    this.maintenanceMessage = '',
    this.requireApproval = true,
    this.features = const {},
  });

  final bool maintenance;
  final String maintenanceMessage;

  /// When false, new users are approved as soon as they sign in
  final bool requireApproval;
  final Map<AppFeature, bool> features;

  factory AppConfig.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const AppConfig();
    return AppConfig(
      maintenance: data['maintenance'] == true,
      maintenanceMessage: data['maintenanceMessage'] as String? ?? '',
      requireApproval: data['requireApproval'] != false,
      features: _parseFeatures(data['features']),
    );
  }

  /// Features are on unless switched off
  bool isEnabled(AppFeature feature) => features[feature] ?? true;
}

Map<AppFeature, bool> _parseFeatures(Object? value) {
  if (value is! Map) return const {};
  return {
    for (final feature in AppFeature.values)
      if (value[feature.name] is bool) feature: value[feature.name] as bool,
  };
}

/// Decides what the user may see. Kept free of Firebase so it can be tested.
AccessState resolveAccess({
  required bool signedIn,
  required bool isAdmin,
  required bool loaded,
  required AppConfig config,
  AppAccount? account,
}) {
  if (!signedIn) return AccessState.signedOut;
  // Admins always get in, even during maintenance, so they can fix things
  if (isAdmin) return AccessState.approved;
  if (!loaded) return AccessState.loading;
  if (config.maintenance) return AccessState.maintenance;
  return switch (account?.status) {
    AccountStatus.approved => AccessState.approved,
    AccountStatus.blocked => AccessState.blocked,
    _ => AccessState.pending,
  };
}

/// A per-user override wins over the app-wide switch
bool resolveFeature(
        AppFeature feature, AppConfig config, AppAccount? account) =>
    account?.features[feature] ?? config.isEnabled(feature);
