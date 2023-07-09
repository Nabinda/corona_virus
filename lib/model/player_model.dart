class PlayerModel {
  final int id;
  final String name;
  final int? sequence;
  PlayerModel({required this.id, required this.name, this.sequence});

  @override
  String toString() => 'PlayerMode(id:$id, name:$name, sequence:$sequence)';
}
