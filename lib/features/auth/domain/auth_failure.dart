/// Why a sign-in/sign-up attempt failed, expressed independently of any UI
/// language. The data layer should never decide what sentence the user
/// reads — that's a presentation concern, so repositories return this
/// instead of a hardcoded Persian/English string.
enum AuthFailureReason {
  invalidCredentials,
  emailInUse,
  weakPassword,
  network,
  unknown,
}

class AuthFailure {
  final AuthFailureReason reason;
  final String? debugDetail;

  const AuthFailure(this.reason, [this.debugDetail]);

  @override
  String toString() => 'AuthFailure($reason, $debugDetail)';
}
