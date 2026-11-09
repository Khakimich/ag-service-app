class Slot {
  Slot({required this.start, required this.label});

  final DateTime start;
  final String label;

  factory Slot.fromJson(Map<String, dynamic> json) => Slot(
        start: DateTime.parse(json['start'] as String),
        label: json['label'] as String,
      );
}
