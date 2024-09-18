class Post {
  int? userId;
  int? id;
  String? title;
  String? body;

  Post({this.userId, this.id, this.title, this.body});

  factory Post.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'userId': int userId,
        'id': int id,
        'title': String title,
        'body': String body
      } => Post(
        userId: userId,
        id: id,
        title: title,
        body: body,
      ),
      _ => throw const FormatException('Failed to load post')
    };
  }

  Post.empty();
}
