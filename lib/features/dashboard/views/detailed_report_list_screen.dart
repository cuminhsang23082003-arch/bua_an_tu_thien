import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DetailedReportListScreen extends StatelessWidget {
  final String title;
  final Stream<List<Widget>> itemsStream;

  const DetailedReportListScreen({
    Key? key,
    required this.title,
    required this.itemsStream,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: StreamBuilder<List<Widget>>(
        stream: itemsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Lỗi tải dữ liệu chi tiết.'));
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(
              child: Text('Không có dữ liệu trong khoảng thời gian này.'),
            );
          }
          return ListView.separated(
            itemBuilder: (context, index) => items[index],
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemCount: items.length,
          );
        },
      ),
    );
  }
}
