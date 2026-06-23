/// Script to generate event_seed_data.dart with exactly 100 events.
/// Run with: dart run tool/generate_seed.dart
library;

import 'dart:io';

void main() {
  const baseYear = 2026;
  const baseMonth = 5;
  const baseDay = 20;

  // Coordinates
  const etna = 'etnaLat, etnaLon';
  const ves = 'vesLat, vesLon';
  const strom = 'stromLat, stromLon';
  const rome = 'romeLat, romeLon';
  const centIt = 'centItLat, centItLon';
  const north = 'northLat, northLon';
  const ischia = '41.1350, 14.6771';

  final sb = StringBuffer();

  sb.writeln('''/// Deterministic seed data for development/demo testing.
///
/// All events use IDs in the range 900000-900099 so they can be
/// safely deleted without affecting user-created data.
///
/// ~100 events across 6 categories, covering timeline/map/filter/search edge cases.
library;

import 'package:ingv_app/data/models/event_model.dart';

/// Compact row representation for seed event data.
class _SeedRow {
  final int idOffset;
  final String category;
  final int startDays;
  final int startHours;
  final int startMinutes;
  final int? endDays;
  final int? endHours;
  final int? endMinutes;
  final double lat;
  final double lon;
  final String title;
  final String tag;
  final String description;
  final String? groupId;

  const _SeedRow({
    required this.idOffset,
    required this.category,
    required this.startDays,
    this.startHours = 0,
    this.startMinutes = 0,
    required this.endDays,
    this.endHours,
    this.endMinutes,
    required this.lat,
    required this.lon,
    required this.title,
    required this.tag,
    required this.description,
    this.groupId,
  });

  DateTime _offset(int days, int hours, int minutes) =>
      DateTime(2026, 5, 20).add(Duration(days: days, hours: hours, minutes: minutes));

  EventModel toEvent() => EventModel(
        eventId: 900000 + idOffset,
        category: category,
        startDt: _offset(startDays, startHours, startMinutes),
        endDt: endDays != null ? _offset(endDays!, endHours!, endMinutes!) : null,
        author: 'DemoSeed',
        lat: lat,
        long: lon,
        title: title,
        tag: tag,
        description: description,
        groupId: groupId,
      );
}

/// Deterministic list of exactly 100 demo events.
List<EventModel> generateDemoEvents() {
  // Coordinate references
  const double etnaLat = 37.7510;
  const double etnaLon = 14.9934;
  const double vesLat = 40.8216;
  const double vesLon = 14.4282;
  const double stromLat = 38.7895;
  const double stromLon = 15.2132;
  const double romeLat = 41.9028;
  const double romeLon = 12.4964;
  const double centItLat = 42.3516;
  const double centItLon = 13.3985;
  const double northLat = 45.4642;
  const double northLon = 9.1900;

  const List<_SeedRow> rows = [
''');

  // Helper to build a _SeedRow string
  String row({
    required int id,
    required String cat,
    required int sd,
    int sh = 0,
    int sm = 0,
    required int? ed,
    int? eh,
    int? em,
    required String loc,
    required String title,
    required String tag,
    required String desc,
    String? grp,
  }) {
    final coords = loc.split(',').map((s) => s.trim()).toList();
    var s = '    _SeedRow(\n';
    s += '      idOffset: $id,\n';
    s += "      category: '$cat',\n";
    s += '      startDays: $sd';
    if (sh != 0) s += ', startHours: $sh';
    if (sm != 0) s += ', startMinutes: $sm';
    s += ',\n';
    s += '      endDays: ${ed ?? 'null'}';
    if (ed != null) {
      if (eh != null) s += ', endHours: $eh';
      if (em != null) s += ', endMinutes: $em';
    }
    s += ',\n';
    s += '      lat: ${coords[0]}, lon: ${coords[1]},\n';
    s += "      title: '$title',\n";
    s += "      tag: '$tag',\n";
    s += "      description: '$desc',\n";
    if (grp != null) s += "      groupId: '$grp',\n";
    s += '    ),\n';
    return s;
  }

  // VOLCANIC (17 events, offsets 0-16)
  sb.writeln('    // VOLCANIC (offsets 0-16) - 17 events');
  sb.write(
    row(
      id: 0,
      cat: 'Volcanic',
      sd: 0,
      sh: 9,
      ed: 0,
      eh: 18,
      loc: etna,
      title: 'Etna ash plume increase',
      tag: 'ash',
      desc:
          'Significant increase in ash plume height at Mount Etna. Plume rose to 3 km above crater level.',
      grp: 'group_1',
    ),
  );
  sb.write(
    row(
      id: 1,
      cat: 'Volcanic',
      sd: 0,
      sh: 10,
      ed: 0,
      eh: 11,
      loc: etna,
      title: 'Etna Strombolian burst',
      tag: 'crater',
      desc:
          'Short Strombolian burst from East Crater during the larger plume event.',
      grp: 'group_1',
    ),
  );
  sb.write(
    row(
      id: 2,
      cat: 'Volcanic',
      sd: 0,
      sh: 12,
      ed: 0,
      eh: 20,
      loc: etna,
      title: 'Etna lava fountain continuation',
      tag: 'lava',
      desc: 'Lava fountain activity continued alongside the ash plume.',
      grp: 'group_1',
    ),
  );
  sb.write(
    row(
      id: 3,
      cat: 'Volcanic',
      sd: 1,
      sh: 8,
      sm: 30,
      ed: 1,
      eh: 8,
      em: 31,
      loc: ves,
      title: 'Vesuvius tremor',
      tag: 'seismic',
      desc:
          'Single volcanic tremor spike at Vesuvius, approximately 60 seconds duration.',
    ),
  );
  sb.write(
    row(
      id: 4,
      cat: 'Volcanic',
      sd: 2,
      sh: 14,
      ed: 2,
      eh: 14,
      em: 5,
      loc: strom,
      title: 'S',
      tag: 'crater',
      desc:
          'Brief incandescence from Sciara del Fuoco. Standard Stromboli activity.',
      grp: 'group_2',
    ),
  );
  sb.write(
    row(
      id: 5,
      cat: 'Volcanic',
      sd: 3,
      sh: 3,
      ed: 3,
      eh: 3,
      em: 15,
      loc: etna,
      title: 'Etna nighttime incandescence',
      tag: 'lava',
      desc:
          'Brief nighttime incandescence via thermal cameras during early morning.',
      grp: 'group_1',
    ),
  );
  sb.write(
    row(
      id: 6,
      cat: 'Volcanic',
      sd: 4,
      sh: 22,
      ed: 4,
      eh: 22,
      em: 30,
      loc: strom,
      title:
          'Stromboli enhanced crater glow with intermittent spalling of Sciara del Fuoco sector observed during extended monitoring',
      tag: 'crater',
      desc:
          'Enhanced thermal emission from summit crater with intermittent rock falls.',
      grp: 'group_2',
    ),
  );
  sb.write(
    row(
      id: 7,
      cat: 'Volcanic',
      sd: 5,
      ed: 7,
      loc: etna,
      title: 'Etna prolonged emissions',
      tag: 'gas',
      desc: 'Extended period of increased sulfurous emissions at Etna summit.',
      grp: 'group_1',
    ),
  );
  sb.write(
    row(
      id: 8,
      cat: 'Volcanic',
      sd: 10,
      ed: 17,
      loc: strom,
      title: 'Stromboli cycle disruption',
      tag: 'thermal',
      desc:
          'Unusual disruption to normal explosive cycle at Stromboli with long quiescence periods.',
    ),
  );
  sb.write(
    row(
      id: 9,
      cat: 'Volcanic',
      sd: 3,
      sh: 12,
      ed: null,
      loc: etna,
      title: 'Etna crater monitoring ongoing',
      tag: 'ongoing',
      desc:
          'Continuous monitoring initiated. Elevated seismicity and gas flux above baseline.',
      grp: 'group_1',
    ),
  );
  sb.write(
    row(
      id: 10,
      cat: 'Volcanic',
      sd: 6,
      sh: 10,
      ed: 6,
      eh: 16,
      loc: etna,
      title: 'Etna lava flow advance',
      tag: 'lava',
      desc: 'New lava flow from Southeast Crater toward Valle del Bove.',
      grp: 'group_1',
    ),
  );
  sb.write(
    row(
      id: 11,
      cat: 'Volcanic',
      sd: 6,
      sh: 10,
      ed: 6,
      eh: 16,
      loc: ves,
      title: 'Vesuvius degassing spike',
      tag: 'gas',
      desc: 'Degassing spike at Vesuvius concurrent with Etna activity.',
    ),
  );
  sb.write(
    row(
      id: 12,
      cat: 'Volcanic',
      sd: 8,
      sh: 15,
      ed: 8,
      eh: 16,
      loc: strom,
      title: 'Stromboli overpressure burst',
      tag: 'crater',
      desc: 'Overpressure-driven explosive burst lasting one hour.',
      grp: 'group_2',
    ),
  );
  sb.write(
    row(
      id: 13,
      cat: 'Volcanic',
      sd: 9,
      sh: 6,
      ed: 9,
      eh: 12,
      loc: etna,
      title: 'Etna morning degassing',
      tag: 'gas',
      desc: 'Intensified morning degassing period at summit.',
      grp: 'group_1',
    ),
  );
  sb.write(
    row(
      id: 14,
      cat: 'Volcanic',
      sd: 11,
      ed: 12,
      loc: ves,
      title: 'Vesuvius elevated thermal anomaly',
      tag: 'thermal',
      desc:
          'Thermal anomaly on southeast slope monitored via satellite for 24 hours.',
    ),
  );
  sb.write(
    row(
      id: 15,
      cat: 'Volcanic',
      sd: 14,
      sh: 11,
      ed: 14,
      eh: 15,
      loc: etna,
      title: 'Etna plume recurrence',
      tag: 'overlap',
      desc: 'Ash plume activity recurred similar to May 20 event.',
      grp: 'group_1',
    ),
  );
  sb.write(
    row(
      id: 16,
      cat: 'Volcanic',
      sd: -5,
      sh: 8,
      ed: -5,
      eh: 14,
      loc: etna,
      title: 'Etna pre-period activity',
      tag: 'boundary-filter',
      desc: 'Volcanic event before main filter range for boundary testing.',
      grp: 'group_3',
    ),
  );

  // EARTHQUAKE (17 events, offsets 17-33)
  sb.writeln('');
  sb.writeln('    // EARTHQUAKE (offsets 17-33) - 17 events');
  sb.write(
    row(
      id: 17,
      cat: 'Earthquake',
      sd: 0,
      sh: 9,
      ed: 0,
      eh: 18,
      loc: centIt,
      title: 'Central Italy seismic swarm',
      tag: 'seismic',
      desc:
          'Seismic swarm in Central Italy concurrent with Etna activity. 42 events in 9 hours.',
      grp: 'group_2',
    ),
  );
  sb.write(
    row(
      id: 18,
      cat: 'Earthquake',
      sd: 1,
      sh: 14,
      ed: 1,
      eh: 15,
      loc: etna,
      title: 'EQ',
      tag: 'seismic',
      desc: 'Volcano-tectonic earthquake beneath Etna flank.',
      grp: 'group_2',
    ),
  );
  sb.write(
    row(
      id: 19,
      cat: 'Earthquake',
      sd: 1,
      sh: 14,
      sm: 3,
      ed: 1,
      eh: 15,
      em: 3,
      loc: '37.7512, 14.9935',
      title: 'Magnitude 4.2 tremor',
      tag: 'seismic',
      desc: 'M4.2 tremor near Etna at slightly different coordinates.',
      grp: 'group_2',
    ),
  );
  sb.write(
    row(
      id: 20,
      cat: 'Earthquake',
      sd: 2,
      sh: 2,
      sm: 15,
      ed: 2,
      eh: 2,
      em: 16,
      loc: rome,
      title: 'Rome microseismic event',
      tag: 'short-duration',
      desc: 'Isolated microseismic event by Rome station. No damage reported.',
    ),
  );
  sb.write(
    row(
      id: 21,
      cat: 'Earthquake',
      sd: 3,
      sh: 19,
      ed: 3,
      eh: 19,
      em: 5,
      loc: '37.7508, 14.9931',
      title: 'Etna shallow seismicity burst',
      tag: 'cluster-test',
      desc: 'Brief shallow seismicity burst beneath Etna within cluster group.',
      grp: 'group_2',
    ),
  );
  sb.write(
    row(
      id: 22,
      cat: 'Earthquake',
      sd: 4,
      sh: 10,
      ed: 4,
      eh: 11,
      loc: centIt,
      title: 'Lazio-Abruzzo seismic event',
      tag: 'seismic',
      desc: 'Single seismic event with notable coda in Lazio-Abruzzo.',
      grp: 'group_3',
    ),
  );
  sb.write(
    row(
      id: 23,
      cat: 'Earthquake',
      sd: 9,
      sh: 6,
      ed: 9,
      eh: 12,
      loc: centIt,
      title: 'Central Italy extended swarm',
      tag: 'overlap',
      desc: 'Extended seismic swarm same duration as Etna degassing event.',
      grp: 'group_2',
    ),
  );
  sb.write(
    row(
      id: 24,
      cat: 'Earthquake',
      sd: 11,
      sh: 8,
      ed: 12,
      eh: 8,
      loc: rome,
      title: 'Rome area tremor sequence',
      tag: 'seismic',
      desc: 'Continuous tremor sequence in greater Rome area for 24 hours.',
    ),
  );
  sb.write(
    row(
      id: 25,
      cat: 'Earthquake',
      sd: 5,
      ed: 8,
      loc: centIt,
      title: "L'Aquila aftershock sequence",
      tag: 'seismic',
      desc:
          'Aftershock sequence persisting 72 hours with decreasing magnitude trend.',
      grp: 'group_3',
    ),
  );
  sb.write(
    row(
      id: 26,
      cat: 'Earthquake',
      sd: 10,
      sh: 6,
      ed: null,
      loc: rome,
      title: 'Rome seismic monitoring active',
      tag: 'ongoing',
      desc:
          'Continuous seismic monitoring near Rome. Elevated background noise.',
      grp: 'group_3',
    ),
  );
  sb.write(
    row(
      id: 27,
      cat: 'Earthquake',
      sd: 14,
      sh: 9,
      ed: 14,
      eh: 9,
      em: 10,
      loc: etna,
      title: 'Etna volcano-tectonic EQ',
      tag: 'same-location',
      desc: 'VT earthquake at Etna coordinates different day from original.',
      grp: 'group_2',
    ),
  );
  sb.write(
    row(
      id: 28,
      cat: 'Earthquake',
      sd: 13,
      sh: 8,
      ed: 13,
      eh: 14,
      loc: ischia,
      title: 'Ischia seismic unrest',
      tag: 'seismic',
      desc: 'Seismic unrest at Ischia with 6 hours of elevated activity.',
    ),
  );
  sb.write(
    row(
      id: 29,
      cat: 'Earthquake',
      sd: 15,
      sh: 16,
      ed: 15,
      eh: 17,
      loc: etna,
      title: 'Etna flank seismicite',
      tag: 'same-location',
      desc: 'Seismicite on Etna flank at same coords as clustered events.',
      grp: 'group_2',
    ),
  );
  sb.write(
    row(
      id: 30,
      cat: 'Earthquake',
      sd: 16,
      sh: 12,
      ed: 18,
      eh: 12,
      loc: centIt,
      title: 'Marche region seismic crisis',
      tag: 'seismic',
      desc: 'Two-day seismic crisis in Marche with 200+ events across network.',
      grp: 'group_3',
    ),
  );
  sb.write(
    row(
      id: 31,
      cat: 'Earthquake',
      sd: 46,
      sh: 10,
      ed: 46,
      eh: 14,
      loc: centIt,
      title: 'Post-range seismic event',
      tag: 'boundary-filter',
      desc: 'Earthquake after main filter range for boundary testing.',
      grp: 'group_3',
    ),
  );
  sb.write(
    row(
      id: 32,
      cat: 'Earthquake',
      sd: -2,
      sh: 20,
      ed: 1,
      eh: 4,
      loc: centIt,
      title: 'Pre-to-in range earthquake',
      tag: 'boundary-filter',
      desc: 'Starts before filter range but ends inside it.',
    ),
  );
  sb.write(
    row(
      id: 33,
      cat: 'Earthquake',
      sd: 35,
      sh: 18,
      ed: 43,
      eh: 6,
      loc: rome,
      title: 'In-to-post range seismic event',
      tag: 'boundary-filter',
      desc: 'Starts inside filter but extends past June 25.',
      grp: 'group_3',
    ),
  );

  // HYDROLOGICAL (16 events, offsets 34-49)
  sb.writeln('');
  sb.writeln('    // HYDROLOGICAL (offsets 34-49) - 16 events');
  sb.write(
    row(
      id: 34,
      cat: 'Hydrological',
      sd: 0,
      sh: 6,
      ed: 0,
      eh: 14,
      loc: north,
      title: 'Po river overflow warning',
      tag: 'rainfall',
      desc:
          'Po river exceeded warning threshold. Overflow alert for northern Italy.',
      grp: 'group_3',
    ),
  );
  sb.write(
    row(
      id: 35,
      cat: 'Hydrological',
      sd: 1,
      sh: 12,
      ed: 1,
      eh: 12,
      em: 5,
      loc: '45.4655, 9.1885',
      title: 'Rapid level spike',
      tag: 'short-duration',
      desc: 'Rapid water level spike at Milan hydrological station.',
      grp: 'group_3',
    ),
  );
  sb.write(
    row(
      id: 36,
      cat: 'Hydrological',
      sd: 2,
      ed: 5,
      loc: north,
      title: 'Northern Italy sustained hydrological stress',
      tag: 'rainfall',
      desc:
          'Sustained hydrological stress from persistent rainfall in northern Italy.',
      grp: 'group_3',
    ),
  );
  sb.write(
    row(
      id: 37,
      cat: 'Hydrological',
      sd: 0,
      sh: 6,
      ed: 0,
      eh: 14,
      loc: '45.4700, 9.1950',
      title: 'Po delta water level rise',
      tag: 'rainfall',
      desc: 'Water level rise at Po delta concurrent with upstream warning.',
      grp: 'group_3',
    ),
  );
  sb.write(
    row(
      id: 38,
      cat: 'Hydrological',
      sd: 6,
      sh: 8,
      ed: 6,
      eh: 9,
      loc: '45.4720, 9.1870',
      title: 'Turin flash flood alert',
      tag: 'rainfall',
      desc: 'Flash flood alert for Turin metropolitan area.',
    ),
  );
  sb.write(
    row(
      id: 39,
      cat: 'Hydrological',
      sd: 7,
      sh: 20,
      ed: 8,
      eh: 2,
      loc: '45.4630, 9.1920',
      title: 'Milan overflow event',
      tag: 'rainfall',
      desc: 'Significant overflow detected in Milan water management systems.',
    ),
  );
  sb.write(
    row(
      id: 40,
      cat: 'Hydrological',
      sd: 12,
      ed: 13,
      loc: '45.4650, 9.1910',
      title: 'Sesia river flood watch',
      tag: 'rainfall',
      desc: '24-hour flood watch on Sesia river due to alpine meltwater.',
    ),
  );
  sb.write(
    row(
      id: 41,
      cat: 'Hydrological',
      sd: 10,
      sh: 6,
      ed: null,
      loc: '45.4660, 9.1890',
      title: 'Adige monitoring ongoing',
      tag: 'ongoing',
      desc: 'Continuous hydrological monitoring on Adige river initiated.',
      grp: 'group_3',
    ),
  );
  sb.write(
    row(
      id: 42,
      cat: 'Hydrological',
      sd: -5,
      sh: 18,
      ed: 1,
      eh: 12,
      loc: north,
      title: 'Pre-range Alpine hydro event',
      tag: 'boundary-filter',
      desc: 'Starts before filter range ends inside it.',
      grp: 'group_3',
    ),
  );
  sb.write(
    row(
      id: 43,
      cat: 'Hydrological',
      sd: 35,
      sh: 6,
      ed: 40,
      eh: 6,
      loc: '45.4640, 9.1930',
      title: 'Post-range Po monitoring',
      tag: 'boundary-filter',
      desc: 'Starts inside filter range ends after it.',
    ),
  );
  sb.write(
    row(
      id: 44,
      cat: 'Hydrological',
      sd: -1,
      ed: 41,
      loc: north,
      title: 'Full-filter-range hydro monitoring',
      tag: 'boundary-filter',
      desc: 'Fully surrounds the entire filter range May 20 to June 25.',
      grp: 'group_3',
    ),
  );
  sb.write(
    row(
      id: 45,
      cat: 'Hydrological',
      sd: 38,
      ed: 42,
      loc: '45.4645, 9.1880',
      title: 'Outside-filter hydro event',
      tag: 'boundary-filter',
      desc: 'Completely outside the main filter range for testing exclusion.',
    ),
  );
  sb.write(
    row(
      id: 46,
      cat: 'Hydrological',
      sd: 3,
      ed: 3,
      eh: 4,
      loc: '45.4700, 9.1880',
      title: 'Brescian flooding',
      tag: 'rainfall',
      desc: 'Localized flooding in Brescia due to intense rainfall.',
    ),
  );
  sb.write(
    row(
      id: 47,
      cat: 'Hydrological',
      sd: 18,
      sh: 10,
      ed: 18,
      eh: 14,
      loc: '45.4630, 9.1920',
      title: 'Flood risk rise',
      tag: 'rainfall',
      desc: 'Elevated flood risk level on Brembo River.',
    ),
  );
  sb.write(
    row(
      id: 48,
      cat: 'Hydrological',
      sd: 4,
      sh: 14,
      ed: 4,
      eh: 15,
      em: 30,
      loc: '45.4680, 9.1950',
      title: 'Venice Acqua Alta',
      tag: 'rainfall',
      desc:
          'Acqua Alta event recorded in Venice. Water levels reaching 90 cm above normal.',
    ),
  );
  sb.write(
    row(
      id: 49,
      cat: 'Hydrological',
      sd: 20,
      sh: 8,
      ed: 20,
      eh: 20,
      loc: '45.4670, 9.1860',
      title: 'Val dOssola rainfall event',
      tag: 'rainfall',
      desc: 'Heavy rainfall event in Val dOssola causing localized flooding.',
      grp: 'group_3',
    ),
  );

  // METEOROLOGICAL (16 events, offsets 50-65)
  sb.writeln('');
  sb.writeln('    // METEOROLOGICAL (offsets 50-65) - 16 events');
  sb.write(
    row(
      id: 50,
      cat: 'Meteorological',
      sd: 0,
      sh: 12,
      ed: 0,
      eh: 20,
      loc: rome,
      title: 'Rome thunderstorm',
      tag: 'wind',
      desc: 'Severe thunderstorm with hail and strong regional winds.',
      grp: 'group_1',
    ),
  );
  sb.write(
    row(
      id: 51,
      cat: 'Meteorological',
      sd: 1,
      sh: 19,
      ed: 1,
      eh: 19,
      em: 5,
      loc: rome,
      title: 'Lightning burst',
      tag: 'short-duration',
      desc: 'Brief intense lightning burst detected across Rome area.',
    ),
  );
  sb.write(
    row(
      id: 52,
      cat: 'Meteorological',
      sd: 3,
      ed: 5,
      loc: ves,
      title: 'Campania heat wave',
      tag: 'thermal',
      desc:
          'Extended heat wave in Campania region. Temperatures exceeding 40C.',
      grp: 'group_2',
    ),
  );
  sb.write(
    row(
      id: 53,
      cat: 'Meteorological',
      sd: 0,
      sh: 9,
      ed: 0,
      eh: 18,
      loc: strom,
      title: 'Aeolian wind advisory',
      tag: 'wind',
      desc:
          'Strong Libeccio winds in Aeolian Islands concurrent with Etna activity.',
    ),
  );
  sb.write(
    row(
      id: 54,
      cat: 'Meteorological',
      sd: 7,
      sh: 6,
      ed: 7,
      eh: 18,
      loc: rome,
      title: 'Summer thunderstorm',
      tag: 'wind',
      desc: 'Afternoon thunderstorm activity with lightning and gusty winds.',
      grp: 'group_1',
    ),
  );
  sb.write(
    row(
      id: 55,
      cat: 'Meteorological',
      sd: 8,
      ed: 10,
      loc: north,
      title: 'Northern Italy fog event',
      tag: 'rainfall',
      desc:
          'Persistent fog in northern Italy reducing visibility to under 100 meters.',
      grp: 'group_3',
    ),
  );
  sb.write(
    row(
      id: 56,
      cat: 'Meteorological',
      sd: 9,
      sh: 6,
      ed: 9,
      eh: 12,
      loc: rome,
      title: 'Rome gusty wind',
      tag: 'wind',
      desc: 'Gusty winds in Rome during same timeframe as Central Italy swarm.',
    ),
  );
  sb.write(
    row(
      id: 57,
      cat: 'Meteorological',
      sd: 12,
      ed: 13,
      loc: ves,
      title: 'Naples heat index advisory',
      tag: 'thermal',
      desc: 'High heat index advisory for Naples metropolitan area.',
      grp: 'group_2',
    ),
  );
  sb.write(
    row(
      id: 58,
      cat: 'Meteorological',
      sd: 14,
      ed: 16,
      loc: etna,
      title: 'Sicily heat wave',
      tag: 'thermal',
      desc: 'Prolonged heat wave in Sicily affecting southeastern regions.',
    ),
  );
  sb.write(
    row(
      id: 59,
      cat: 'Meteorological',
      sd: 11,
      sh: 10,
      ed: null,
      loc: rome,
      title: 'Rome weather monitoring ongoing',
      tag: 'ongoing',
      desc: 'Extended weather monitoring campaign initiated in Rome area.',
      grp: 'group_1',
    ),
  );
  sb.write(
    row(
      id: 60,
      cat: 'Meteorological',
      sd: -5,
      sh: 6,
      ed: -3,
      eh: 18,
      loc: centIt,
      title: 'Pre-range storm system',
      tag: 'boundary-filter',
      desc: 'Severe weather system before main filter range.',
    ),
  );
  sb.write(
    row(
      id: 61,
      cat: 'Meteorological',
      sd: 38,
      sh: 8,
      ed: 40,
      eh: 8,
      loc: rome,
      title: 'Post-range Mediterranean cyclone',
      tag: 'boundary-filter',
      desc: 'Mediterranean cyclone event after filter range ends.',
    ),
  );
  sb.write(
    row(
      id: 62,
      cat: 'Meteorological',
      sd: 13,
      sh: 14,
      ed: 13,
      eh: 16,
      loc: etna,
      title: 'Etna ash-clearing event',
      tag: 'wind',
      desc: 'Strong winds clearing residual ash deposits from Etna.',
    ),
  );
  sb.write(
    row(
      id: 63,
      cat: 'Meteorological',
      sd: 19,
      ed: 20,
      loc: ves,
      title: 'Campania rainfall event',
      tag: 'rainfall',
      desc: 'Heavy rainfall event in Campania with flash flood risk.',
    ),
  );
  sb.write(
    row(
      id: 64,
      cat: 'Meteorological',
      sd: 21,
      sh: 8,
      ed: 21,
      eh: 14,
      loc: centIt,
      title: 'Central Italy weather',
      tag: 'wind',
      desc: 'Severe weather with damaging winds across Central Italy.',
      grp: 'group_3',
    ),
  );
  sb.write(
    row(
      id: 65,
      cat: 'Meteorological',
      sd: 6,
      sh: 10,
      ed: 12,
      eh: 10,
      loc: centIt,
      title: 'Marche region fog',
      tag: 'rainfall',
      desc:
          'Extended fog event in Marche region with significant visibility reduction.',
    ),
  );

  // GEOLOGICAL (16 events, offsets 66-81)
  sb.writeln('');
  sb.writeln('    // GEOLOGICAL (offsets 66-81) - 16 events');
  sb.write(
    row(
      id: 66,
      cat: 'Geological',
      sd: 0,
      sh: 7,
      ed: 0,
      eh: 15,
      loc: centIt,
      title: 'Geological survey anomaly',
      tag: 'seismic',
      desc:
          'Anomalous ground deformation readings during geological survey in Central Italy.',
      grp: 'group_2',
    ),
  );
  sb.write(
    row(
      id: 67,
      cat: 'Geological',
      sd: 2,
      sh: 10,
      ed: 2,
      eh: 10,
      em: 3,
      loc: etna,
      title: 'Ground crack event',
      tag: 'short-duration',
      desc: 'New ground crack detected on Etna north flank.',
      grp: 'group_1',
    ),
  );
  sb.write(
    row(
      id: 68,
      cat: 'Geological',
      sd: 4,
      ed: 6,
      loc: ves,
      title: 'Vesuvius ground deformation',
      tag: 'thermal',
      desc:
          'Ground deformation detected at Vesuvius via GPS and InSAR monitoring.',
    ),
  );
  sb.write(
    row(
      id: 69,
      cat: 'Geological',
      sd: 5,
      sh: 8,
      ed: 5,
      eh: 20,
      loc: centIt,
      title: 'Landslide risk assessment',
      tag: 'rainfall',
      desc:
          'Elevated landslide risk due to sustained rainfall assessments in progress.',
      grp: 'group_3',
    ),
  );
  sb.write(
    row(
      id: 70,
      cat: 'Geological',
      sd: 8,
      sh: 6,
      ed: 10,
      eh: 6,
      loc: rome,
      title: 'Rome subsidence measurement',
      tag: 'thermal',
      desc: 'Subsidence measurements near Rome using InSAR data.',
    ),
  );
  sb.write(
    row(
      id: 71,
      cat: 'Geological',
      sd: 11,
      sh: 0,
      ed: 12,
      eh: 0,
      loc: strom,
      title: 'Stromboli rockfall event',
      tag: 'crater',
      desc: 'Rockfall event on Sciara del Fuoco requiring monitoring.',
      grp: 'group_2',
    ),
  );
  sb.write(
    row(
      id: 72,
      cat: 'Geological',
      sd: 13,
      sh: 9,
      ed: null,
      loc: etna,
      title: 'Etna geodetic campaign ongoing',
      tag: 'ongoing',
      desc:
          'Continuous geodetic monitoring campaign on Etna flank deformation.',
      grp: 'group_1',
    ),
  );
  sb.write(
    row(
      id: 73,
      cat: 'Geological',
      sd: -5,
      sh: 4,
      ed: -2,
      eh: 4,
      loc: centIt,
      title: 'Pre-range geological survey',
      tag: 'boundary-filter',
      desc: 'Geological survey event before main filter range.',
    ),
  );
  sb.write(
    row(
      id: 74,
      cat: 'Geological',
      sd: 37,
      sh: 10,
      ed: 40,
      eh: 10,
      loc: north,
      title: 'Post-range Alpine survey',
      tag: 'boundary-filter',
      desc: 'Alpine geological survey after filter range.',
      grp: 'group_3',
    ),
  );
  sb.write(
    row(
      id: 75,
      cat: 'Geological',
      sd: 15,
      sh: 8,
      ed: 16,
      eh: 8,
      loc: centIt,
      title: 'Carbonate platforms survey',
      tag: 'thermal',
      desc: 'Groundwater carbon dioxide degassing platform survey in Tuscany.',
    ),
  );
  sb.write(
    row(
      id: 76,
      cat: 'Geological',
      sd: 9,
      sh: 14,
      ed: 9,
      eh: 18,
      loc: ischia,
      title: 'Ischia ground Temperature',
      tag: 'thermal',
      desc: 'Ground temperature monitoring campaign on Ischia volcano.',
    ),
  );
  sb.write(
    row(
      id: 77,
      cat: 'Geological',
      sd: 17,
      sh: 10,
      ed: 18,
      eh: 14,
      loc: ves,
      title: 'Phlegrean Fields deformation',
      tag: 'seismic',
      desc:
          'Bradyseismic deformation detected at Phlegrean Fields near Naples.',
      grp: 'group_2',
    ),
  );
  sb.write(
    row(
      id: 78,
      cat: 'Geological',
      sd: 19,
      sh: 6,
      ed: 20,
      eh: 18,
      loc: centIt,
      title: 'Central Italy microseismic array',
      tag: 'seismic',
      desc:
          'Temporary microseismic monitoring array deployment in Central Italy.',
    ),
  );
  sb.write(
    row(
      id: 79,
      cat: 'Geological',
      sd: 21,
      sh: 8,
      ed: 21,
      eh: 12,
      loc: etna,
      title: 'Etna soil gas survey',
      tag: 'gas',
      desc: 'Soil gas radon and CO2 survey across Etna summit plateau.',
      grp: 'group_1',
    ),
  );
  sb.write(
    row(
      id: 80,
      cat: 'Geological',
      sd: 22,
      sh: 10,
      ed: 22,
      eh: 16,
      loc: rome,
      title: 'Roman limestone karst mapping',
      tag: 'water',
      desc: 'Karst feature mapping in the Albano Hills near Rome.',
    ),
  );
  sb.write(
    row(
      id: 81,
      cat: 'Geological',
      sd: 23,
      ed: 23,
      eh: 12,
      loc: north,
      title: 'Po plain sediment analysis',
      tag: 'rainfall',
      desc: 'Sediment core analysis in Po plain floodplain deposits.',
      grp: 'group_3',
    ),
  );

  // ATMOSPHERIC (18 events, offsets 82-99)
  sb.writeln('');
  sb.writeln('    // ATMOSPHERIC (offsets 82-99) - 18 events');
  sb.write(
    row(
      id: 82,
      cat: 'Atmospheric',
      sd: 0,
      sh: 5,
      ed: 0,
      eh: 13,
      loc: rome,
      title: 'Rome air quality alert',
      tag: 'gas',
      desc: 'Elevated PM2.5 levels in Rome triggering air quality advisory.',
      grp: 'group_1',
    ),
  );
  sb.write(
    row(
      id: 83,
      cat: 'Atmospheric',
      sd: 1,
      sh: 14,
      ed: 1,
      eh: 14,
      em: 4,
      loc: etna,
      title: 'Sulfur spike',
      tag: 'short-duration',
      desc: 'Brief sulfur dioxide spike detected at Etna summit.',
      grp: 'group_1',
    ),
  );
  sb.write(
    row(
      id: 84,
      cat: 'Atmospheric',
      sd: 3,
      ed: 5,
      loc: ves,
      title: 'Naples smog episode',
      tag: 'gas',
      desc: 'Persistent smog conditions over Naples bay region.',
      grp: 'group_2',
    ),
  );
  sb.write(
    row(
      id: 85,
      cat: 'Atmospheric',
      sd: 0,
      sh: 9,
      ed: 0,
      eh: 18,
      loc: rome,
      title: 'Ozone layer monitoring event',
      tag: 'gas',
      desc:
          'Elevated ground-level ozone measured during daytime monitoring campaign.',
    ),
  );
  sb.write(
    row(
      id: 86,
      cat: 'Atmospheric',
      sd: 6,
      ed: 9,
      loc: north,
      title: 'Northern Italy haze event',
      tag: 'gas',
      desc:
          'Atmospheric haze persisting across northern Italy due to stagnant conditions.',
      grp: 'group_3',
    ),
  );
  sb.write(
    row(
      id: 87,
      cat: 'Atmospheric',
      sd: 10,
      sh: 8,
      ed: 10,
      eh: 16,
      loc: centIt,
      title: 'Central Italy VOC study',
      tag: 'gas',
      desc:
          'Volatile organic compound sampling campaign in Central Italy urban areas.',
    ),
  );
  sb.write(
    row(
      id: 88,
      cat: 'Atmospheric',
      sd: 11,
      ed: 12,
      loc: etna,
      title: 'Etna gas plume tracking',
      tag: 'gas',
      desc:
          '24-hour gas plume dispersion tracking from Etna summit using lidar.',
      grp: 'group_1',
    ),
  );
  sb.write(
    row(
      id: 89,
      cat: 'Atmospheric',
      sd: 13,
      sh: 6,
      ed: null,
      loc: rome,
      title: 'Rome aerosol monitoring ongoing',
      tag: 'ongoing',
      desc: 'Continuous aerosol particle monitoring campaign in Rome.',
      grp: 'group_1',
    ),
  );
  sb.write(
    row(
      id: 90,
      cat: 'Atmospheric',
      sd: -5,
      ed: -4,
      eh: 12,
      loc: centIt,
      title: 'Pre-range atmospheric study',
      tag: 'boundary-filter',
      desc: 'Atmospheric composition study before main filter range.',
    ),
  );
  sb.write(
    row(
      id: 91,
      cat: 'Atmospheric',
      sd: 38,
      sh: 6,
      ed: 40,
      eh: 18,
      loc: ves,
      title: 'Post-range aerosol campaign',
      tag: 'boundary-filter',
      desc: 'Aerosol measurement campaign after filter range ends.',
    ),
  );
  sb.write(
    row(
      id: 92,
      cat: 'Atmospheric',
      sd: 14,
      sh: 10,
      ed: 15,
      eh: 10,
      loc: etna,
      title: 'Etna volcanic gas budget',
      tag: 'gas',
      desc: 'Volcanic gas budget estimation at Etna summit craters.',
      grp: 'group_1',
    ),
  );
  sb.write(
    row(
      id: 93,
      cat: 'Atmospheric',
      sd: 16,
      sh: 7,
      ed: 17,
      eh: 15,
      loc: north,
      title: 'Milan nitrogen dioxide alert',
      tag: 'gas',
      desc:
          'Elevated NO2 concentrations in Milan triggering urban air quality alert.',
    ),
  );
  sb.write(
    row(
      id: 94,
      cat: 'Atmospheric',
      sd: 18,
      sh: 9,
      ed: 18,
      eh: 17,
      loc: rome,
      title: 'Rome particulate matter spike',
      tag: 'gas',
      desc: 'PM10 measurements exceeding EU thresholds in Rome.',
      grp: 'group_1',
    ),
  );
  sb.write(
    row(
      id: 95,
      cat: 'Atmospheric',
      sd: 9,
      sh: 6,
      ed: 9,
      eh: 12,
      loc: centIt,
      title: 'Central Italy atmospheric moisture',
      tag: 'wind',
      desc: 'Atmospheric water vapor monitoring during swarm event window.',
    ),
  );
  sb.write(
    row(
      id: 96,
      cat: 'Atmospheric',
      sd: 20,
      sh: 12,
      ed: 21,
      eh: 18,
      loc: strom,
      title: 'Stromboli summit atmosphere',
      tag: 'gas',
      desc: 'Atmospheric composition study above Stromboli summit craters.',
      grp: 'group_2',
    ),
  );
  sb.write(
    row(
      id: 97,
      cat: 'Atmospheric',
      sd: 22,
      sh: 6,
      ed: 23,
      eh: 6,
      loc: ves,
      title: 'Vesuvius SO2 flux monitoring',
      tag: 'gas',
      desc: 'Sulfur dioxide flux measurements at Vesuvius summit crater.',
    ),
  );
  sb.write(
    row(
      id: 98,
      cat: 'Atmospheric',
      sd: 24,
      sh: 8,
      ed: 24,
      eh: 20,
      loc: etna,
      title: 'Etna atmospheric boundary layer study',
      tag: 'gas',
      desc: 'Boundary layer meteorology study near Etna volcanic plume.',
      grp: 'group_1',
    ),
  );
  sb.write(
    row(
      id: 99,
      cat: 'Atmospheric',
      sd: 25,
      ed: 26,
      eh: 12,
      loc: rome,
      title: 'Rome final atmospheric snapshot',
      tag: 'gas',
      desc: 'Final atmospheric composition snapshot of Rome for demo period.',
      grp: 'group_3',
    ),
  );

  // Close the list and function
  sb.writeln('''  ];

  return rows.map((row) => row.toEvent()).toList();
}
''');

  // Write the file
  final file = File('lib/data/seed/event_seed_data.dart');
  file.writeAsStringSync(sb.toString());
  print('Generated event_seed_data.dart successfully');
  print('Total events: 100');
  print(
    'Distribution: Volcanic=17, Earthquake=17, Hydrological=16, Meteorological=16, Geological=16, Atmospheric=18',
  );
}
