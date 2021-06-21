// File created by
// Lung Razvan <long1eu>
// on 24/11/2019

part of 'sign_in_it_io.dart';

/// Helper class for persisting tokens between sessions
class DataStorage {
  /// Create an instance that will persist the values using [store].
  const DataStorage._({required Store store, required String clientId})
      : _store = store,
        _clientId = clientId;

  final Store _store;
  final String _clientId;

  static const String _kIdTokenKey = 'idToken';
  static const String _kAccessTokenKey = 'accessToken';
  static const String _kRefreshTokenKey = 'refreshToken';
  static const String _kScopeKey = 'scope';
  static const String _kExpirationAtKey = 'expiresAt';
  static const String _kIdKey = 'id';
  static const String _kNameKey = 'name';
  static const String _kEmailKey = 'email';
  static const String _kPictureKey = 'picture';

  /// The is of the user
  ///
  /// In case there is no user logged in this value is the id of the last user
  /// that was logged in. This id can be used as a hint when the user tries to
  /// login again.
  String? get id => _store.get(_getKey(_kIdKey));

  /// Saves the JSON Web Token (JWT) that contains digitally signed identity
  /// information about the user.
  String? get idToken => _store.get(_getKey(_kIdTokenKey));

  set idToken(String? value) => _setValue(_kIdTokenKey, value);

  /// Saves the token that your application sends to authorize a Google API
  /// request.
  String? get accessToken => _store.get(_getKey(_kAccessTokenKey));

  set accessToken(String? value) => _setValue(_kAccessTokenKey, value);

  /// Saves the remaining lifetime of the access token.
  DateTime? get expiresAt {
    final String? date = _store.get(_getKey(_kExpirationAtKey));
    return date != null ? DateTime.parse(date) : null;
  }

  set expiresAt(DateTime? value) {
    _setValue(_kExpirationAtKey, value?.toIso8601String() ?? '');
  }

  /// Saves the token that you can use to obtain a new access token.
  ///
  /// Refresh tokens are present if you provided a
  /// [SignInItIo._exchangeEndpoint] value and are valid until the
  /// user revokes access.
  String? get refreshToken => _store.get(_getKey(_kRefreshTokenKey));

  set refreshToken(String? value) => _setValue(_kRefreshTokenKey, value);

  /// Retrieve the authentication data after sign in.
  platform.GoogleSignInTokenData? get tokenData {
    if (idToken != null || accessToken != null) {
      return platform.GoogleSignInTokenData(
          idToken: idToken, accessToken: accessToken);
    }

    return null;
  }

  set tokenData(platform.GoogleSignInTokenData? data) {
    idToken = data?.idToken ?? '';
    accessToken = data?.accessToken ?? '';
  }

  /// Save the scopes that we were granted access to in the last authorization.
  ///
  /// Returns an empty list if no authorization has take place yet.
  List<String> get scopes {
    final String? value = _store.get(_getKey(_kScopeKey));
    if (value == null || value.isEmpty) {
      return <String>[];
    }

    return value.split(' ');
  }

  set scopes(List<String> value) {
    _setValue(_kScopeKey, value.join(' '));
  }

  /// Convenience method to update all fields persisted by this object
  void saveResult(Map<String, dynamic> result) {
    refreshToken = result['refresh_token'] ?? refreshToken;
    idToken = result['id_token'];
    accessToken = result['access_token'];
    scopes = result['scope'].split(' ');
    expiresAt = DateTime.now()
        .add(Duration(seconds: int.parse('${result['expires_in']}')));
  }

  void saveUserProfile(Map<String, dynamic> result) {
    _setValue(_kIdKey, result['sub']);
    _setValue(_kNameKey, result['name']);
    _setValue(_kEmailKey, result['email']);
    _setValue(_kPictureKey, result['picture']);
  }

  /// Convenience method to clear all entries of this [_clientId].
  ///
  /// This can be used to sign out only a specific user
  void clear() {
    // We don't want to clear the id of the user, in case he tries to login
    // again we can use the id to set it as a hint for the Google Auth Server
    // _setValue(_kIdKey, null);

    _setValue(_kIdTokenKey, null);
    _setValue(_kAccessTokenKey, null);
    _setValue(_kRefreshTokenKey, null);
    _setValue(_kScopeKey, null);
    _setValue(_kExpirationAtKey, null);
    _setValue(_kNameKey, null);
    _setValue(_kEmailKey, null);
    _setValue(_kPictureKey, null);
  }

  /// Convenience method to clear all user this objects persisted
  void clearAll() {
    _store.clearAll();
  }

  /// Retrieve information about this signed in user based on the id_token.
  platform.GoogleSignInUserData? get userData {
    if (idToken != null) {
      return platform.GoogleSignInUserData(
        id: _store.get(_getKey(_kIdKey))!,
        displayName: _store.get(_getKey(_kNameKey)),
        email: _store.get(_getKey(_kEmailKey))!,
        photoUrl: _store.get(_getKey(_kPictureKey)),
        idToken: idToken,
      );
    }

    return null;
  }

  void _setValue(String key, String? value) {
    if (value == null) {
      _store.remove(_getKey(key));
    } else {
      _store.set(_getKey(key), value);
    }
  }

  String _getKey(String field) => 'DataStorage___$_clientId\__$field';
}

/// Interface for persisting key/value pairs
abstract class Store {
  /// Persist the [value] at [key].
  void set(String key, String value);

  /// Remove the value at specified [key] if exists.
  void remove(String key);

  /// Get the value at specified [key] or nul if it doesn't exists.
  String? get(String key);

  /// Remove all the values store.
  void clearAll();
}

class _SharedPreferencesStore extends Store {
  _SharedPreferencesStore(this._preferences);

  final SharedPreferences _preferences;

  @override
  String? get(String key) {
    return _preferences.get(key)?.toString();
  }

  @override
  void remove(String key) {
    _preferences.remove(key);
  }

  @override
  void set(String key, String value) {
    _preferences.setString(key, value);
  }

  @override
  void clearAll() {
    _preferences.clear();
  }
}
