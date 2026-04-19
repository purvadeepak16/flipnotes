import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/chat_service.dart';
import '../../models/chat_model.dart';
import '../../theme/app_theme.dart';
import 'chat_room_screen.dart';

class ChatHomeScreen extends StatefulWidget {
  const ChatHomeScreen({Key? key}) : super(key: key);

  @override
  State<ChatHomeScreen> createState() => _ChatHomeScreenState();
}

class _ChatHomeScreenState extends State<ChatHomeScreen> {
  final ChatService _chatService = ChatService();
  final Map<String, bool> _joiningGroups = {};
  
  void _showCreateGroupDialog(BuildContext context, String currentUserId) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    bool isCreating = false;

    showDialog(
      context: context,
      barrierDismissible: !isCreating,
      builder: (context) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.card,
            title: const Text('Create New Group',
                style: TextStyle(
                    color: AppColors.darkText, fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  enabled: !isCreating,
                  decoration: const InputDecoration(labelText: 'Group Name'),
                ),
                TextField(
                  controller: descController,
                  enabled: !isCreating,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isCreating ? null : () => Navigator.pop(context),
                child: const Text('Cancel',
                    style: TextStyle(color: AppColors.mutedText)),
              ),
              ElevatedButton(
                onPressed: isCreating
                    ? null
                    : () async {
                        final name = nameController.text.trim();
                        if (name.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Please enter a group name')),
                          );
                          return;
                        }

                        setDialogState(() => isCreating = true);

                        try {
                          await _chatService.createGroup(
                            name,
                            descController.text.trim(),
                            currentUserId,
                          );
                          if (context.mounted) Navigator.pop(context);
                        } catch (e) {
                          setDialogState(() => isCreating = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Failed to create group: $e')),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary),
                child: isCreating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Create',
                        style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.firebaseUser;
    final topPadding = MediaQuery.of(context).padding.top;

    if (user == null) {
      return const Center(child: Text("Not Authenticated"));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateGroupDialog(context, user.uid),
        backgroundColor: AppColors.chatsPink,
        elevation: 2,
        child: const Icon(Icons.add, color: Colors.white, size: 24),
      ),
      body: Column(
        children: [
          // Hero Banner
          Stack(
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(20, topPadding + 20, 20, 48),
                decoration: const BoxDecoration(
                  color: AppColors.chatsPink,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'COMMUNITY',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Chat with friends',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Share notes and study together',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Decorative Circle
              Positioned(
                top: -20,
                right: -40,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.09),
                      width: 30,
                    ),
                  ),
                ),
              ),
            ],
          ),

          Expanded(
            child: StreamBuilder<List<ChatGroup>>(
              stream: _chatService.getGroupsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.chatsPink));
                }

                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading groups'));
                }

                final groups = snapshot.data ?? [];

                if (groups.isEmpty) {
                  return Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: const Text(
                        'No groups available. Create one to get started!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.mutedText, fontSize: 13),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    final group = groups[index];
                    final isMember = group.memberIds.contains(user.uid);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.chatsPink.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(child: Text('💬', style: TextStyle(fontSize: 20))),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  group.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                Text(
                                  group.description,
                                  style: const TextStyle(color: AppColors.mutedText, fontSize: 11),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (isMember)
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatRoomScreen(group: group),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.chatsPink,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                minimumSize: const Size(0, 32),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Open', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            )
                          else
                            OutlinedButton(
                              onPressed: _joiningGroups[group.id] == true
                                  ? null
                                  : () async {
                                      setState(() {
                                        _joiningGroups[group.id] = true;
                                      });
                                      try {
                                        await _chatService.joinGroup(group.id, user.uid);
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Failed to join group: $e')),
                                          );
                                        }
                                      } finally {
                                        if (mounted) {
                                          setState(() {
                                            _joiningGroups[group.id] = false;
                                          });
                                        }
                                      }
                                    },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.chatsPink),
                                foregroundColor: AppColors.chatsPink,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                minimumSize: const Size(0, 32),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: _joiningGroups[group.id] == true
                                  ? const SizedBox(
                                      height: 12,
                                      width: 12,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: AppColors.chatsPink))
                                  : const Text('Join', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                        ],
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
