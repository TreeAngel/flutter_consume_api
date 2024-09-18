import 'dart:convert';

import 'package:consume_api_jsonplaceholder/post.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const MyHomePage(title: 'Flutter Consume API JSONPlaceholder'),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  // Future<Post>? _futurePost;
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final appTheme = Theme.of(context);
    var colorScheme = appTheme.colorScheme;
    final textStyle =
        appTheme.textTheme.titleMedium!.copyWith(color: colorScheme.onPrimary);

    Widget selectedPage;
    switch (selectedIndex) {
      case 0:
        selectedPage = const GetPostsPage();
      case 1:
        selectedPage = const CreatePostPage();
      case 2:
        selectedPage = const UpdatePostPage();
      case 3:
        selectedPage = const DeletePostPage();
      default:
        throw UnimplementedError('Index of $selectedIndex out of range');
    }

    var mainArea = ColoredBox(
      color: colorScheme.surfaceContainer,
      child: AnimatedSwitcher(
        duration: Durations.short4,
        child: selectedPage,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title, style: textStyle),
      ),
      body: Column(
        children: [
          Expanded(child: mainArea),
          BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                  icon: Icon(Icons.article), label: 'Get Post'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.post_add), label: 'Create Post'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.edit_document), label: 'Edit Post'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.delete), label: 'Delete Post'),
            ],
            currentIndex: selectedIndex,
            onTap: (value) {
              setState(() {
                selectedIndex = value;
              });
            },
          ),
        ],
      ),
    );
  }
}

Future<List<Post>> fetchPosts() async {
  final uri = Uri.parse('https://jsonplaceholder.typicode.com/posts');
  final response = await http.get(uri);

  if (response.statusCode == 200) {
    List jsonResponse = jsonDecode(response.body) as List;
    return jsonResponse.map((post) => Post.fromJson(post)).toList();
  } else {
    throw Exception('Failed to load post');
  }
}

class GetPostsPage extends StatefulWidget {
  const GetPostsPage({super.key});

  @override
  State<GetPostsPage> createState() => _GetPostsPageState();
}

class _GetPostsPageState extends State<GetPostsPage> {
  late Future<List<Post>> _futurePosts;

  @override
  void initState() {
    super.initState();
    _futurePosts = fetchPosts();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Post>>(
      future: _futurePosts,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (_, index) {
              Post post = snapshot.data![index];
              return Column(
                children: [
                  ListTile(
                    title: Text(post.title.toString()),
                    subtitle: Text(post.body.toString()),
                  ),
                  const Divider()
                ],
              );
            },
          );
        } else if (snapshot.hasError) {
          return Text('Error fetching post: ${snapshot.error}');
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}

Future<Post> createPost(String title, String body) async {
  final uri = Uri.parse('https://jsonplaceholder.typicode.com/posts');
  final response = await http.post(uri,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=utf-8'
      },
      body: jsonEncode(<String, dynamic>{
        'title': title,
        'body': body,
        'userId': 1,
      }));

  if (response.statusCode == 201) {
    return Post.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  } else {
    throw Exception('Failed to create post');
  }
}

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  Future<Post>? _futurePost;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Scaffold(
        body: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.all(10),
          child: (_futurePost == null) ? buildColumn() : buildFutureBuilder(),
        ),
        floatingActionButton: (_futurePost != null)
            ? FloatingActionButton(
                onPressed: () {
                  _futurePost = null;
                },
                child: const Icon(Icons.refresh),
              )
            : null,
      ),
    );
  }

  Column buildColumn() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(hintText: 'Title'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _bodyController,
          decoration: const InputDecoration(hintText: 'Body'),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _futurePost =
                  createPost(_titleController.text, _bodyController.text);
            });
          },
          child: const Text('Create new post'),
        ),
      ],
    );
  }

  FutureBuilder<Post> buildFutureBuilder() {
    return FutureBuilder<Post>(
      future: _futurePost,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Divider(),
              const Text('Post created'),
              ListTile(
                title: Text('Title: ${snapshot.data!.title}'),
                subtitle: Text('Body: ${snapshot.data!.body}'),
              ),
              const Divider(),
            ],
          );
        } else if (snapshot.hasError) {
          return Text('Error creating post: ${snapshot.error}');
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}

Future<Post> updatePost(String title, String body) async {
  final uri = Uri.parse('https://jsonplaceholder.typicode.com/posts/1');
  final response = await http.put(uri,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=utf-8'
      },
      body: jsonEncode(<String, dynamic>{
        'id': 1,
        'title': title,
        'body': body,
        'userId': 1,
      }));

  if (response.statusCode == 200) {
    return Post.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  } else {
    throw Exception('Failed to update post');
  }
}

Future<Post> fetchPost(int? id) async {
  final uri = Uri.parse('https://jsonplaceholder.typicode.com/posts/$id');
  final response = await http.get(uri);

  if (response.statusCode == 200) {
    return Post.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  } else {
    throw Exception('Failed to load post');
  }
}

class UpdatePostPage extends StatefulWidget {
  const UpdatePostPage({super.key});

  @override
  State<UpdatePostPage> createState() => UpdatePostPageState();
}

class UpdatePostPageState extends State<UpdatePostPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  late Future<Post> _futurePost;

  @override
  void initState() {
    super.initState();
    _futurePost = fetchPost(1);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.only(left: 16, right: 16),
          child: FutureBuilder<Post>(
            future: _futurePost,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                if (snapshot.hasData) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(snapshot.data!.title.toString()),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          hintText: 'Enter Title',
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(snapshot.data!.body.toString()),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _bodyController,
                        decoration: const InputDecoration(
                          hintText: 'Enter Body',
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _futurePost = updatePost(
                                _titleController.text, _bodyController.text);
                          });
                        },
                        child: const Text('Update Data'),
                      ),
                    ],
                  );
                } else if (snapshot.hasError) {
                  return Center(child: Text('${snapshot.error}'));
                }
              }
              return const Center(child: CircularProgressIndicator());
            },
          ),
        ),
      ),
    );
  }
}

Future<Post> deletePost(int? id) async {
  final uri = Uri.parse('https://jsonplaceholder.typicode.com/posts/$id');
  final response = await http.delete(uri, headers: <String, String>{
    'Content-Type': 'application/json; charset=utf-8'
  });

  if (response.statusCode == 200) {
    return Post.empty();
  } else {
    throw Exception('Failed to delete post');
  }
}

class DeletePostPage extends StatefulWidget {
  const DeletePostPage({super.key});

  @override
  State<DeletePostPage> createState() => _DeletePostPageState();
}

class _DeletePostPageState extends State<DeletePostPage> {
  late Future<Post> _futurePost;

  @override
  void initState() {
    super.initState();
    _futurePost = fetchPost(10);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16),
        child: FutureBuilder<Post>(
          future: _futurePost,
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              if (snapshot.hasData) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Text('Title'),
                    const SizedBox(
                      height: 10,
                    ),
                    Text(snapshot.data?.title ?? 'Post Deleted'),
                    const Divider(),
                    const Text('Body'),
                    const SizedBox(
                      height: 10,
                    ),
                    Text(snapshot.data?.body ?? 'Post Deleted'),
                    const SizedBox(
                      height: 20,
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _futurePost = deletePost(snapshot.data?.id);
                        });
                      },
                      child: const Text('Delete Post'),
                    )
                  ],
                );
              } else if (snapshot.hasError) {
                return Center(child: Text('${snapshot.error}'));
              }
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }
}
