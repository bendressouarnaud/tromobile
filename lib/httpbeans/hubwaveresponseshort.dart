class HubWaveResponseShort {
  final String id;
  final String wave_launch_url;
  final int reserve;

  const HubWaveResponseShort({
    required this.id,
    required this.wave_launch_url,
    required this.reserve
  });

  factory HubWaveResponseShort.fromJson(Map<String, dynamic> json) {
    return HubWaveResponseShort(
        id: json['id'],
        wave_launch_url: json['wave_launch_url'],
        reserve: json['reserve']
    );
  }
}