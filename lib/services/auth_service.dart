import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class AuthService extends GetxService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  int? _resendToken;

  User? get currentUser => _auth.currentUser;
  String? get userId => _auth.currentUser?.uid;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> verifyPhoneNumber(
    String phoneNumber, {
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
    Function(PhoneAuthCredential credential)? onAutoVerify,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          if (onAutoVerify != null) {
            onAutoVerify(credential);
          } else {
            await _auth.signInWithCredential(credential);
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          String errorMessage = 'Verification failed';
          if (e.code == 'invalid-phone-number') {
            errorMessage = 'Invalid phone number format';
          } else if (e.code == 'too-many-requests') {
            errorMessage = 'Too many requests. Try again later';
          } else if (e.message != null) {
            errorMessage = e.message!;
          }
          onError(errorMessage);
        },
        codeSent: (String verificationId, int? resendToken) {
          _resendToken = resendToken;
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Auto-retrieval timeout
        },
        forceResendingToken: _resendToken,
      );
    } catch (e) {
      onError(e.toString());
    }
  }

  Future<UserCredential> signInWithSmsCode(
    String verificationId,
    String smsCode,
  ) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-verification-code') {
        throw 'Invalid verification code';
      } else if (e.code == 'session-expired') {
        throw 'Session expired. Please try again';
      } else {
        throw e.message ?? 'Authentication failed';
      }
    }
  }

  // Convertir un numéro de téléphone en fake email
  String _phoneToEmail(String phone) {
    // Enlever le +
    final phoneNumber = phone.replaceAll('+', '');
    return '$phoneNumber@trashpicker.app';
  }

  // Lier un credential email/password au user Firebase actuel
  Future<void> linkPasswordCredential(String phone, String password) async {
    try {
      final email = _phoneToEmail(phone);
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );

      await _auth.currentUser?.linkWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'provider-already-linked') {
        throw 'Ce compte est déjà lié à un mot de passe';
      } else if (e.code == 'email-already-in-use') {
        throw 'Ce numéro est déjà utilisé';
      } else {
        throw e.message ?? 'Échec de la création du compte';
      }
    }
  }

  // Login avec numéro de téléphone + mot de passe
  Future<UserCredential> signInWithPhonePassword(
    String phone,
    String password,
  ) async {
    try {
      final email = _phoneToEmail(phone);
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw 'Aucun compte trouvé avec ce numéro';
      } else if (e.code == 'wrong-password') {
        throw 'Mot de passe incorrect';
      } else if (e.code == 'invalid-email') {
        throw 'Numéro de téléphone invalide';
      } else if (e.code == 'user-disabled') {
        throw 'Ce compte a été désactivé';
      } else {
        throw e.message ?? 'Échec de la connexion';
      }
    }
  }

  // Changer le mot de passe
  Future<void> updatePassword(String newPassword) async {
    try {
      await _auth.currentUser?.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw 'Le mot de passe est trop faible';
      } else if (e.code == 'requires-recent-login') {
        throw 'Veuillez vous reconnecter pour changer votre mot de passe';
      } else {
        throw e.message ?? 'Échec de la modification du mot de passe';
      }
    }
  }

  // Créer un compte admin/picker avec email/password
  Future<UserCredential> createUserWithEmailPassword(
    String phone,
    String password,
  ) async {
    try {
      final email = _phoneToEmail(phone);
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw 'Ce numéro est déjà utilisé';
      } else if (e.code == 'weak-password') {
        throw 'Le mot de passe est trop faible';
      } else {
        throw e.message ?? 'Échec de la création du compte';
      }
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  bool isAuthenticated() {
    return _auth.currentUser != null;
  }
}
