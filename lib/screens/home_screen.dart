import 'package:flutter/material.dart';
import 'package:notification_fcm_token/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('หน้าแรก'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthProvider>().signOut();
              // ignore: use_build_context_synchronously
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (authProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = authProvider.user;
          if (user == null) {
            return const Center(child: Text('ไม่พบข้อมูลผู้ใช้'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: user.photoUrl != null
                            ? NetworkImage(user.photoUrl!)
                            : null,
                        child: user.photoUrl == null
                            ? const Icon(Icons.person, size: 50)
                            : null,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'สวัสดี ${user.username}!',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                _buildInfoCard('ข้อมูลผู้ใช้', [
                  _buildInfoRow('ID', user.id.toString()),
                  _buildInfoRow('UUID', user.uuid),
                  _buildInfoRow('Email', user.email),
                  _buildInfoRow('Username', user.username),
                  _buildInfoRow('Phone', user.phoneNumber ?? 'ไม่ระบุ'),
                  _buildInfoRow('Bio', user.bio ?? 'ไม่มี'),
                ]),
                const SizedBox(height: 20),
                _buildInfoCard('ข้อมูลการตรวจสอบตัวตน', [
                  _buildInfoRow('Firebase UID', user.firebaseUid ?? 'ไม่มี'),
                  _buildInfoRow('Auth Provider', user.authProvider),
                  _buildInfoRow(
                    'Email Verified',
                    user.isEmailVerified ? 'ใช่' : 'ไม่',
                  ),
                  _buildInfoRow(
                    'Last Login',
                    user.lastLogin?.toString() ?? 'ไม่มี',
                  ),
                ]),
                const SizedBox(height: 20),
                _buildInfoCard('ข้อมูลระบบ', [
                  _buildInfoRow(
                    'สถานะ',
                    user.isActive ? 'ใช้งาน' : 'ไม่ใช้งาน',
                  ),
                  _buildInfoRow('สร้างเมื่อ', user.createdAt.toString()),
                  _buildInfoRow('อัปเดตล่าสุด', user.updatedAt.toString()),
                ]),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}
