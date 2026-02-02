import 'package:buaanyeuthuong/features/authentication/viewmodels/auth_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class WaitingApprovalScreen extends StatelessWidget {
  const WaitingApprovalScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(24),
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              colors: [Colors.orange, Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.verified_user_outlined, size: 80, color: Colors.orange),
            const SizedBox(height: 24),
            const Text(''
                'Hồ sơ quán ăn đang chờ duyệt',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
              ,
            ),
            const SizedBox(height: 16),
            const Text(
              'Cảm ơn bạn đã đăng ký trở thành đối tác của Bữa Ăn Yêu Thương.\n\n'
                  'Admin sẽ kiểm tra thông tin quán ăn của bạn để đảm bảo tính minh bạch và an toàn cho cộng đồng.\n\n'
                  'Vui lòng quay lại sau khi hồ sơ được duyệt.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
                onPressed: (){
                  context.read<AuthViewModel>().signOut();
                },
              icon: const Icon(Icons.logout),
                label: const Text('Đăng xuất'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.orange,
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
                onPressed: (){}, child: const Text("Kiểm tra lại trạng thái")
            )
          ],
        ),
      ),
    );
  }
}