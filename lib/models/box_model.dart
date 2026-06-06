// ─────────────────────────────────────────────────────────
// ENUMS
// ─────────────────────────────────────────────────────────

enum SurpriseType {
  image,
  video,
  message,
  voiceNote,
  funnyPopup,
  jokerAnimation,
  soundEffect,
  miniGift,
  mindGame, // ✅ added
}

// ─────────────────────────────────────────────────────────
// SURPRISE MODEL
// ─────────────────────────────────────────────────────────

class Surprise {
  final String id;
  final SurpriseType type;
  final String? content;
  final String? mediaUrl;

  Surprise({
    required this.id,
    required this.type,
    this.content,
    this.mediaUrl,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'content': content,
    'mediaUrl': mediaUrl,
  };

  factory Surprise.fromJson(Map<String, dynamic> json) {
    return Surprise(
      id: json['id'] as String,
      type: SurpriseType.values.firstWhere(
            (e) => e.name == json['type'],
        orElse: () => SurpriseType.message,
      ),
      content: json['content'] as String?,
      mediaUrl: json['mediaUrl'] as String?,
    );
  }
}

// ─────────────────────────────────────────────────────────
// GIFT BOX MODEL
// ─────────────────────────────────────────────────────────

class GiftBox {
  final String id;
  final String creatorId;
  final String giftName;
  final String receiverName;
  final String? note;
  final List<Surprise> surprises;
  final DateTime createdAt;
  final String shareableLink;
  final String? selectedBoxColor;
  final bool isComplete;

  GiftBox({
    required this.id,
    required this.creatorId,
    required this.giftName,
    required this.receiverName,
    this.note,
    required this.surprises,
    required this.createdAt,
    required this.shareableLink,
    this.selectedBoxColor,
    this.isComplete = false,
  });

  GiftBox copyWith({
    String? id,
    String? creatorId,
    String? giftName,
    String? receiverName,
    String? note,
    List<Surprise>? surprises,
    DateTime? createdAt,
    String? shareableLink,
    String? selectedBoxColor,
    bool? isComplete,
  }) {
    return GiftBox(
      id: id ?? this.id,
      creatorId: creatorId ?? this.creatorId,
      giftName: giftName ?? this.giftName,
      receiverName: receiverName ?? this.receiverName,
      note: note ?? this.note,
      surprises: surprises ?? this.surprises,
      createdAt: createdAt ?? this.createdAt,
      shareableLink: shareableLink ?? this.shareableLink,
      selectedBoxColor: selectedBoxColor ?? this.selectedBoxColor,
      isComplete: isComplete ?? this.isComplete,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'creatorId': creatorId,
    'giftName': giftName,
    'receiverName': receiverName,
    'note': note,
    'surprises': surprises.map((s) => s.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'shareableLink': shareableLink,
    'selectedBoxColor': selectedBoxColor,
    'isComplete': isComplete,
  };

  factory GiftBox.fromJson(Map<String, dynamic> json) {
    return GiftBox(
      id: json['id'] as String,
      creatorId: json['creatorId'] as String,
      giftName: json['giftName'] as String,
      receiverName: json['receiverName'] as String,
      note: json['note'] as String?,
      surprises: (json['surprises'] as List<dynamic>? ?? [])
          .map((e) => Surprise.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      shareableLink: json['shareableLink'] as String? ?? '',
      selectedBoxColor: json['selectedBoxColor'] as String?,
      isComplete: json['isComplete'] as bool? ?? false,
    );
  }
}