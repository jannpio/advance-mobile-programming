import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pioquinto_advmobprog/constants.dart';

ValueNotifier<UserService> userService = ValueNotifier(UserService());

class UserService {
  Map<String, dynamic> data = {};

  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  User? get currentUser => firebaseAuth.currentUser;
  Stream<User?> get authStateChanges => firebaseAuth.authStateChanges();

  /// ------------------- MongoDB -------------------

  Future<Map<String, dynamic>> loginUser(String email, String password) async {
    final response = await post(
      Uri.parse('$host/api/users/login'),
      body: {"email": email, "password": password},
    );

    if (response.statusCode == 200) {
      data = jsonDecode(response.body);
      data['type'] = 'mongo';
      await saveMongoUserData(data);
      return data;
    } else {
      throw Exception('Failed to login with MongoDB');
    }
  }

  Future<Map<String, dynamic>> registerUser(
      String firstName,
      String lastName,
      int age,
      String gender,
      String contactNumber,
      String email,
      String username,
      String password,
      String address) async {
    final response = await post(
      Uri.parse('$host/api/users/register'),
      body: {
        "firstName": firstName,
        "lastName": lastName,
        "age": age.toString(),
        "gender": gender,
        "contactNumber": contactNumber,
        "email": email,
        "username": username,
        "password": password,
        "address": address,
      },
    );

    if (response.statusCode == 201) {
      data = jsonDecode(response.body);
      data['type'] = 'mongo';
      await saveMongoUserData(data);
      return data;
    } else {
      throw Exception('Failed to register with MongoDB');
    }
  }

  Future<Map<String, dynamic>> updateUser(Map<String, dynamic> userData) async {
    final userId = userData['id'];
    final payload = _cleanseData(userData);

    final response = await put(
      Uri.parse('$host/api/users/$userId'),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final updatedData = jsonDecode(response.body);
      updatedData['type'] = 'mongo';
      await saveMongoUserData(updatedData);
      return updatedData;
    } else {
      throw Exception('Failed to update user: ${response.statusCode} ${response.body}');
    }
  }

  Future<void> deleteUser(String id) async {
    final response = await post(Uri.parse('$host/api/users/delete/$id'));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete user');
    }
    await logoutMongo();
  }

  /// ------------------- Firebase + Firestore -------------------

  Future<UserCredential> signIn({required String email, required String password}) async {
    final cred = await firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
    final userData = await getFirebaseUserData();
    if (userData.isEmpty) {
      await saveFirebaseUserData({
        "uid": cred.user?.uid,
        "email": email,
        "type": "firebase",
        "isActive": true,
      });
    }
    return cred;
  }

  Future<UserCredential> createAccountWithDetails({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required int age,
    required String gender,
    required String contactNumber,
    required String username,
    required String address,
  }) async {
    final cred = await firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await saveFirebaseUserData({
      "uid": cred.user?.uid,
      "email": email,
      "firstName": firstName,
      "lastName": lastName,
      "age": age,
      "gender": gender,
      "contactNumber": contactNumber,
      "username": username,
      "address": address,
      "type": "firebase",
      "isActive": true,
    });

    return cred;
  }

  Future<void> updateUsername({required String username}) async {
    if (currentUser != null) {
      await currentUser!.updateDisplayName(username);
      final userData = await getFirebaseUserData();
      userData['username'] = username;
      await saveFirebaseUserData(userData);
    }
  }

  Future<void> deleteAccount({required String email, required String password}) async {
    if (currentUser != null) {
      final credential = EmailAuthProvider.credential(email: email, password: password);
      await currentUser!.reauthenticateWithCredential(credential);
      await firestore.collection('users').doc(currentUser!.uid).delete();
      await currentUser!.delete();
      await logoutFirebase();
    }
  }

  Future<void> resetPasswordFromCurrentPassword({
    required String currentPassword,
    required String newPassword,
    required String email,
  }) async {
    final credential = EmailAuthProvider.credential(email: email, password: currentPassword);
    await currentUser!.reauthenticateWithCredential(credential);
    await currentUser!.updatePassword(newPassword);
  }

  Future<void> signOut() async {
    await firebaseAuth.signOut();
    await logoutFirebase();
  }

  /// ------------------- MongoDB (SharedPreferences) -------------------

  Future<void> saveMongoUserData(Map<String, dynamic> userData) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('mongo_user', jsonEncode(userData));
  }

  Future<Map<String, dynamic>> getMongoUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('mongo_user');
    if (userJson == null) return {};
    return jsonDecode(userJson);
  }

  Future<bool> isMongoLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('mongo_user') != null;
  }

  Future<void> logoutMongo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('mongo_user');
  }

  /// ------------------- Firebase (Firestore) -------------------

  Future<void> saveFirebaseUserData(Map<String, dynamic> userData) async {
    if (currentUser == null) return;
    final uid = currentUser!.uid;

    await firestore.collection('users').doc(uid).set(userData, SetOptions(merge: true));
    data = userData;
  }

  Future<Map<String, dynamic>> getFirebaseUserData() async {
    if (currentUser == null) return {};
    final uid = currentUser!.uid;

    final doc = await firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      data = doc.data() ?? {};
      return data;
    }
    return {};
  }

  Future<bool> isFirebaseLoggedIn() async {
    if (currentUser == null) return false;
    final doc = await firestore.collection('users').doc(currentUser!.uid).get();
    return doc.exists;
  }

  Future<void> logoutFirebase() async {
    data = {};
  }

  Future<void> saveUserData(Map<String, dynamic> userData) async {
    if (userData['type'] == 'firebase') {
      await saveFirebaseUserData(userData);
    } else {
      await saveMongoUserData(userData);
    }
  }

  Future<Map<String, dynamic>> getUserData() async {
    if (await isMongoLoggedIn()) {
      return await getMongoUserData();
    } else if (await isFirebaseLoggedIn()) {
      return await getFirebaseUserData();
    }
    return {};
  }

  Future<void> logout() async {
    if (await isMongoLoggedIn()) {
      await logoutMongo();
    } else if (await isFirebaseLoggedIn()) {
      await logoutFirebase();
      await firebaseAuth.signOut();
    }
  }

  Map<String, dynamic> _cleanseData(Map<String, dynamic> data) {
    return Map.fromEntries(
      data.entries.where((entry) => entry.value != null && entry.value != ''),
    );
  }
}
