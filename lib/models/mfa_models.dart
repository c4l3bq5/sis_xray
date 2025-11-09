// lib/models/mfa_models.dart

class MFAVerifyResponse {
  final bool success;
  final String message;
  final MFAVerifyData? data;

  MFAVerifyResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory MFAVerifyResponse.fromJson(Map<String, dynamic> json) {
    return MFAVerifyResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null 
          ? MFAVerifyData.fromJson(json['data']) 
          : null,
    );
  }
}

class MFAVerifyData {
  final int userId;
  final bool mfaVerified;

  MFAVerifyData({
    required this.userId,
    required this.mfaVerified,
  });

  factory MFAVerifyData.fromJson(Map<String, dynamic> json) {
    return MFAVerifyData(
      userId: json['userId'] ?? 0,
      mfaVerified: json['mfaVerified'] ?? false,
    );
  }
}

class MFASetupData {
  final int userId;
  final String secret;
  final String qrCode;
  final String otpauthUrl;
  final List<String> backupCodes;
  final String message;

  MFASetupData({
    required this.userId,
    required this.secret,
    required this.qrCode,
    required this.otpauthUrl,
    required this.backupCodes,
    required this.message,
  });

  factory MFASetupData.fromJson(Map<String, dynamic> json) {
    return MFASetupData(
      userId: json['userId'] ?? 0,
      secret: json['secret'] ?? '',
      qrCode: json['qrCode'] ?? '',
      otpauthUrl: json['otpauthUrl'] ?? '',
      backupCodes: (json['backupCodes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      message: json['message'] ?? '',
    );
  }
}

class MFAStatusResponse {
  final bool success;
  final MFAStatusData? data;

  MFAStatusResponse({
    required this.success,
    this.data,
  });

  factory MFAStatusResponse.fromJson(Map<String, dynamic> json) {
    return MFAStatusResponse(
      success: json['success'] ?? false,
      data: json['data'] != null 
          ? MFAStatusData.fromJson(json['data']) 
          : null,
    );
  }
}

class MFAStatusData {
  final bool mfaEnabled;
  final bool hasSecret;
  final int userId;

  MFAStatusData({
    required this.mfaEnabled,
    required this.hasSecret,
    required this.userId,
  });

  factory MFAStatusData.fromJson(Map<String, dynamic> json) {
    return MFAStatusData(
      mfaEnabled: json['mfaEnabled'] ?? false,
      hasSecret: json['hasSecret'] ?? false,
      userId: json['userId'] ?? 0,
    );
  }
}