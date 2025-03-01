class DeviceInfo {
  final String uniqueId;
  final String baseOs;
  final String deviceName;
  final String deviceModel;
  final String manufacturer;
  final String firstInstallTime;

  DeviceInfo({
    required this.uniqueId,
    required this.baseOs,
    required this.deviceName,
    required this.deviceModel,
    required this.manufacturer,
    required this.firstInstallTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'uniqueId': uniqueId,
      'baseOs': baseOs,
      'deviceName': deviceName,
      'deviceModel': deviceModel,
      'manufacturer': manufacturer,
      'firstInstallTime': firstInstallTime,
    };
  }

  factory DeviceInfo.fromJson(Map<String, dynamic> json) {
    return DeviceInfo(
      uniqueId: json['uniqueId'],
      baseOs: json['baseOs'],
      deviceName: json['deviceName'],
      deviceModel: json['deviceModel'],
      manufacturer: json['manufacturer'],
      firstInstallTime: json['firstInstallTime'],
    );
  }
}
