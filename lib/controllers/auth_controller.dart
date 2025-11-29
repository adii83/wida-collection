import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class AuthController extends GetxController {
  AuthController(this._supabaseService);

  final SupabaseService _supabaseService;

  final isLoading = false.obs;
  final Rxn<User> currentUser = Rxn<User>();
  final RxnString lastError = RxnString();

  bool get canUseSupabase => _supabaseService.isReady;
  bool get isLoggedIn => currentUser.value != null;

  @override
  void onInit() {
    super.onInit();
    if (!_supabaseService.isReady) return;
    currentUser.value = _supabaseService.client?.auth.currentUser;
    _supabaseService.client?.auth.onAuthStateChange.listen((event) {
      currentUser.value = event.session?.user;
    });
  }

  Future<bool> signIn(String email, String password) async {
    if (!_supabaseService.isReady) return false;
    try {
      isLoading.value = true;
      await _supabaseService.signIn(email, password);
      lastError.value = null;
      return true;
    } catch (e) {
      lastError.value = e.toString();
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> signUp(String email, String password) async {
    if (!_supabaseService.isReady) return false;
    try {
      isLoading.value = true;
      await _supabaseService.signUp(email, password);
      lastError.value = null;
      return true;
    } catch (e) {
      lastError.value = e.toString();
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signOut() async {
    if (!_supabaseService.isReady) return;
    await _supabaseService.signOut();
  }
}
