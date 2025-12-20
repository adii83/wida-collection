import 'dart:io';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../models/user_profile.dart';
import '../models/user_address.dart';
import 'package:flutter/foundation.dart';

class AuthController extends GetxController {
  AuthController(this._supabaseService);

  final SupabaseService _supabaseService;

  final isLoading = false.obs;
  final Rxn<User> currentUser = Rxn<User>();
  final RxnString lastError = RxnString();
  final Rxn<UserProfile> profile = Rxn<UserProfile>();
  final RxList<UserAddress> addresses = <UserAddress>[].obs;

  bool get canUseSupabase => _supabaseService.isReady;
  bool get isLoggedIn => currentUser.value != null;
  bool get isAdmin => profile.value?.role == 'admin';

  @override
  void onInit() {
    super.onInit();
    if (!_supabaseService.isReady) return;
    currentUser.value = _supabaseService.client?.auth.currentUser;
    if (currentUser.value != null) {
      _loadProfile();
    }
    _supabaseService.client?.auth.onAuthStateChange.listen((event) {
      currentUser.value = event.session?.user;
      if (currentUser.value != null) {
        _loadProfile();
      } else {
        profile.value = null;
      }
    });
  }

  Future<void> _loadProfile() async {
    final userId = _supabaseService.currentUserId;
    if (userId == null) return;
    try {
      final p = await _supabaseService.fetchProfile(userId);
      if (p != null) {
        debugPrint('Loaded Profile: ${p.email}, Role: ${p.role}');
        profile.value = p;
      }
      await fetchAddresses();
    } catch (_) {
      // ignore for now
    }
  }

  Future<bool> signIn(String email, String password) async {
    if (!_supabaseService.isReady) return false;
    try {
      isLoading.value = true;
      await _supabaseService.signIn(email, password);
      await _loadProfile(); // Force sequential load to ensure Admin checks work
      lastError.value = null;
      return true;
    } catch (e) {
      lastError.value = e.toString();
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Sign in using either email or username as identifier.
  Future<bool> signInWithIdentifier(String identifier, String password) async {
    if (!_supabaseService.isReady) return false;
    try {
      isLoading.value = true;
      final email = await _supabaseService.resolveEmailForLogin(identifier);
      if (email == null) {
        lastError.value = 'Akun tidak ditemukan';
        return false;
      }

      await _supabaseService.signIn(email, password);
      await _loadProfile(); // Force sequential load
      lastError.value = null;
      return true;
    } catch (e) {
      lastError.value = e.toString();
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> signUp(
    String email,
    String password, {
    required String fullName,
    required String username,
  }) async {
    if (!_supabaseService.isReady) return false;
    try {
      isLoading.value = true;
      final res = await _supabaseService.signUp(
        email,
        password,
        data: {
          'full_name': fullName,
          'username': username,
          'role': 'user', // Explicitly set default role in metadata
        },
      );
      final user = res?.user;

      if (user != null) {
        // Create or update profile row
        final profileModel = UserProfile(
          id: user.id,
          username: username,
          fullName: fullName,
          email: email,
        );
        await _supabaseService.upsertProfile(profileModel);
      }

      await _loadProfile(); // Force sequential load
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
    // Force state clear for UI responsiveness
    currentUser.value = null;
    profile.value = null;
  }

  Future<bool> updateProfile({
    String? fullName,
    String? username,
    String? phone,
    String? avatarUrl,
  }) async {
    if (!_supabaseService.isReady) return false;
    final user = currentUser.value;
    if (user == null) return false;

    try {
      isLoading.value = true;

      final currentProfile =
          profile.value ??
          UserProfile(
            id: user.id,
            username: username ?? user.email?.split('@').first ?? 'user',
            fullName: fullName ?? user.email ?? 'User',
            email: user.email,
          );

      final updated = currentProfile.copyWith(
        fullName: fullName,
        username: username,
        phone: phone,
        avatarUrl: avatarUrl,
      );

      final saved = await _supabaseService.upsertProfile(updated);
      if (saved != null) {
        profile.value = saved;
        return true;
      }
      return false;
    } catch (e) {
      lastError.value = e.toString();
      Get.snackbar(
        'Gagal menyimpan',
        'Terjadi kesalahan saat menyimpan profil.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateProfilePicture(File file) async {
    if (!_supabaseService.isReady) return false;
    final user = currentUser.value;
    if (user == null) return false;

    try {
      isLoading.value = true;

      // 1. Check size (5MB)
      final size = await file.length();
      if (size > 5 * 1024 * 1024) {
        lastError.value = 'Ukuran gambar maksimal 5MB';
        return false;
      }

      // 2. Upload
      final ext = file.path.split('.').last;
      final path = '${user.id}/${DateTime.now().millisecondsSinceEpoch}.$ext';
      final url = await _supabaseService.uploadAvatar(file, path);

      if (url == null) {
        lastError.value = 'Gagal upload gambar';
        return false;
      }

      // 3. Update profile
      return updateProfile(avatarUrl: url);
    } catch (e) {
      lastError.value = e.toString();
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> syncFcmToken(String token) async {
    if (!_supabaseService.isReady) return;
    final user = currentUser.value;
    if (user == null) return;

    // Ensure we have the latest profile data before updating
    // This prevents overwriting the 'role' with a default 'user' value
    if (profile.value == null) {
      await _loadProfile();
    }

    final current = profile.value;
    // If still null after load attempt, we can't safely update purely based on defaults
    // as we might overwrite critical fields like 'role'.
    if (current == null) return;

    // Avoid unnecessary updates
    if (current.fcmToken == token) return;

    try {
      // SAFE UPDATE: Only update the fcm_token column.
      // Do NOT Upsert the whole profile, as it risks overwriting the 'role'
      // if the local profile data is stale or incomplete.
      await _supabaseService.updateFcmToken(user.id, token);

      // Update local state locally without re-fetching potentially stale data
      profile.value = current.copyWith(fcmToken: token);
      debugPrint('FCM Token synced to Supabase (Safe Mode): $token');
    } catch (e) {
      debugPrint('Failed to sync FCM token: $e');
    }
  }

  Future<void> fetchAddresses() async {
    if (!_supabaseService.isReady) return;
    final userId = currentUser.value?.id;
    if (userId == null) return;

    try {
      final list = await _supabaseService.fetchAddresses(userId);
      addresses.assignAll(list);
    } catch (e) {
      debugPrint('Error fetching addresses: $e');
    }
  }

  Future<bool> upsertAddress(UserAddress address) async {
    if (!_supabaseService.isReady) return false;
    final userId = currentUser.value?.id;
    if (userId == null) return false;

    try {
      isLoading.value = true;
      final saved = await _supabaseService.upsertAddress(address, userId);
      if (saved != null) {
        await fetchAddresses(); // Refresh list
        return true;
      }
      return false;
    } catch (e) {
      lastError.value = e.toString();
      Get.snackbar('Error', 'Gagal menyimpan alamat');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deleteAddress(String addressId) async {
    if (!_supabaseService.isReady) return false;
    try {
      isLoading.value = true;
      await _supabaseService.deleteAddress(addressId);
      await fetchAddresses();
      return true;
    } catch (e) {
      lastError.value = e.toString();
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> setDefaultAddress(String addressId) async {
    if (!_supabaseService.isReady) return false;
    final userId = currentUser.value?.id;
    if (userId == null) return false;

    try {
      isLoading.value = true;
      await _supabaseService.setDefaultAddress(addressId, userId);
      await fetchAddresses();
      return true;
    } catch (e) {
      lastError.value = e.toString();
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
