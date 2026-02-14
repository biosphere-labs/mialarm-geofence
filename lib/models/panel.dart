import 'package:cloud_firestore/cloud_firestore.dart';

class Partition {
  final int id;
  final String name;
  final String state; // "armed" | "disarmed" | "home_arm" | "sleep_arm"
  final bool autoArmOnLeave;
  final bool autoDisarmOnArrive;

  const Partition({
    required this.id,
    required this.name,
    this.state = 'disarmed',
    this.autoArmOnLeave = false,
    this.autoDisarmOnArrive = false,
  });

  bool get isArmed => state != 'disarmed';

  String get displayState => switch (state) {
        'armed' => 'Armed',
        'disarmed' => 'Disarmed',
        'home_arm' => 'Home',
        'sleep_arm' => 'Sleep',
        _ => state,
      };

  factory Partition.fromMap(Map<String, dynamic> map) {
    return Partition(
      id: map['id'] as int,
      name: map['name'] as String? ?? 'Partition',
      state: map['state'] as String? ?? 'disarmed',
      autoArmOnLeave: map['autoArmOnLeave'] as bool? ?? false,
      autoDisarmOnArrive: map['autoDisarmOnArrive'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'state': state,
        'autoArmOnLeave': autoArmOnLeave,
        'autoDisarmOnArrive': autoDisarmOnArrive,
      };

  Partition copyWith({
    int? id,
    String? name,
    String? state,
    bool? autoArmOnLeave,
    bool? autoDisarmOnArrive,
  }) {
    return Partition(
      id: id ?? this.id,
      name: name ?? this.name,
      state: state ?? this.state,
      autoArmOnLeave: autoArmOnLeave ?? this.autoArmOnLeave,
      autoDisarmOnArrive: autoDisarmOnArrive ?? this.autoDisarmOnArrive,
    );
  }
}

class Zone {
  final int id;
  final String name;
  final String type; // "entry_exit" | "instant" | "24hr" | "fire"
  final int partitionId;
  final String state; // "closed" | "open" | "bypassed" | "tamper"

  const Zone({
    required this.id,
    required this.name,
    this.type = 'instant',
    required this.partitionId,
    this.state = 'closed',
  });

  bool get isOpen => state == 'open';
  bool get isBypassed => state == 'bypassed';

  String get displayType => switch (type) {
        'entry_exit' => 'Entry/Exit',
        'instant' => 'Instant',
        '24hr' => '24 Hour',
        'fire' => 'Fire',
        _ => type,
      };

  factory Zone.fromMap(Map<String, dynamic> map) {
    return Zone(
      id: map['id'] as int,
      name: map['name'] as String? ?? 'Zone',
      type: map['type'] as String? ?? 'instant',
      partitionId: map['partitionId'] as int? ?? 1,
      state: map['state'] as String? ?? 'closed',
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'type': type,
        'partitionId': partitionId,
        'state': state,
      };

  Zone copyWith({String? state}) {
    return Zone(
      id: id,
      name: name,
      type: type,
      partitionId: partitionId,
      state: state ?? this.state,
    );
  }
}

class Output {
  final int id;
  final String name;
  final String type; // "momentary" | "toggle"
  final String state; // "on" | "off"

  const Output({
    required this.id,
    required this.name,
    this.type = 'toggle',
    this.state = 'off',
  });

  bool get isOn => state == 'on';
  bool get isMomentary => type == 'momentary';

  factory Output.fromMap(Map<String, dynamic> map) {
    return Output(
      id: map['id'] as int,
      name: map['name'] as String? ?? 'Output',
      type: map['type'] as String? ?? 'toggle',
      state: map['state'] as String? ?? 'off',
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'type': type,
        'state': state,
      };

  Output copyWith({String? state}) {
    return Output(
      id: id,
      name: name,
      type: type,
      state: state ?? this.state,
    );
  }
}

class Panel {
  final String id;
  final String siteId;
  final String name;
  final String model;
  final bool connected;
  final List<Partition> partitions;
  final List<Zone> zones;
  final List<Output> outputs;

  const Panel({
    required this.id,
    required this.siteId,
    required this.name,
    this.model = 'mi64',
    this.connected = true,
    this.partitions = const [],
    this.zones = const [],
    this.outputs = const [],
  });

  factory Panel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Panel(
      id: doc.id,
      siteId: data['siteId'] as String? ?? '',
      name: data['name'] as String? ?? 'Panel',
      model: data['model'] as String? ?? 'mi64',
      connected: data['connected'] as bool? ?? true,
      partitions: (data['partitions'] as List<dynamic>?)
              ?.map((p) => Partition.fromMap(p as Map<String, dynamic>))
              .toList() ??
          [],
      zones: (data['zones'] as List<dynamic>?)
              ?.map((z) => Zone.fromMap(z as Map<String, dynamic>))
              .toList() ??
          [],
      outputs: (data['outputs'] as List<dynamic>?)
              ?.map((o) => Output.fromMap(o as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() => {
        'siteId': siteId,
        'name': name,
        'model': model,
        'connected': connected,
        'partitions': partitions.map((p) => p.toMap()).toList(),
        'zones': zones.map((z) => z.toMap()).toList(),
        'outputs': outputs.map((o) => o.toMap()).toList(),
      };
}
