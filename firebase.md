import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:notification_fcm_token/Service/notification_service.dart';
import 'package:notification_fcm_token/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  NotificationService.initializedNotification();
  FirebaseMessaging.onBackgroundMessage(
    NotificationService.firebaseMessagingBackgroundHandler,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Notification',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.light,
        ),
        fontFamily: 'Roboto',
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.dark,
        ),
        fontFamily: 'Roboto',
      ),
      themeMode: ThemeMode.system,
      home: const NotificationHomePage(),
    );
  }
}

class NotificationHomePage extends StatefulWidget {
  const NotificationHomePage({super.key});

  @override
  State<NotificationHomePage> createState() => _NotificationHomePageState();
}

class _NotificationHomePageState extends State<NotificationHomePage>
    with TickerProviderStateMixin {
  int _notificationCount = 0;
  String _fcmToken = 'loading...';
  bool _isSubscribed = true;
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  final List<NotificationItem> _recentNotifications = [
    NotificationItem(
      title: 'Welcome!',
      message: 'Firebase notification are ready',
      time: 'Just now',
      icon: Icons.celebration,
      color: Colors.green,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadFCMToken();
    _setupNotificationListener();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.elasticOut),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
        );

    _slideController.forward();
  }

  void _setupNotificationListener() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      setState(() {
        _notificationCount++;
        _recentNotifications.insert(
          0,
          NotificationItem(
            title: message.notification?.title ?? "New Notification",
            message: message.notification?.body ?? "You have a new message",
            time: "Now",
            icon: Icons.notifications_active,
            color: Theme.of(context).colorScheme.primary,
          ),
        );
        if (_recentNotifications.length > 5) {
          _recentNotifications.removeLast();
        }
      });
      _pulseController.forward().then((_) {
        _pulseController.reverse();
      });
    });
  }

  Future<void> _loadFCMToken() async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      setState(() {
        _fcmToken = token ?? 'Unable to get token';
      });
    } catch (e) {
      setState(() {
        _fcmToken = 'Error loading token';
      });
    }
  }

  Future<void> _toggleSubscription() async {
    try {
      if (_isSubscribed) {
        await FirebaseMessaging.instance.unsubscribeFromTopic('jong');
      } else {
        await FirebaseMessaging.instance.subscribeToTopic('jong');
      }
      setState(() {
        _isSubscribed = !_isSubscribed;
      });
      _showSnackBar(
        _isSubscribed
            ? 'Subscribed to notifications!'
            : 'Unsubscribed from notifications!',
      );
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _copyTokenToClipboard() {
    Clipboard.setData(ClipboardData(text: _fcmToken));
    _showSnackBar('FCM Token copied to clipboard!');
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorSchema = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorSchema.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: colorSchema.surface,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Firebase Notifications',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colorSchema.onSurface,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorSchema.primary.withOpacity(0.1),
                      colorSchema.secondary.withOpacity(0.1),
                    ],
                  ),
                ),
                child: Center(
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: colorSchema.primary.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.notifications_active,
                            size: 60,
                            color: colorSchema.primary,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SlideTransition(
              position: _slideAnimation,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatsCard(
                            'Total Notifications',
                            _notificationCount.toString(),
                            Icons.notifications,
                            colorSchema.primary,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: _buildStatsCard(
                            'Subscription Status',
                            _isSubscribed ? 'Active' : 'Inactive',
                            _isSubscribed ? Icons.check_circle : Icons.cancel,
                            _isSubscribed ? Colors.green : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),

                    _buildActionButton(
                      'Toggle Subscription',
                      _isSubscribed
                          ? 'Tap to unsubscribe from notifications'
                          : 'Tap to subscribe to notifications',
                      _isSubscribed
                          ? Icons.notifications_off
                          : Icons.notifications_on,
                      _toggleSubscription,
                      _isSubscribed ? Colors.orange : Colors.green,
                    ),
                    SizedBox(height: 16),

                    _buildActionButton(
                      'Copy FCM Token',
                      'Copy your Firebase Cloud Messaging token',
                      Icons.copy,
                      _copyTokenToClipboard,
                      colorSchema.secondary,
                    ),
                    SizedBox(height: 24),

                    _buildTokenCard(),
                    SizedBox(height: 24),

                    Text(
                      'Recent Notifications',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorSchema.onSurface,
                      ),
                    ),
                    SizedBox(height: 16),

                    if (_recentNotifications.isEmpty)
                      _buildEmptyState()
                    else
                      ..._recentNotifications.map(_buildNotificationTile),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
    Color color,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildTokenCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.vpn_key,
                  color: Theme.of(context).colorScheme.primary,
                ),
                SizedBox(width: 8),
                Text(
                  'FCM Token',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Text(
                _fcmToken,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTile(NotificationItem notification) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: EdgeInsets.all(12),
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: notification.color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(notification.icon, color: notification.color),
        ),
        title: Text(
          notification.title,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text(notification.message),
            SizedBox(height: 4),
            Text(
              notification.time,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.notifications_none,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            SizedBox(height: 16),
            Text(
              'No notifications yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'When you reveived notifications, they will appear here.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NotificationItem {
  final String title;
  final String message;
  final String time;
  final IconData icon;
  final Color color;

  NotificationItem({
    required this.title,
    required this.message,
    required this.time,
    required this.icon,
    required this.color,
  });
}
