

  import 'package:hive/hive.dart';

class RaceResultFields {
  static const int season = 0;
  static const int round = 1;
  static const int grandPrixName = 2;
  static const int sessionName = 3;
  static const int driverCode = 4;
  static const int driverName = 5;
  static const int teamName = 6;
  static const int position = 7;
  static const int points = 8;
  static const int status = 9;
  static const int fastestLap = 10;
}


class RaceResult {
  /// Normalized race result row used by both Hive and the repository layer.
  const RaceResult({
    required this.season,
    required this.round,
    required this.grandPrixName,
    required this.sessionName,
    required this.driverCode,
    required this.driverName,
    required this.teamName,
    required this.position,
    required this.points,
    required this.status,
    required this.fastestLap,
  });

  final int season;
  final int round;
  final String grandPrixName;
  final String sessionName;
  final String driverCode;
  final String driverName;
  final String teamName;
  final int position;
  final double points;
  final String status;
  final bool fastestLap;

  factory RaceResult.fromJson(Map<String, dynamic> json) {
    return RaceResult(
      season: json['season'] as int? ?? 0,
      round: json['round'] as int? ?? 0,
      grandPrixName: json['grandPrixName'] as String? ?? '',
      sessionName: json['sessionName'] as String? ?? 'Race',
      driverCode: json['driverCode'] as String? ?? '',
      driverName: json['driverName'] as String? ?? '',
      teamName: json['teamName'] as String? ?? '',
      position: json['position'] as int? ?? 0,
      points: (json['points'] is int)
          ? (json['points'] as int).toDouble()
          : (json['points'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? '',
      fastestLap: json['fastest_lap'] as bool? ?? false,
    );
  }

  factory RaceResult.fromErgastJson(
    Map<String, dynamic> json, {
    required int season,
    required int round,
    required String grandPrixName,
    String sessionName = 'Race',
  }) {
    final driver = json['Driver'] as Map<String, dynamic>? ?? const {};
    final constructor =
        json['Constructor'] as Map<String, dynamic>? ?? const {};
    final fastestLapNode =
        json['FastestLap'] as Map<String, dynamic>? ?? const {};
    final positionText = (json['position'] ?? json['positionText'] ?? '0')
        .toString();

    return RaceResult(
      season: season,
      round: round,
      grandPrixName: grandPrixName,
      sessionName: sessionName,
      driverCode: (driver['code'] ?? '').toString(),
      driverName:
          '${(driver['givenName'] ?? '').toString()} ${(driver['familyName'] ?? '').toString()}'
              .trim(),
      teamName: (constructor['name'] ?? '').toString(),
      position: int.tryParse(positionText) ?? 0,
      points: double.tryParse((json['points'] ?? '0').toString()) ?? 0,
      status: (json['status'] ?? '').toString(),
      fastestLap: fastestLapNode.isNotEmpty,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'season': season,
      'round': round,
      'grandPrixName': grandPrixName,
      'sessionName': sessionName,
      'driverCode': driverCode,
      'driverName': driverName,
      'teamName': teamName,
      'position': position,
      'points': points,
      'status': status,
      'fastest_lap': fastestLap,
    };
  }
}

class RaceResultAdapter extends TypeAdapter<RaceResult> {
  @override
  final int typeId = 0;

  @override
  RaceResult read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < fieldCount; i++) reader.readByte(): reader.read(),
    };

    return RaceResult(
      season: fields[RaceResultFields.season] as int,
      round: fields[RaceResultFields.round] as int,
      grandPrixName: fields[RaceResultFields.grandPrixName] as String,
      sessionName: fields[RaceResultFields.sessionName] as String,
      driverCode: fields[RaceResultFields.driverCode] as String,
      driverName: fields[RaceResultFields.driverName] as String,
      teamName: fields[RaceResultFields.teamName] as String,
      position: fields[RaceResultFields.position] as int,
      points: fields[RaceResultFields.points] as double,
      status: fields[RaceResultFields.status] as String,
      fastestLap: fields[RaceResultFields.fastestLap] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, RaceResult obj) {
    writer
      ..writeByte(11)
      ..writeByte(RaceResultFields.season)
      ..write(obj.season)
      ..writeByte(RaceResultFields.round)
      ..write(obj.round)
      ..writeByte(RaceResultFields.grandPrixName)
      ..write(obj.grandPrixName)
      ..writeByte(RaceResultFields.sessionName)
      ..write(obj.sessionName)
      ..writeByte(RaceResultFields.driverCode)
      ..write(obj.driverCode)
      ..writeByte(RaceResultFields.driverName)
      ..write(obj.driverName)
      ..writeByte(RaceResultFields.teamName)
      ..write(obj.teamName)
      ..writeByte(RaceResultFields.position)
      ..write(obj.position)
      ..writeByte(RaceResultFields.points)
      ..write(obj.points)
      ..writeByte(RaceResultFields.status)
      ..write(obj.status)
      ..writeByte(RaceResultFields.fastestLap)
      ..write(obj.fastestLap);
  }
}
