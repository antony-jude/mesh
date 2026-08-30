import 'package:permission_handler/permission_handler.dart';

class MeshPermissionService {
  static Future<bool> requestMeshPermissions() async {
    final permissions = <Permission>[];

    if (await Permission.bluetoothScan.isDenied || await Permission.bluetoothScan.isRestricted) {
      permissions.add(Permission.bluetoothScan);
    }
    if (await Permission.bluetoothAdvertise.isDenied || await Permission.bluetoothAdvertise.isRestricted) {
      permissions.add(Permission.bluetoothAdvertise);
    }
    if (await Permission.bluetoothConnect.isDenied || await Permission.bluetoothConnect.isRestricted) {
      permissions.add(Permission.bluetoothConnect);
    }

    if (await Permission.nearbyWifiDevices.isDenied || await Permission.nearbyWifiDevices.isRestricted) {
      permissions.add(Permission.nearbyWifiDevices);
    }

    if (await Permission.location.isDenied || await Permission.location.isRestricted) {
      permissions.add(Permission.location);
    }

    if (permissions.isEmpty) {
      return true;
    }

    final statuses = await permissions.request();
    final granted = statuses.values.every((status) =>
        status == PermissionStatus.granted ||
        status == PermissionStatus.limited ||
        status == PermissionStatus.provisional);

    return granted;
  }
}
