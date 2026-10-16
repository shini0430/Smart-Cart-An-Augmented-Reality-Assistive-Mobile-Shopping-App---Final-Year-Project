import 'package:firebase_auth/firebase_auth.dart';

import 'api_service.dart';

class UserProfile {
  final String uid;
  final String name;
  final String phoneNumber;
  final String address;
  final String email;

  UserProfile({
    required this.uid,
    required this.name,
    required this.phoneNumber,
    required this.address,
    required this.email,
  });

  // ============================================================
  // CONVERT PROFILE TO MAP
  // ============================================================

  Map<String, dynamic> toMap() {
    return {
      'user_uid': uid,
      'name': name,
      'phone_number': phoneNumber,
      'address': address,
      'email': email,
    };
  }

  // ============================================================
  // CREATE PROFILE FROM MYSQL DATA
  // ============================================================

  factory UserProfile.fromMap(Map<String, dynamic> map, [String? uid]) {
    return UserProfile(
      uid: uid ?? (map['user_uid'] ?? map['uid'] ?? '').toString(),

      name: (map['name'] ?? '').toString(),

      phoneNumber:
          (map['phone_number'] ?? map['phoneNumber'] ?? map['phone'] ?? '')
              .toString(),

      address: (map['address'] ?? '').toString(),

      email: (map['email'] ?? '').toString(),
    );
  }
}

class ProfileService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ============================================================
  // GET PROFILE FROM MYSQL
  // ============================================================

  Future<UserProfile?> getUserProfile() async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        print('PROFILE: No logged-in user.');
        return null;
      }

      final response = await ApiService.get('get_profile.php');

      print('PROFILE GET RESPONSE: $response');

      if (response == null) {
        print('PROFILE: No response from server.');
        return null;
      }

      if (response['status'] == 'success') {
        final data = response['data'];

        if (data is Map) {
          return UserProfile.fromMap(Map<String, dynamic>.from(data), user.uid);
        }
      }

      print('PROFILE GET FAILED: ${response['message'] ?? 'Unknown error'}');

      return null;
    } catch (e) {
      print('PROFILE GET ERROR: $e');
      return null;
    }
  }

  // ============================================================
  // SAVE / UPDATE PROFILE IN MYSQL
  // ============================================================

  Future<void> saveUserProfile(UserProfile profile) async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        print('PROFILE: No logged-in user.');
        return;
      }

      final body = {
        'name': profile.name,
        'phone_number': profile.phoneNumber,
        'address': profile.address,
        'email': user.email ?? profile.email,
      };

      print('PROFILE SAVE BODY: $body');

      final response = await ApiService.post('save_profile.php', body);

      print('PROFILE SAVE RESPONSE: $response');

      if (response == null) {
        print('PROFILE: No response from server.');
        return;
      }

      if (response['status'] == 'success') {
        print('PROFILE: Saved successfully to MySQL.');
      } else {
        print('PROFILE SAVE FAILED: ${response['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      print('PROFILE SAVE ERROR: $e');
    }
  }
}
