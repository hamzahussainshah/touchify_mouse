class DeviceModel {
  final String id;
  final String name;
  final String ipAddress;
  final int port;
  final String os; // 'macOS', 'Windows'
  final int signalStrength; // 1-4

  const DeviceModel({
    required this.id,
    required this.name,
    required this.ipAddress,
    required this.port,
    required this.os,
    this.signalStrength = 4,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown Device',
      ipAddress: json['ipAddress']?.toString() ?? json['ip']?.toString() ?? '',
      port: json['port'] is int ? json['port'] : int.tryParse(json['port']?.toString() ?? '') ?? 35901,
      os: json['os']?.toString() ?? 'unknown',
      signalStrength: json['signalStrength'] as int? ?? 4,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'ipAddress': ipAddress,
      'port': port,
      'os': os,
      'signalStrength': signalStrength,
    };
  }
}
