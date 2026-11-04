/// Firebase is intentionally not initialized in this build.
/// `Firebase.initializeApp` must wait for real platform options.
/// Google and Facebook sign-in are not completed locally.
class FirebaseGate {
  const FirebaseGate._();

  static const configured = false;

  static const status =
      'Firebase is not configured. Add google-services.json and '
      'GoogleService-Info.plist, then initialize Firebase with the generated '
      'options. Do not ship service-account keys in the app.';
}
