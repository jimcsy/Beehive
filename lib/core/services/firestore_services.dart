import 'package:beehive/core/services/module_repository.dart';
import 'package:beehive/core/services/room_repository.dart';
import 'package:beehive/core/services/user_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


// --- This is your new, clean service class! ---

class FirestoreService {
  // 1. Still the single source of truth for the _db instance
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  FirebaseAuth get auth => FirebaseAuth.instance; 

  // 2. Public properties for each repository
  late final UserRepository users;
  late final RoomRepository rooms;
  late final ModuleRepository modules;

  // 3. The constructor creates the repositories, passing the db instance
  FirestoreService() {
    users = UserRepository(_db);
    rooms = RoomRepository(_db);
    modules = ModuleRepository(_db);
  }
}


 