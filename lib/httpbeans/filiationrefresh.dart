class FiliationRefresh {
  final String parrainage;
  final double bonus;

  const FiliationRefresh({
    required this.parrainage,
    required this.bonus
  });

  factory FiliationRefresh.fromJson(Map<String, dynamic> json) {
    return FiliationRefresh(
        parrainage: json['parrainage'],
        bonus: json['bonus']
    );
  }
}