enum NodeState { active, locked, completed }

class LessonNode {
  const LessonNode({
    required this.id,
    required this.title,
    required this.state,
    this.stars = 0,
  });

  final String id;
  final String title;
  final NodeState state;
  final int stars; // 0–3

  LessonNode copyWith({NodeState? state, int? stars}) {
    return LessonNode(
      id: id,
      title: title,
      state: state ?? this.state,
      stars: stars ?? this.stars,
    );
  }
}

class LearningUnit {
  const LearningUnit({
    required this.id,
    required this.title,
    required this.description,
    required this.nodes,
    this.isUnlocked = false,
  });

  final String id;
  final String title;
  final String description;
  final List<LessonNode> nodes;
  final bool isUnlocked;

  bool get isCompleted => nodes.every((n) => n.state == NodeState.completed);
}