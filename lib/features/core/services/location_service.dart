import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  //Ham de lay vi tri hien tai cua nguoi dung
  Future<Position?> getCurrentPosition() async {
    //1. Kiem tra quyen
    final status = await Permission.location.request();
    if (status.isGranted) {
      //2. neu da co quyen, lay vi tri
      try {
        return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
      } catch (e) {
        print("Lỗi khi lấy vị trí: $e");
        return null;
      }
    }else if(status.isDenied || status.isPermanentlyDenied){
      // 3. Nếu người dùng từ chối, có thể mở cài đặt
      print("Người dùng đã từ chối quyền truy cập vị trí.");
      // (Tùy chọn) Mở cài đặt ứng dụng để người dùng có thể cấp quyền thủ công
      // openAppSettings();
      return null;
    }
    return null;
  }
}
