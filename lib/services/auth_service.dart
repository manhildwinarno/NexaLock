import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  /// Stream of Auth State changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Get Current Firebase User
  User? get currentUser => _auth.currentUser;

  /// Sign In with Email and Password and fetch UserModel with Role
  Future<UserModel?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final User? user = credential.user;
      if (user != null) {
        // Fetch custom user profile from Firestore to detect role
        UserModel? userModel = await _firestoreService.getUser(user.uid);

        // If user profile doesn't exist in Firestore yet, initialize standard user role
        if (userModel == null) {
          userModel = UserModel(
            uid: user.uid,
            name: user.displayName ?? email.split('@').first,
            email: user.email ?? email,
            role: 'user', // Default role
          );
          await _firestoreService.saveUser(userModel);
        }

        return userModel;
      }
      return null;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw Exception('An unexpected error occurred during sign in.');
    }
  }

  /// Sign Up with Email and Password
  Future<UserModel?> registerWithEmailAndPassword(String email, String password, String name) async {
    FirebaseApp? tempApp;
    try {
      tempApp = await Firebase.initializeApp(
        name: 'TemporaryRegisterApp',
        options: Firebase.app().options,
      );

      final UserCredential credential = await FirebaseAuth.instanceFor(app: tempApp)
          .createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final User? user = credential.user;
      if (user != null) {
        // Create default user profile in Firestore using the primary app's service
        final userModel = UserModel(
          uid: user.uid,
          name: name.trim().isEmpty ? email.split('@').first : name.trim(),
          email: user.email ?? email,
          role: 'user', // Default role
          rfidUid: '', // Empty RFID to be linked later
        );
        
        await _firestoreService.saveUser(userModel);
        return userModel;
      }
      return null;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw Exception('An unexpected error occurred during registration.');
    } finally {
      if (tempApp != null) {
        await tempApp.delete();
      }
    }
  }

  /// Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
