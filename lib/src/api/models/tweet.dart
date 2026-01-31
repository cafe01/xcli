/// Minimal tweet data class for typed access to common fields.
///
/// Not a full model of the X API response -- just enough structure to avoid
/// raw map access for the most frequent fields. Commands can always fall
/// through to the raw JSON when needed.
class Tweet {
  const Tweet({
    required this.id,
    required this.text,
    this.authorId,
    this.createdAt,
    this.conversationId,
  });

  /// Parse from X API v2 tweet object.
  factory Tweet.fromJson(Map<String, dynamic> json) {
    return Tweet(
      id: json['id'] as String,
      text: json['text'] as String,
      authorId: json['author_id'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      conversationId: json['conversation_id'] as String?,
    );
  }

  final String id;
  final String text;
  final String? authorId;
  final DateTime? createdAt;
  final String? conversationId;
}
