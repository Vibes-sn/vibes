import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibes/core/services/database_service.dart';

class UserProvider extends ChangeNotifier {
  UserProvider({SupabaseClient? client, DatabaseService? database})
    : _client = client ?? Supabase.instance.client,
      _database = database ?? DatabaseService(client: client) {
    _authSub = _client.auth.onAuthStateChange.listen((_) => _handleAuth());
    _handleAuth();
  }

  final SupabaseClient _client;
  final DatabaseService _database;
  StreamSubscription<AuthState>? _authSub;
  StreamSubscription? _profileSub;

  User? _user;
  String _role = 'viber';
  bool _isVerified = false;
  bool _loading = true;
  bool _organizerMode = false;

  User? get user => _user;
  String get role => _role;
  bool get isVerified => _isVerified;
  bool get isHost => _role == 'host';
  bool get isLoading => _loading;
  bool get organizerMode => _organizerMode;

  void setOrganizerMode(bool enabled) {
    if (!isHost) return;
    if (_organizerMode == enabled) return;
    _organizerMode = enabled;
    notifyListeners();
  }

  Future<void> refresh() => _refresh();

  Future<void> _refresh() async {
    try {
      if (_user == null) return;
      _loading = true;
      notifyListeners();
      final profile = await _database.fetchProfile(_user!.id);
      _role = profile?.role ?? 'viber';
      _isVerified = profile?.isVerified ?? false;
    } catch (_) {
      _role = 'viber';
      _isVerified = false;
      _organizerMode = false;
    } finally {
      if (_role != 'host') {
        _organizerMode = false;
      }
      _loading = false;
      notifyListeners();
    }
  }

  void _handleAuth() {
    _user = _client.auth.currentUser;
    _profileSub?.cancel();
    if (_user == null) {
      _role = 'viber';
      _isVerified = false;
      _organizerMode = false;
      _loading = false;
      notifyListeners();
      return;
    }
    _loading = true;
    notifyListeners();
    _profileSub = _database
        .watchProfile(_user!.id)
        .listen(
          (profile) {
            _role = profile?.role ?? 'viber';
            _isVerified = profile?.isVerified ?? false;
            if (_role != 'host') {
              _organizerMode = false;
            }
            _loading = false;
            notifyListeners();
          },
          onError: (_) {
            _role = 'viber';
            _isVerified = false;
            _organizerMode = false;
            _loading = false;
            notifyListeners();
          },
        );
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _profileSub?.cancel();
    super.dispose();
  }
}

class UserScope extends InheritedNotifier<UserProvider> {
  const UserScope({
    super.key,
    required UserProvider notifier,
    required Widget child,
  }) : super(notifier: notifier, child: child);

  static UserProvider of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<UserScope>();
    if (scope?.notifier == null) {
      throw StateError('UserScope not found in widget tree.');
    }
    return scope!.notifier!;
  }
}
