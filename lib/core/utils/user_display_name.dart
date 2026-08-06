import '../../features/auth/domain/entities/user_entity.dart';

extension UserDisplayName on UserEntity {
  String get displayNameOrFallback {
    final name = displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final mail = email;
    if (mail != null && mail.isNotEmpty) return mail.split('@').first;
    return 'Guest';
  }

  String get avatarInitial =>
      displayNameOrFallback.substring(0, 1).toUpperCase();
}
