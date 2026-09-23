import 'package:flutter/material.dart';
class Movie {
  String title;
  

  Movie({required this.title}); //required가 붙으면 필수
}

void main() {
  
  
  // 4. nullable 닉네임을 안전한 기본값으로 변환 (?? 연산자 사용)
  String? userNickname; // 현재 null 상태라고 가정
  String displayName = userNickname ?? '0화L0VER';
  debugPrint('환영합니다, $displayName님!');

  // 2. 영화 3개를 List<Movie>에 넣기
  List<Movie> movieList = [
    Movie(title: '라라랜드'),
    Movie(title: '파이트 클럽'),
    Movie(title: '오디세이'),
  ];

  
  debugPrint('--- [for 문을 이용한 영화 제목 출력] ---');
  for (var movie in movieList) {
    debugPrint(movie.title);

  runApp(const MyApp());
  }
}

class MyApp extends StatelessWidget { //StatelessWidget 은 정적일때 사용
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {//현재 데이터에 맞는 위젯트리를 build에서 반환 
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
          title: const Text('내 프로필'),
          elevation: 0,
          scrolledUnderElevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: .center,
          children: [
            const 
            
            Text('보고 싶은 영화부터 나만의 평점까지 한곳에서 관리해요'),
            const Icon(
                Icons.movie_outlined,
                size: 72,
                color: Colors.red,
                semanticLabel: '영화 아이콘',
              ),

          
          ElevatedButton(
  onPressed: () {
    debugPrint('시작하기 버튼을 눌렀습니다.');
  },
  style: ElevatedButton.styleFrom(
    minimumSize: const Size(double.infinity, 48),
    padding: const EdgeInsets.symmetric(horizontal: 24),
  ),
  child: const Text('시작하기'), //버튼 안에 들어갈거
)],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter, //버튼 기능지정
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
    
  }
  
}
