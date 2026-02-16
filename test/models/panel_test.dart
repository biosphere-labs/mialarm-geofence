import 'package:flutter_test/flutter_test.dart';
import 'package:mialarm_geofence/models/panel.dart';

void main() {
  group('Partition', () {
    test('creates with defaults', () {
      const p = Partition(id: 1, name: 'House');
      expect(p.state, 'disarmed');
      expect(p.autoArmOnLeave, false);
      expect(p.autoDisarmOnArrive, false);
    });

    test('isArmed returns true for armed states', () {
      expect(const Partition(id: 1, name: 'P', state: 'armed').isArmed, true);
      expect(
          const Partition(id: 1, name: 'P', state: 'home_arm').isArmed, true);
      expect(
          const Partition(id: 1, name: 'P', state: 'sleep_arm').isArmed, true);
    });

    test('isArmed returns false for disarmed', () {
      expect(const Partition(id: 1, name: 'P', state: 'disarmed').isArmed,
          false);
    });

    test('displayState maps correctly', () {
      expect(const Partition(id: 1, name: 'P', state: 'armed').displayState,
          'Armed');
      expect(
          const Partition(id: 1, name: 'P', state: 'disarmed').displayState,
          'Disarmed');
      expect(
          const Partition(id: 1, name: 'P', state: 'home_arm').displayState,
          'Home');
      expect(
          const Partition(id: 1, name: 'P', state: 'sleep_arm').displayState,
          'Sleep');
      expect(const Partition(id: 1, name: 'P', state: 'unknown').displayState,
          'unknown');
    });

    test('fromMap with all fields', () {
      final p = Partition.fromMap({
        'id': 1,
        'name': 'House',
        'state': 'armed',
        'autoArmOnLeave': true,
        'autoDisarmOnArrive': true,
      });
      expect(p.id, 1);
      expect(p.name, 'House');
      expect(p.state, 'armed');
      expect(p.autoArmOnLeave, true);
      expect(p.autoDisarmOnArrive, true);
    });

    test('fromMap with missing optional fields', () {
      final p = Partition.fromMap({'id': 1});
      expect(p.name, 'Partition');
      expect(p.state, 'disarmed');
      expect(p.autoArmOnLeave, false);
      expect(p.autoDisarmOnArrive, false);
    });

    test('toMap roundtrips', () {
      const original = Partition(
        id: 2,
        name: 'Perimeter',
        state: 'armed',
        autoArmOnLeave: true,
        autoDisarmOnArrive: false,
      );
      final restored = Partition.fromMap(original.toMap());
      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.state, original.state);
      expect(restored.autoArmOnLeave, original.autoArmOnLeave);
      expect(restored.autoDisarmOnArrive, original.autoDisarmOnArrive);
    });

    test('copyWith overrides specific fields', () {
      const p = Partition(id: 1, name: 'House', state: 'disarmed');
      final armed = p.copyWith(state: 'armed');
      expect(armed.state, 'armed');
      expect(armed.id, 1);
      expect(armed.name, 'House');
    });
  });

  group('Zone', () {
    test('creates with defaults', () {
      const z = Zone(id: 1, name: 'Front Door', partitionId: 1);
      expect(z.type, 'instant');
      expect(z.state, 'closed');
    });

    test('isOpen and isBypassed', () {
      expect(
          const Zone(id: 1, name: 'Z', partitionId: 1, state: 'open').isOpen,
          true);
      expect(
          const Zone(id: 1, name: 'Z', partitionId: 1, state: 'closed').isOpen,
          false);
      expect(
          const Zone(id: 1, name: 'Z', partitionId: 1, state: 'bypassed')
              .isBypassed,
          true);
      expect(
          const Zone(id: 1, name: 'Z', partitionId: 1, state: 'closed')
              .isBypassed,
          false);
    });

    test('displayType maps correctly', () {
      expect(
          const Zone(id: 1, name: 'Z', partitionId: 1, type: 'entry_exit')
              .displayType,
          'Entry/Exit');
      expect(
          const Zone(id: 1, name: 'Z', partitionId: 1, type: 'instant')
              .displayType,
          'Instant');
      expect(
          const Zone(id: 1, name: 'Z', partitionId: 1, type: '24hr')
              .displayType,
          '24 Hour');
      expect(
          const Zone(id: 1, name: 'Z', partitionId: 1, type: 'fire')
              .displayType,
          'Fire');
    });

    test('fromMap with missing optional fields', () {
      final z = Zone.fromMap({'id': 1});
      expect(z.name, 'Zone');
      expect(z.type, 'instant');
      expect(z.partitionId, 1);
      expect(z.state, 'closed');
    });

    test('toMap roundtrips', () {
      const original = Zone(
        id: 5,
        name: 'Gate Beam',
        type: 'entry_exit',
        partitionId: 2,
        state: 'open',
      );
      final restored = Zone.fromMap(original.toMap());
      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.type, original.type);
      expect(restored.partitionId, original.partitionId);
      expect(restored.state, original.state);
    });

    test('copyWith overrides state', () {
      const z = Zone(id: 1, name: 'Door', partitionId: 1, state: 'closed');
      final bypassed = z.copyWith(state: 'bypassed');
      expect(bypassed.state, 'bypassed');
      expect(bypassed.name, 'Door');
    });
  });

  group('Output', () {
    test('creates with defaults', () {
      const o = Output(id: 1, name: 'Gate');
      expect(o.type, 'toggle');
      expect(o.state, 'off');
    });

    test('isOn and isMomentary', () {
      expect(const Output(id: 1, name: 'O', state: 'on').isOn, true);
      expect(const Output(id: 1, name: 'O', state: 'off').isOn, false);
      expect(
          const Output(id: 1, name: 'O', type: 'momentary').isMomentary, true);
      expect(
          const Output(id: 1, name: 'O', type: 'toggle').isMomentary, false);
    });

    test('fromMap with missing optional fields', () {
      final o = Output.fromMap({'id': 1});
      expect(o.name, 'Output');
      expect(o.type, 'toggle');
      expect(o.state, 'off');
    });

    test('toMap roundtrips', () {
      const original = Output(
        id: 3,
        name: 'Garden Lights',
        type: 'toggle',
        state: 'on',
      );
      final restored = Output.fromMap(original.toMap());
      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.type, original.type);
      expect(restored.state, original.state);
    });

    test('copyWith overrides state', () {
      const o = Output(id: 1, name: 'Gate', state: 'off');
      final on = o.copyWith(state: 'on');
      expect(on.state, 'on');
      expect(on.name, 'Gate');
    });
  });

  group('Panel', () {
    test('creates with defaults', () {
      const panel = Panel(id: 'p1', siteId: 's1', name: 'Main');
      expect(panel.model, 'mi64');
      expect(panel.connected, true);
      expect(panel.partitions, isEmpty);
      expect(panel.zones, isEmpty);
      expect(panel.outputs, isEmpty);
    });

    test('toMap includes nested collections', () {
      const panel = Panel(
        id: 'p1',
        siteId: 's1',
        name: 'Main',
        partitions: [Partition(id: 1, name: 'House')],
        zones: [Zone(id: 1, name: 'Door', partitionId: 1)],
        outputs: [Output(id: 1, name: 'Gate')],
      );
      final map = panel.toMap();

      expect((map['partitions'] as List).length, 1);
      expect((map['zones'] as List).length, 1);
      expect((map['outputs'] as List).length, 1);
      expect(map['siteId'], 's1');
      expect(map.containsKey('id'), false); // doc ID not in map
    });
  });
}
