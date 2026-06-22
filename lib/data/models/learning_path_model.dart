enum NodeState { active, locked, completed }

class LessonNode {
  const LessonNode({
    required this.id,
    required this.title,
    this.state = NodeState.locked,
    this.stars = 0,
    this.order = 0,
  });

  final String id;
  final String title;
  final NodeState state;
  final int stars; // 0–3
  final int order;

  LessonNode copyWith({NodeState? state, int? stars, int? order}) {
    return LessonNode(
      id: id,
      title: title,
      state: state ?? this.state,
      stars: stars ?? this.stars,
      order: order ?? this.order,
    );
  }

  factory LessonNode.fromMap(Map<String, dynamic> map, String id) {
    return LessonNode(
      id: id,
      title: map['title'] as String? ?? '',
      // state is NOT stored in Firestore — computed from user progress
      state: NodeState.locked,
      stars: map['stars'] as int? ?? 0,
      order: map['order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'stars': stars,
      'order': order,
    };
  }
}

class LearningUnit {
  const LearningUnit({
    required this.id,
    required this.title,
    required this.description,
    required this.nodes,
    this.isUnlocked = false,
    this.order = 0,
  });

  final String id;
  final String title;
  final String description;
  final List<LessonNode> nodes;
  final bool isUnlocked;
  final int order;

  bool get isCompleted => nodes.every((n) => n.state == NodeState.completed);

  factory LearningUnit.fromMap(
      Map<String, dynamic> map, String id, List<LessonNode> nodes) {
    return LearningUnit(
      id: id,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      nodes: nodes,
      isUnlocked: map['isUnlocked'] as bool? ?? false,
      order: map['order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'isUnlocked': isUnlocked,
      'order': order,
    };
  }
}
