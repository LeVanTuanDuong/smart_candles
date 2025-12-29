import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Service to manage Firebase Authentication
class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal() {
    // Listen to auth state changes
    _auth.authStateChanges().listen((User? user) {
      _currentUser = user;
      notifyListeners();
    });
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Configure GoogleSignIn with client ID for web
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    // Web Client ID from Firebase Console (google-services.json)
    clientId: kIsWeb
        ? '427990378688-6l7kdagg582118kdg10c9j2uigk1vfl9.apps.googleusercontent.com'
        : null,
  );
  User? _currentUser;

  // Getters
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  String? get userId => _currentUser?.uid;
  String? get userEmail => _currentUser?.email;

  /// Initialize and get current user
  Future<void> initialize() async {
    _currentUser = _auth.currentUser;
    notifyListeners();
  }

  /// Sign in with email and password
  Future<UserCredential?> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      _currentUser = credential.user;
      notifyListeners();
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Đã xảy ra lỗi: $e');
    }
  }

  /// Register with email and password
  Future<UserCredential?> registerWithEmailPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Update display name if provided
      if (displayName != null && displayName.trim().isNotEmpty) {
        await credential.user?.updateDisplayName(displayName.trim());
        await credential.user?.reload();
        _currentUser = _auth.currentUser;
      } else {
        _currentUser = credential.user;
      }

      // Lưu user data vào Firestore
      if (credential.user != null) {
        await _saveUserToFirestore(credential.user!, displayName: displayName);
      }

      notifyListeners();
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Đã xảy ra lỗi: $e');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      // Sign out from Google if signed in with Google
      await _googleSignIn.signOut();
      // Sign out from Firebase
      await _auth.signOut();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      throw Exception('Không thể đăng xuất: $e');
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Đã xảy ra lỗi: $e');
    }
  }

  /// Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Sign out from Google first to ensure clean state (ignore errors)
      try {
        await _googleSignIn.signOut();
      } catch (e) {
        // Ignore sign out errors (may not be signed in)
      }

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // Obtain the auth details from the request
      if (googleUser == null) {
        // User cancelled the sign-in
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);
      _currentUser = userCredential.user;

      // Lưu user data vào Firestore
      if (userCredential.user != null) {
        await _saveUserToFirestore(
          userCredential.user!,
          displayName: googleUser.displayName,
        );
      }

      notifyListeners();
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Đăng nhập Google thất bại: $e');
    }
  }

  /// Lưu user data vào Firestore
  Future<void> _saveUserToFirestore(User user, {String? displayName}) async {
    try {
      final userRef = _firestore.collection('users').doc(user.uid);
      final userData = {
        'uid': user.uid,
        'email': user.email,
        'displayName': displayName ?? user.displayName ?? '',
        'photoURL': user.photoURL ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Kiểm tra user đã tồn tại chưa
      final docSnapshot = await userRef.get();
      if (docSnapshot.exists) {
        // Cập nhật thông tin đăng nhập
        await userRef.update({
          'lastLoginAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          // Cập nhật displayName và photoURL nếu có thay đổi
          if (displayName != null && displayName.isNotEmpty)
            'displayName': displayName,
          if (user.photoURL != null) 'photoURL': user.photoURL,
        });
      } else {
        // Tạo user mới
        await userRef.set(userData);
      }
    } catch (e) {
      // Không throw error để không ảnh hưởng đến flow đăng nhập
      debugPrint('Error saving user to Firestore: $e');
    }
  }

  /// Handle Firebase Auth exceptions and return user-friendly messages
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Mật khẩu quá yếu. Vui lòng sử dụng mật khẩu mạnh hơn.';
      case 'email-already-in-use':
        return 'Email này đã được sử dụng. Vui lòng đăng nhập hoặc sử dụng email khác.';
      case 'invalid-email':
        return 'Email không hợp lệ. Vui lòng kiểm tra lại.';
      case 'user-not-found':
        return 'Không tìm thấy tài khoản với email này.';
      case 'wrong-password':
        return 'Mật khẩu không đúng. Vui lòng thử lại.';
      case 'user-disabled':
        return 'Tài khoản này đã bị vô hiệu hóa. Vui lòng liên hệ hỗ trợ.';
      case 'too-many-requests':
        return 'Quá nhiều yêu cầu. Vui lòng thử lại sau.';
      case 'operation-not-allowed':
        return 'Thao tác không được phép. Vui lòng liên hệ hỗ trợ.';
      case 'network-request-failed':
        return 'Lỗi kết nối mạng. Vui lòng kiểm tra kết nối internet.';
      default:
        return e.message ?? 'Đã xảy ra lỗi: ${e.code}';
    }
  }
}
