import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettings {
  static const String _keyTeamInvites = 'notif_team_invites';
  static const String _keyTournamentUpdates = 'notif_tournament_updates';
  static const String _keyGeneralInfo = 'notif_general_info';
  static const String _keySound = 'notif_sound';
  static const String _keyVibration = 'notif_vibration';

  // Get notification preferences
  static Future<bool> getTeamInvitesEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyTeamInvites) ?? true;
  }

  static Future<bool> getTournamentUpdatesEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyTournamentUpdates) ?? true;
  }

  static Future<bool> getGeneralInfoEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyGeneralInfo) ?? true;
  }

  static Future<bool> getSoundEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keySound) ?? true;
  }

  static Future<bool> getVibrationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyVibration) ?? true;
  }

  // Set notification preferences
  static Future<void> setTeamInvitesEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyTeamInvites, enabled);
  }

  static Future<void> setTournamentUpdatesEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyTournamentUpdates, enabled);
  }

  static Future<void> setGeneralInfoEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyGeneralInfo, enabled);
  }

  static Future<void> setSoundEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySound, enabled);
  }

  static Future<void> setVibrationEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyVibration, enabled);
  }

  // Get all settings as a map
  static Future<Map<String, bool>> getAllSettings() async {
    return {
      'teamInvites': await getTeamInvitesEnabled(),
      'tournamentUpdates': await getTournamentUpdatesEnabled(),
      'generalInfo': await getGeneralInfoEnabled(),
      'sound': await getSoundEnabled(),
      'vibration': await getVibrationEnabled(),
    };
  }

  // Check if a notification should be shown based on type and settings
  static Future<bool> shouldShowNotification(String type) async {
    switch (type) {
      case 'invite':
        return await getTeamInvitesEnabled();
      case 'tournament':
        return await getTournamentUpdatesEnabled();
      case 'info':
        return await getGeneralInfoEnabled();
      default:
        return true;
    }
  }
}