class TelemetryData {
  final double cpu;
  final double ram;
  final GpuData gpu;
  final NetworkData network;
  final DiskData disk;
  final double temp;
  final double fanSpeed;
  final String topRamApp;
  final String topCpuApp;

  TelemetryData({
    this.cpu = 0.0,
    this.ram = 0.0,
    GpuData? gpu,
    NetworkData? network,
    DiskData? disk,
    this.temp = 0.0,
    this.fanSpeed = 0.0,
    this.topRamApp = "N/A",
    this.topCpuApp = "N/A",
  })  : gpu = gpu ?? GpuData(),
        network = network ?? NetworkData(),
        disk = disk ?? DiskData();

  factory TelemetryData.fromJson(Map<String, dynamic> json) {
    return TelemetryData(
      cpu: (json['cpu'] ?? 0.0).toDouble(),
      ram: (json['ram'] ?? 0.0).toDouble(),
      gpu: GpuData.fromJson(json['gpu'] ?? {}),
      network: NetworkData.fromJson(json['network'] ?? {}),
      disk: DiskData.fromJson(json['disk'] ?? {}),
      temp: (json['temp'] ?? 0.0).toDouble(),
      fanSpeed: (json['fanSpeed'] ?? 0.0).toDouble(),
      topRamApp: json['topRamApp'] ?? "N/A",
      topCpuApp: json['topCpuApp'] ?? "N/A",
    );
  }
}

class GpuData {
  final double load;
  final double memory;
  final double temp;

  GpuData({
    this.load = 0.0,
    this.memory = 0.0,
    this.temp = 0.0,
  });

  factory GpuData.fromJson(Map<String, dynamic> json) {
    return GpuData(
      load: (json['load'] ?? 0.0).toDouble(),
      memory: (json['memory'] ?? 0.0).toDouble(),
      temp: (json['temp'] ?? 0.0).toDouble(),
    );
  }
}

class NetworkData {
  final double down;
  final double up;

  NetworkData({
    this.down = 0.0,
    this.up = 0.0,
  });

  factory NetworkData.fromJson(Map<String, dynamic> json) {
    return NetworkData(
      down: (json['down'] ?? 0.0).toDouble(),
      up: (json['up'] ?? 0.0).toDouble(),
    );
  }
}

class DiskData {
  final double usage;
  final double read;
  final double write;

  DiskData({
    this.usage = 0.0,
    this.read = 0.0,
    this.write = 0.0,
  });

  factory DiskData.fromJson(Map<String, dynamic> json) {
    return DiskData(
      usage: (json['usage'] ?? 0.0).toDouble(),
      read: (json['read'] ?? 0.0).toDouble(),
      write: (json['write'] ?? 0.0).toDouble(),
    );
  }
}
