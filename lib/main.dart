import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

const String WORKER_URL = "https://deluxe-servers.ridwamarsya.workers.dev";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initNotifications();
  runApp(MyApp());
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = 
    FlutterLocalNotificationsPlugin();

Future<void> initNotifications() async {
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'deluxe_channel',
    'Deluxe Teriosh',
    description: 'Notifikasi dari Deluxe Teriosh App',
    importance: Importance.high,
    priority: Priority.high,
  );
  
  await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);
  
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

Future<void> showNotification(String title, String message) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'deluxe_channel',
    'Deluxe Teriosh',
    channelDescription: 'Notifikasi dari Deluxe Teriosh App',
    importance: Importance.high,
    priority: Priority.high,
    visibility: NotificationVisibility.public,
    icon: '@mipmap/ic_launcher',
    styleInformation: BigTextStyleInformation(message),
  );
  
  const NotificationDetails platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
  );
  
  await flutterLocalNotificationsPlugin.show(
    DateTime.now().millisecondsSinceEpoch.remainder(100000),
    title,
    message,
    platformChannelSpecifics,
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Deluxe Teriosh',
      theme: ThemeData.dark(),
      home: SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 1500), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => WebViewScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1a0f2e), Color(0xFF0f0a1a)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF8b5cf6), Color(0xFFa855f7)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(Icons.storage, size: 40, color: Colors.white),
              ),
              SizedBox(height: 20),
              Text(
                "DELUXE TERIOSH",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              SizedBox(height: 10),
              Text("Loading...", style: TextStyle(color: Color(0xFFa78bfa))),
              SizedBox(height: 20),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8b5cf6)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WebViewScreen extends StatefulWidget {
  @override
  _WebViewScreenState createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late WebViewController _controller;
  bool isLoading = true;
  bool isMaintenance = false;
  String maintenanceTitle = "Maintenance";
  String maintenanceMessage = "Server sedang maintenance.";
  Timer? notificationTimer;

  Future<void> fetchNotification() async {
    try {
      final response = await http.get(
        Uri.parse("$WORKER_URL/api/notification"),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['show'] == true) {
          if (!isMaintenance) {
            setState(() {
              isMaintenance = true;
              maintenanceTitle = data['title'] ?? "Maintenance";
              maintenanceMessage = data['message'] ?? "Server sedang maintenance.";
            });
            await showNotification(maintenanceTitle, maintenanceMessage);
          } else if (maintenanceMessage != data['message']) {
            setState(() {
              maintenanceMessage = data['message'];
            });
            await showNotification(data['title'] ?? "Update", data['message']);
          }
        } else {
          setState(() => isMaintenance = false);
        }
      }
    } catch (e) {
      print("Fetch notif error: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    notificationTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      fetchNotification();
    });
    fetchNotification();
  }

  @override
  void dispose() {
    notificationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Deluxe Teriosh"),
        centerTitle: true,
        backgroundColor: Color(0xFF1a0f2e),
        elevation: 0,
        actions: [
          if (isMaintenance)
            Container(
              margin: EdgeInsets.only(right: 15),
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                  SizedBox(width: 4),
                  Text("MAINTENANCE", style: TextStyle(fontSize: 10, color: Colors.red)),
                ],
              ),
            ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => _controller.reload(),
            tooltip: "Refresh",
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(2),
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF8b5cf6), Color(0xFFa855f7), Color(0xFFe879f9)],
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          WebView(
            initialUrl: WORKER_URL,
            javascriptMode: JavascriptMode.unrestricted,
            zoomEnabled: true,
            onWebViewCreated: (controller) => _controller = controller,
            onPageStarted: (url) => setState(() => isLoading = true),
            onPageFinished: (url) => setState(() => isLoading = false),
            onWebResourceError: (error) {
              print("WebView error: ${error.errorCode}");
              fetchNotification();
            },
          ),
          if (isLoading)
            Container(
              color: Color(0xFF0f0a1a).withOpacity(0.9),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8b5cf6)),
                    ),
                    SizedBox(height: 20),
                    Text("Loading...", style: TextStyle(color: Color(0xFFa78bfa))),
                  ],
                ),
              ),
            ),
          if (isMaintenance && !isLoading)
            Container(
              color: Color(0xFF0f0a1a).withOpacity(0.95),
              child: Center(
                child: Container(
                  margin: EdgeInsets.all(30),
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Color(0xFF1a0f2e),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Color(0xFF8b5cf6), width: 1),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.build, size: 60, color: Colors.orange),
                      SizedBox(height: 20),
                      Text(maintenanceTitle, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      SizedBox(height: 10),
                      Text(maintenanceMessage, textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFa78bfa))),
                      SizedBox(height: 30),
                      ElevatedButton.icon(
                        onPressed: () => _controller.reload(),
                        icon: Icon(Icons.refresh),
                        label: Text("Coba Lagi"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF8b5cf6),
                          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
