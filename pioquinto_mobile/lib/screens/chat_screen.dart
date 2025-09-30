import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../services/chat_service.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';
import '../screens/chat_detailscreen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _searchChatController = TextEditingController();
  final ChatService _chatService = ChatService();
  final UserService _userService = UserService();

  String? _currentUserEmail;
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentUserEmail();
    _searchChatController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {
      _searchText = _searchChatController.text;
    });
  }

  Future<void> _loadCurrentUserEmail() async {
    final userData = await _userService.getUserData();
    setState(() {
      _currentUserEmail = userData['email']?.toString();
    });
  }

  @override
  void dispose() {
    _searchChatController.removeListener(_onSearchChanged);
    _searchChatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SizedBox(height: 20.h),
          // Search bar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
            child: TextField(
              controller: _searchChatController,
              style: TextStyle(fontSize: 14.sp),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle: TextStyle(fontSize: 14.sp, color: Colors.grey),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchChatController.text.isNotEmpty
                    ? IconButton(
                        tooltip: 'Clear',
                        icon: const Icon(Icons.cancel),
                        onPressed: () {
                          setState(() {
                            _searchChatController.clear();
                            _searchText = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),
          SizedBox(height: 10.h),

          // Users Stream
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _chatService.getUsersStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    padding: EdgeInsets.all(16.sp),
                    child: const Center(
                      child: CircularProgressIndicator.adaptive(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: CustomText(
                      text: 'Error loading users',
                      fontSize: 16.sp,
                      color: Colors.black,
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: CustomText(
                      text: 'No users found',
                      fontSize: 16.sp,
                      color: Colors.black,
                    ),
                  );
                }

                // Get all users
                final List<Map<String, dynamic>> users = snapshot.data!;

                // Filter out current user & apply search
                final filteredUsers = users.where((user) {
                  if (_currentUserEmail != null &&
                      user['email'] == _currentUserEmail) {
                    return false;
                  }
                  if (_searchText.isNotEmpty) {
                    final searchLower = _searchText.toLowerCase();
                    final firstName = user['firstName']?.toLowerCase() ?? '';
                    final lastName = user['lastName']?.toLowerCase() ?? '';
                    final email = user['email']?.toLowerCase() ?? '';
                    return firstName.contains(searchLower) ||
                        lastName.contains(searchLower) ||
                        email.contains(searchLower);
                  }
                  return true;
                }).toList();

                if (filteredUsers.isEmpty) {
                  return Center(
                    child: CustomText(
                      text: 'No users found matching "$_searchText"',
                      fontSize: 16.sp,
                      color: Colors.black,
                    ),
                  );
                }

                // Display user list
                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];

                    // Compute initials
                    final firstInitial = (user['firstName'] != null &&
                            user['firstName'].toString().isNotEmpty)
                        ? user['firstName'][0].toString().toUpperCase()
                        : '';
                    final lastInitial = (user['lastName'] != null &&
                            user['lastName'].toString().isNotEmpty)
                        ? user['lastName'][0].toString().toUpperCase()
                        : '';
                    final initials = '$firstInitial$lastInitial';

                    return GestureDetector(
                      onTap: () {
                        if (_currentUserEmail == null ||
                            _currentUserEmail!.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Cannot open chat: user info not available')),
                          );
                          return;
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatDetailScreen(
                              currentUserEmail: _currentUserEmail!,
                              tappedUser: user,
                            ),
                          ),
                        );
                      },
                      child: Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            child: CustomText(
                              text: initials,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          title: CustomText(
                            text:
                                '${user['firstName'] ?? 'Unknown'} ${user['lastName'] ?? ''}',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          subtitle: CustomText(
                            text: user['email'] ?? 'No email',
                            fontSize: 12,
                            fontWeight: FontWeight.w300,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
