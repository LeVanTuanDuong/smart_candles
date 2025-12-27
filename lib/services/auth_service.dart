import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

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
