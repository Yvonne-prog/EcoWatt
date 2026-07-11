import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const EcoWattApp());
}

class EcoWattApp extends StatefulWidget {
  const EcoWattApp({super.key});

  @override
  State<EcoWattApp> createState() => _EcoWattAppState();
}

class _EcoWattAppState extends State<EcoWattApp> {
  bool isLoading = true;
  bool isDarkMode = true;
  bool isLoggedIn = false;
  bool hasAccount = false;
  bool notificationsEnabled = true;

  String userName = '';
  String userEmail = '';
  String savedPassword = '';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    final savedName = prefs.getString('userName') ?? '';
    final savedEmail = prefs.getString('userEmail') ?? '';
    final password = prefs.getString('userPassword') ?? '';

    setState(() {
      isDarkMode = prefs.getBool('isDarkMode') ?? true;
      isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;

      userName = savedName;
      userEmail = savedEmail;
      savedPassword = password;

      hasAccount =
          savedName.isNotEmpty && savedEmail.isNotEmpty && password.isNotEmpty;

      isLoading = false;
    });
  }

  Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);
    setState(() {
      isDarkMode = value;
    });
  }

  Future<void> setNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', value);
    setState(() {
      notificationsEnabled = value;
    });
  }

 

  ThemeData _lightTheme() {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF00B894),
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFFF4F8F7),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Color(0xFFF4F8F7),
        foregroundColor: Color(0xFF10201A),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 76,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFF00B894).withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  ThemeData _darkTheme() {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF63F5A6),
      brightness: Brightness.dark,
    ).copyWith(
      primary: const Color(0xFF63F5A6),
      secondary: const Color(0xFF31D0AA),
      surface: const Color(0xFF111818),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF091010),
      cardTheme: CardThemeData(
        color: const Color(0xFF111818),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
          side: const BorderSide(color: Color(0xFF1D2828)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Color(0xFF091010),
        foregroundColor: Colors.white,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 76,
        backgroundColor: const Color(0xFF111818),
        indicatorColor: const Color(0xFF63F5A6).withValues(alpha: 0.14),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: _lightTheme(),
        darkTheme: _darkTheme(),
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    // Login is removed for the prototype/demo.
    // The app opens directly to the dashboard so the backend can be demonstrated quickly.
    final home = HomeShell(
      isDarkMode: isDarkMode,
      notificationsEnabled: notificationsEnabled,
      userName: userName.isNotEmpty ? userName : 'EcoWatt User',
      userEmail: userEmail,
      onThemeChanged: setDarkMode,
      onNotificationsChanged: setNotifications,
      onLogout: () async {},
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EcoWatt',
      theme: _lightTheme(),
      darkTheme: _darkTheme(),
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: home,
    );
  }
}

class HomeShell extends StatefulWidget {
  final bool isDarkMode;
  final bool notificationsEnabled;
  final String userName;
  final String userEmail;
  final ValueChanged<bool> onThemeChanged;
  final ValueChanged<bool> onNotificationsChanged;
  final Future<void> Function() onLogout;

  const HomeShell({
    super.key,
    required this.isDarkMode,
    required this.notificationsEnabled,
    required this.userName,
    required this.userEmail,
    required this.onThemeChanged,
    required this.onNotificationsChanged,
    required this.onLogout,
  });

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int currentIndex = 0;
  final random = Random();
  Timer? timer;

  double voltage = 0.0;
  double current = 0.0;
  double power = 0.0;
  double totalEnergy = 0.0;
  double tariff = 750.0;
  int efficiencyScore = 100;
  double trendPercent = 0.0;
  String peakUsageTime = 'Live';
  String lastPowerStatus = '';

  Future<void> loadSensorData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('sensor_readings')
          .doc('latest')
          .get();

      if (!doc.exists || !mounted) return;

      final data = doc.data()!;
      final newVoltage = (data['voltage'] as num?)?.toDouble() ?? voltage;
      final newCurrent = (data['current'] as num?)?.toDouble() ?? current;
      final newPower = (data['power'] as num?)?.toDouble() ?? power;
      final newEnergy = (data['energy'] as num?)?.toDouble() ?? totalEnergy;
      final newStatus = _powerStatusLabel(newPower);

      setState(() {
        voltage = newVoltage;
        current = newCurrent;
        power = newPower;
        totalEnergy = newEnergy;

        powerHistory.add(power);
        energyHistory.add(totalEnergy);

        if (powerHistory.length > 20) powerHistory.removeAt(0);
        if (energyHistory.length > 20) energyHistory.removeAt(0);

        if (powerHistory.length > 1 && powerHistory.first != 0) {
          trendPercent = ((powerHistory.last - powerHistory.first) / powerHistory.first) * 100;
        } else {
          trendPercent = 0.0;
        }

        efficiencyScore = (100 - (power / 30)).round().clamp(40, 100).toInt();
        peakUsageTime = TimeOfDay.now().format(context);

        if (widget.notificationsEnabled && newStatus != lastPowerStatus) {
          notifications.insert(
            0,
            AppNotification(
              title: newStatus,
              body: 'Live reading: ${power.toStringAsFixed(0)} W, ${current.toStringAsFixed(2)} A at ${voltage.toStringAsFixed(1)} V.',
              time: 'Just now',
              icon: newPower >= 1200 ? Icons.warning_amber_rounded : Icons.sensors,
              color: newPower >= 1200 ? Colors.redAccent : Colors.green,
            ),
          );
          if (notifications.length > 20) notifications.removeLast();
          lastPowerStatus = newStatus;
        }
      });
    } catch (e) {
      debugPrint('Firestore loading error: $e');
    }
  }

  final List<double> powerHistory = [];
  final List<double> energyHistory = [];

  bool alertShowing = false;

  final List<AppNotification> notifications = [
    const AppNotification(
      title: 'EcoWatt monitor ready',
      body: 'Waiting for live ESP32 readings from Firebase.',
      time: 'Now',
      icon: Icons.sensors,
      color: Colors.green,
    ),
  ];

  final List<AppliancePreset> presets = const [
    AppliancePreset(
      name: 'Bulb',
      watts: 12,
      icon: Icons.lightbulb,
      autoOffSupported: false,
    ),
   
    AppliancePreset(
      name: 'Flat Iron',
      watts: 1200,
      icon: Icons.local_fire_department,
      autoOffSupported: true,
    ),
    
  ];

  late List<ApplianceData> appliances;

  @override
  void initState() {
    super.initState();
    appliances = [
      ApplianceData.fromPreset(
        presets.firstWhere((e) => e.name == 'Flat Iron'),
        quantity: 1,
      ),
    ];
    _loadTariff();
    loadSensorData();
    _startBackendPolling();
  }

  Future<void> _loadTariff() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      tariff = prefs.getDouble('tariff') ?? 750.0;
    });
  }

  Future<void> _saveTariff(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('tariff', value);
  }

  void _seedCharts() {
    powerHistory.clear();
    energyHistory.clear();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  bool get peakUsageDetected => power >= 1200;

  String _powerStatusLabel(double value) {
    if (value >= 1200) return 'High Power Alert';
    if (value >= 100) return 'Live Appliance Running';
    return 'No Load Detected';
  }
  double get dailyUsage => totalEnergy;
  double get weeklyUsage => dailyUsage * 6.5;
  double get estimatedCost => dailyUsage * tariff;

  String get energyStatus {
    if (power >= 1200) return 'High Usage';
    if (power >= 100) return 'Appliance Running';
    return 'No Load Detected';
  }

  List<ApplianceData> topConsumers() {
    final sorted = [...appliances];
    sorted.sort(
      (a, b) => b.configuredLoadWatts.compareTo(a.configuredLoadWatts),
    );
    return sorted.take(2).toList();
  }

  String get recommendation {
    final top = topConsumers().isNotEmpty ? topConsumers().first.name : 'the connected appliance';
    if (power >= 1200) {
      return 'High live power detected from $top. Monitor the appliance closely.';
    }
    if (power >= 100) {
      return '$top is running. EcoWatt is monitoring live voltage, current, power and energy.';
    }
    return 'No significant appliance load is detected right now.';
  }

  SavingsEstimate get savingsEstimate {
    if (appliances.isEmpty) {
      return const SavingsEstimate(
        applianceName: 'No appliance',
        savedLoadWatts: 0,
        savedMoney: 0,
      );
    }

    final sorted = [...appliances];
    sorted.sort(
      (a, b) => b.configuredLoadWatts.compareTo(a.configuredLoadWatts),
    );
    final top = sorted.first;
    final savedWatts = power * 0.30;
    final savedMoney = (savedWatts / 1000) * tariff;

    return SavingsEstimate(
      applianceName: top.name,
      savedLoadWatts: savedWatts,
      savedMoney: savedMoney,
    );
  }

  void _applyAutoOffIfNeeded() {
    final candidates = appliances
        .where((a) => a.autoOffEnabled && a.autoOffSupported)
        .toList();

    if (peakUsageDetected && candidates.isNotEmpty) {
      candidates.sort(
        (a, b) => b.configuredLoadWatts.compareTo(a.configuredLoadWatts),
      );

      final target = candidates.first;
      final index = appliances.indexOf(target);

      if (index != -1) {
        final reducedQuantity = appliances[index].quantity > 1
            ? appliances[index].quantity - 1
            : 0;

        if (reducedQuantity == 0) {
          appliances.removeAt(index);
        } else {
          appliances[index] = appliances[index].copyWith(
            quantity: reducedQuantity,
          );
        }

        notifications.insert(
          0,
          AppNotification(
            title: 'Auto-Off triggered',
            body:
                '${target.name} load was reduced to lower total power demand.',
            time: 'Just now',
            icon: Icons.power_settings_new,
            color: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showPeakPopup() {
    if (!mounted || alertShowing || !peakUsageDetected) return;
    alertShowing = true;

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('High Power Alert'),
        content: Text(
          'EcoWatt detected high total power usage (${power.toStringAsFixed(0)} W).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Dismiss'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                currentIndex = 2;
              });
            },
            child: const Text('View Appliances'),
          ),
        ],
      ),
    ).then((_) {
      alertShowing = false;
    });
  }

  void _startBackendPolling() {
    timer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (!mounted) return;
      await loadSensorData();

      _applyAutoOffIfNeeded();

      if (peakUsageDetected) {
        _showPeakPopup();
      }
    });
  }

  Future<void> editTariff() async {
    final controller = TextEditingController(text: tariff.toStringAsFixed(0));

    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Electricity Tariff'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'UGX per kWh',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              Navigator.pop(context, value);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result > 0) {
      await _saveTariff(result);
      setState(() {
        tariff = result;
      });
    }
  }

  Future<void> confirmReset() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Data'),
        content: const Text('Clear measured and simulated readings?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (result == true) {
      setState(() {
        voltage = 0.0;
        current = 0.0;
        power = 0.0;
        totalEnergy = 0.0;
        efficiencyScore = 100;
        trendPercent = 0.0;
        peakUsageTime = 'Live';
        _seedCharts();
      });
    }
  }

  Future<void> openNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NotificationsScreen(
          notifications: notifications,
          notificationsEnabled: widget.notificationsEnabled,
        ),
      ),
    );
  }

  Future<void> showAddApplianceDialog() async {
    AppliancePreset selectedPreset = presets.first;
    int quantity = 1;
    bool autoOff = false;

    final result = await showDialog<ApplianceData>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: const Text('Add Appliance'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<AppliancePreset>(
                    initialValue: selectedPreset,
                    decoration: const InputDecoration(
                      labelText: 'Appliance',
                      border: OutlineInputBorder(),
                    ),
                    items: presets
                        .map(
                          (preset) => DropdownMenuItem(
                            value: preset,
                            child: Text(
                              '${preset.name} • ${preset.watts.toStringAsFixed(0)}W',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setLocalState(() {
                        selectedPreset = value;
                        if (!selectedPreset.autoOffSupported) {
                          autoOff = false;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: '1',
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Quantity / Units',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      quantity = int.tryParse(value) ?? 1;
                      if (quantity < 1) quantity = 1;
                    },
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.08),
                    ),
                    child: Text(
                      'Rated appliance load: ${(selectedPreset.watts * quantity).toStringAsFixed(0)} W',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.08),
                    ),
                    child: const Text(
                      'Live readings come from the ESP32 sensors. Added appliances are used to label and understand the monitored load.',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      ApplianceData.fromPreset(
                        selectedPreset,
                        quantity: quantity,
                        autoOffEnabled: autoOff,
                      ),
                    );
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        final existingIndex = appliances.indexWhere(
          (a) => a.name == result.name,
        );
        if (existingIndex >= 0) {
          final existing = appliances[existingIndex];
          appliances[existingIndex] = existing.copyWith(
            quantity: existing.quantity + result.quantity,
            autoOffEnabled: existing.autoOffEnabled || result.autoOffEnabled,
          );
        } else {
          appliances.add(result);
        }
      });
    }
  }

  void removeAppliance(int index) {
    setState(() {
      appliances.removeAt(index);
    });
  }

  void showInfoDialog(String title, String body) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
Future<void> handleAccountMenu(String value) async {
  if (value == 'about') {
    showInfoDialog(
      'About the App',
      'EcoWatt helps users monitor electricity, manage appliance load, receive alerts, and understand usage patterns through one smart dashboard.',
    );
  }
}
  

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(
        status: energyStatus,
        power: power,
        dailyUsage: dailyUsage,
        estimatedCost: estimatedCost,
        efficiencyScore: efficiencyScore,
        trendPercent: trendPercent,
        recommendation: recommendation,
        powerHistory: powerHistory,
        topConsumers: topConsumers(),
        tariff: tariff,
        peakUsageDetected: peakUsageDetected,
        weeklyUsage: weeklyUsage,
        weeklyCost: weeklyUsage * tariff,
        savingsEstimate: savingsEstimate,
      ),
      LiveMonitorScreen(
        voltage: voltage,
        current: current,
        power: power,
        totalEnergy: totalEnergy,
      ),
      AppliancesScreen(
        tariff: tariff,
        appliances: appliances,
        livePower: power,
        onDeleteAppliance: removeAppliance,
      ),
      AnalyticsScreen(
        dailyUsage: dailyUsage,
        weeklyUsage: weeklyUsage,
        peakUsageTime: peakUsageTime,
        trendPercent: trendPercent,
        powerHistory: powerHistory,
        energyHistory: energyHistory,
        appliances: appliances,
        livePower: power,
      ),
      SettingsScreen(
        isDarkMode: widget.isDarkMode,
        onThemeChanged: widget.onThemeChanged,
        tariff: tariff,
        onEditTariff: editTariff,
        onResetData: confirmReset,
        notificationsEnabled: widget.notificationsEnabled,
        onNotificationsChanged: widget.onNotificationsChanged,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('EcoWatt'),
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: PopupMenuButton<String>(
            tooltip: 'Account',
            offset: const Offset(0, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onSelected: handleAccountMenu,
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.userName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.userEmail,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'about',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.info_outline),
                  title: Text('About the App'),
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            onPressed: openNotifications,
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none_rounded),
                if (widget.notificationsEnabled)
                  Positioned(
                    right: -1,
                    top: -1,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: screens[currentIndex],
      floatingActionButton: currentIndex == 2
          ? FloatingActionButton.extended(
              onPressed: showAddApplianceDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Appliance'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (value) {
          setState(() {
            currentIndex = value;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.sensors_outlined),
            selectedIcon: Icon(Icons.sensors),
            label: 'Live',
          ),
          NavigationDestination(
            icon: Icon(Icons.electrical_services_outlined),
            selectedIcon: Icon(Icons.electrical_services),
            label: 'Appliances',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class AppNotification {
  final String title;
  final String body;
  final String time;
  final IconData icon;
  final Color color;

  const AppNotification({
    required this.title,
    required this.body,
    required this.time,
    required this.icon,
    required this.color,
  });
}

class AppliancePreset {
  final String name;
  final double watts;
  final IconData icon;
  final bool autoOffSupported;

  const AppliancePreset({
    required this.name,
    required this.watts,
    required this.icon,
    required this.autoOffSupported,
  });
}

class ApplianceData {
  final String name;
  final double watts;
  final int quantity;
  final IconData icon;
  final bool autoOffEnabled;
  final bool autoOffSupported;

  const ApplianceData({
    required this.name,
    required this.watts,
    required this.quantity,
    required this.icon,
    required this.autoOffEnabled,
    required this.autoOffSupported,
  });

  factory ApplianceData.fromPreset(
    AppliancePreset preset, {
    required int quantity,
    bool autoOffEnabled = false,
  }) {
    return ApplianceData(
      name: preset.name,
      watts: preset.watts,
      quantity: quantity,
      icon: preset.icon,
      autoOffEnabled: autoOffEnabled,
      autoOffSupported: preset.autoOffSupported,
    );
  }

  ApplianceData copyWith({
    String? name,
    double? watts,
    int? quantity,
    IconData? icon,
    bool? autoOffEnabled,
    bool? autoOffSupported,
  }) {
    return ApplianceData(
      name: name ?? this.name,
      watts: watts ?? this.watts,
      quantity: quantity ?? this.quantity,
      icon: icon ?? this.icon,
      autoOffEnabled: autoOffEnabled ?? this.autoOffEnabled,
      autoOffSupported: autoOffSupported ?? this.autoOffSupported,
    );
  }

  double get configuredLoadWatts => watts * quantity;
}

class SavingsEstimate {
  final String applianceName;
  final double savedLoadWatts;
  final double savedMoney;

  const SavingsEstimate({
    required this.applianceName,
    required this.savedLoadWatts,
    required this.savedMoney,
  });
}

class NotificationsScreen extends StatelessWidget {
  final List<AppNotification> notifications;
  final bool notificationsEnabled;

  const NotificationsScreen({
    super.key,
    required this.notifications,
    required this.notificationsEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: notificationsEnabled
          ? ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = notifications[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: item.color.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(item.icon, color: item.color),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(item.body),
                              const SizedBox(height: 8),
                              Text(
                                item.time,
                                style: TextStyle(
                                  color: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.color
                                          ?.withValues(alpha: 0.7) ??
                                      Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            )
          : const Center(child: Text('Notifications are turned off.')),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  final String status;
  final double power;
  final double dailyUsage;
  final double estimatedCost;
  final int efficiencyScore;
  final double trendPercent;
  final String recommendation;
  final List<double> powerHistory;
  final List<ApplianceData> topConsumers;
  final double tariff;
  final bool peakUsageDetected;
  final double weeklyUsage;
  final double weeklyCost;
  final SavingsEstimate savingsEstimate;

  const DashboardScreen({
    super.key,
    required this.status,
    required this.power,
    required this.dailyUsage,
    required this.estimatedCost,
    required this.efficiencyScore,
    required this.trendPercent,
    required this.recommendation,
    required this.powerHistory,
    required this.topConsumers,
    required this.tariff,
    required this.peakUsageDetected,
    required this.weeklyUsage,
    required this.weeklyCost,
    required this.savingsEstimate,
  });

  Color statusColor() {
    if (status == 'High Usage') return Colors.red;
    if (status == 'Rising Usage') return Colors.orange;
    return Colors.green;
  }

  String trendLabel() {
    if (trendPercent >= 0) return '+${trendPercent.toStringAsFixed(1)}%';
    return '${trendPercent.toStringAsFixed(1)}%';
  }

  @override
  Widget build(BuildContext context) {
    final color = statusColor();

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 700;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            DashboardHeroCard(
              status: status,
              statusColor: color,
              trendLabel: trendLabel(),
              estimatedCost: estimatedCost,
              power: power,
              dailyUsage: dailyUsage,
              powerHistory: powerHistory,
            ),
            if (peakUsageDetected) ...[
              const SizedBox(height: 18),
              const PeakAlertCard(),
            ],
            const SizedBox(height: 18),
            ResponsiveCardGrid(
              isWide: wide,
              children: [
                DashboardStatCard(
                  title: 'Estimated Cost',
                  value: 'UGX ${estimatedCost.toStringAsFixed(0)}',
                  subtitle: 'Based on total measured energy',
                  icon: Icons.attach_money,
                ),
                DashboardStatCard(
                  title: 'Efficiency Score',
                  value: '$efficiencyScore%',
                  subtitle: efficiencyScore >= 80
                      ? 'Good performance'
                      : 'Needs improvement',
                  icon: Icons.eco,
                ),
              ],
            ),
            const SizedBox(height: 18),
            SmartInsightsCard(
              weeklyUsage: weeklyUsage,
              weeklyCost: weeklyCost,
              trendLabel: trendLabel(),
              recommendation: recommendation,
            ),
            const SizedBox(height: 18),
            ResponsiveCardGrid(
              isWide: wide,
              children: [
                CompactSavingsCard(estimate: savingsEstimate),
                TopConsumersCard(topConsumers: topConsumers, livePower: power),
              ],
            ),
          ],
        );
      },
    );
  }
}

class DashboardHeroCard extends StatelessWidget {
  final String status;
  final Color statusColor;
  final String trendLabel;
  final double estimatedCost;
  final double power;
  final double dailyUsage;
  final List<double> powerHistory;

  const DashboardHeroCard({
    super.key,
    required this.status,
    required this.statusColor,
    required this.trendLabel,
    required this.estimatedCost,
    required this.power,
    required this.dailyUsage,
    required this.powerHistory,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final chartColor = dark
        ? const Color(0xFF66FFA6)
        : const Color(0xFF19A95A);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: dark
              ? const [Color(0xFF141A1A), Color(0xFF101414)]
              : const [Color(0xFFFFFFFF), Color(0xFFF2FBF6)],
        ),
        border: Border.all(
          color: dark ? const Color(0xFF1F2626) : const Color(0xFFDDE9DF),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.eco, color: statusColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Energy Status',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        status,
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    trendLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            HeroMetric(
              label: 'Live Power',
              value: '${power.toStringAsFixed(0)} W',
            ),
            const SizedBox(height: 14),
            HeroMetric(
              label: 'Measured Energy',
              value: '${dailyUsage.toStringAsFixed(2)} kWh',
            ),
            const SizedBox(height: 18),
            const Text(
              'Live Power Trend',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 190,
              child: MiniTrendChart(
                values: powerHistory,
                chartLine: chartColor,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: chartColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: chartColor.withValues(alpha: 0.14),
                    child: Icon(
                      Icons.account_balance_wallet,
                      color: chartColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(child: Text('Total estimated cost')),
                  Text(
                    'UGX ${estimatedCost.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HeroMetric extends StatelessWidget {
  final String label;
  final String value;

  const HeroMetric({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: dark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFEEF6F0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 24),
          ),
        ],
      ),
    );
  }
}

class DashboardStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  const DashboardStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PeakAlertCard extends StatelessWidget {
  const PeakAlertCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.red.withValues(alpha: 0.10),
      child: const Padding(
        padding: EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.red,
              child: Icon(Icons.warning_amber_rounded, color: Colors.white),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'High electricity consumption detected right now. Consider reducing heavy appliance load.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SmartInsightsCard extends StatelessWidget {
  final double weeklyUsage;
  final double weeklyCost;
  final String trendLabel;
  final String recommendation;

  const SmartInsightsCard({
    super.key,
    required this.weeklyUsage,
    required this.weeklyCost,
    required this.trendLabel,
    required this.recommendation,
  });

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.of(context).size.width < 600;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.insights,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Smart Insights',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (narrow) ...[
              InsightTile(
                title: 'Measured Totals',
                lines: [
                  'Energy: ${weeklyUsage.toStringAsFixed(2)} kWh',
                  'Cost: UGX ${weeklyCost.toStringAsFixed(0)}',
                  'Trend: $trendLabel',
                ],
              ),
              const SizedBox(height: 12),
              InsightTile(
                title: 'Recommendation',
                lines: [recommendation],
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: InsightTile(
                      title: 'Measured Totals',
                      lines: [
                        'Energy: ${weeklyUsage.toStringAsFixed(2)} kWh',
                        'Cost: UGX ${weeklyCost.toStringAsFixed(0)}',
                        'Trend: $trendLabel',
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InsightTile(
                      title: 'Recommendation',
                      lines: [recommendation],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class InsightTile extends StatelessWidget {
  final String title;
  final List<String> lines;

  const InsightTile({
    super.key,
    required this.title,
    required this.lines,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          ...lines.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(e),
            ),
          ),
        ],
      ),
    );
  }
}

class CompactSavingsCard extends StatelessWidget {
  final SavingsEstimate estimate;

  const CompactSavingsCard({
    super.key,
    required this.estimate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.savings,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${estimate.applianceName} is monitored using live measured power from EcoWatt.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TopConsumersCard extends StatelessWidget {
  final List<ApplianceData> topConsumers;
  final double livePower;

  const TopConsumersCard({
    super.key,
    required this.topConsumers,
    required this.livePower,
  });

  @override
  Widget build(BuildContext context) {
    final totalRatedLoad = topConsumers.fold<double>(
      0,
      (sum, item) => sum + item.configuredLoadWatts,
    );

    double estimatedLiveWatts(ApplianceData appliance) {
      if (topConsumers.length == 1) return livePower;
      if (totalRatedLoad <= 0) return 0;
      return livePower * (appliance.configuredLoadWatts / totalRatedLoad);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Live Registered Appliances',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              topConsumers.length == 1
                  ? 'Showing real live power from EcoWatt hardware.'
                  : 'Total live power is shared across registered appliances by rated load.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            if (topConsumers.isEmpty)
              const Text('Add appliances to see live appliance monitoring.')
            else
              ...topConsumers.asMap().entries.map((entry) {
                final rank = entry.key + 1;
                final appliance = entry.value;
                final wattsNow = estimatedLiveWatts(appliance);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.green.withValues(alpha: 0.16),
                        child: Text('$rank'),
                      ),
                      const SizedBox(width: 10),
                      Icon(appliance.icon, size: 18),
                      const SizedBox(width: 10),
                      Expanded(child: Text(appliance.name)),
                      Text(
                        '${wattsNow.toStringAsFixed(0)} W live',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class LiveMonitorScreen extends StatelessWidget {
  final double voltage;
  final double current;
  final double power;
  final double totalEnergy;

  const LiveMonitorScreen({
    super.key,
    required this.voltage,
    required this.current,
    required this.power,
    required this.totalEnergy,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        DashboardStatCard(
          title: 'Voltage',
          value: '${voltage.toStringAsFixed(1)} V',
          subtitle: 'Current line voltage',
          icon: Icons.bolt,
        ),
        const SizedBox(height: 16),
        DashboardStatCard(
          title: 'Current',
          value: '${current.toStringAsFixed(2)} A',
          subtitle: 'Current flowing now',
          icon: Icons.electric_meter,
        ),
        const SizedBox(height: 16),
        DashboardStatCard(
          title: 'Power',
          value: '${power.toStringAsFixed(0)} W',
          subtitle: 'Real-time total power usage',
          icon: Icons.flash_on,
        ),
        const SizedBox(height: 16),
        DashboardStatCard(
          title: 'Accumulated Energy',
          value: '${totalEnergy.toStringAsFixed(2)} kWh',
          subtitle: 'Measured total energy usage',
          icon: Icons.bar_chart,
        ),
      ],
    );
  }
}

class AppliancesScreen extends StatelessWidget {
  final double tariff;
  final List<ApplianceData> appliances;
  final double livePower;
  final ValueChanged<int> onDeleteAppliance;

  const AppliancesScreen({
    super.key,
    required this.tariff,
    required this.appliances,
    required this.livePower,
    required this.onDeleteAppliance,
  });

  Color statusColor(double liveWatts, double ratedWatts) {
    if (liveWatts >= ratedWatts * 0.90 && ratedWatts > 0) return Colors.red;
    if (liveWatts >= 100) return Colors.orange;
    return Colors.green;
  }

  String statusLabel(double liveWatts, double ratedWatts) {
    if (liveWatts < 20) return 'Off / No load detected';
    if (liveWatts >= ratedWatts * 0.90 && ratedWatts > 0) return 'High live power usage';
    return 'Live measured power active';
  }

  @override
  Widget build(BuildContext context) {
    final totalRatedLoad = appliances.fold<double>(
      0,
      (sum, item) => sum + item.configuredLoadWatts,
    );

    if (appliances.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No appliances yet.\nTap "Add Appliance" to build your appliance list.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: appliances.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final appliance = appliances[index];
        final share = totalRatedLoad == 0
            ? 0.0
            : appliance.configuredLoadWatts / totalRatedLoad;
        final applianceLivePower = livePower * share;
        final color = statusColor(applianceLivePower, appliance.configuredLoadWatts);
        final status = statusLabel(applianceLivePower, appliance.configuredLoadWatts);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(appliance.icon, color: color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appliance.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Rated load: ${appliance.configuredLoadWatts.toStringAsFixed(0)} W (${appliance.quantity} unit${appliance.quantity > 1 ? 's' : ''})',
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'delete') onDeleteAppliance(index);
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'delete', child: Text('Remove')),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Live power now'),
                    const Spacer(),
                    Text(
                      '${applianceLivePower.toStringAsFixed(0)} W',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text('Share of total live load'),
                    const Spacer(),
                    Text('${(share * 100).toStringAsFixed(0)}%'),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: share.clamp(0.0, 1.0).toDouble(),
                    minHeight: 14,
                    color: color,
                    backgroundColor: color.withValues(alpha: 0.12),
                  ),
                ),
                const SizedBox(height: 12),
                Text('Status: $status'),
              ],
            ),
          ),
        );
      },
    );
  }
}

class AnalyticsScreen extends StatelessWidget {
  final double dailyUsage;
  final double weeklyUsage;
  final String peakUsageTime;
  final double trendPercent;
  final List<double> powerHistory;
  final List<double> energyHistory;
  final List<ApplianceData> appliances;
  final double livePower;

  const AnalyticsScreen({
    super.key,
    required this.dailyUsage,
    required this.weeklyUsage,
    required this.peakUsageTime,
    required this.trendPercent,
    required this.powerHistory,
    required this.energyHistory,
    required this.appliances,
    required this.livePower,
  });

  @override
  Widget build(BuildContext context) {
    final trendLabel = trendPercent >= 0
        ? '+${trendPercent.toStringAsFixed(1)}%'
        : '${trendPercent.toStringAsFixed(1)}%';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        UsageChartCard(
          title: 'Total Power Trend',
          unit: 'W',
          values: powerHistory,
        ),
        const SizedBox(height: 18),
        UsageChartCard(
          title: 'Total Energy Trend',
          unit: 'kWh',
          values: energyHistory,
        ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Live measurements from Ecowatt Hardware.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        const SizedBox(height: 18),
        ApplianceBarChartCard(appliances: appliances, livePower: livePower),
        const SizedBox(height: 18),
        DashboardStatCard(
          title: 'Measured Energy',
          value: '${dailyUsage.toStringAsFixed(2)} kWh',
          subtitle: 'Measured total energy so far',
          icon: Icons.today,
        ),
        const SizedBox(height: 16),
        DashboardStatCard(
          title: 'Projected Weekly Energy',
          value: '${weeklyUsage.toStringAsFixed(2)} kWh',
          subtitle: 'Projected from current total',
          icon: Icons.date_range,
        ),
        const SizedBox(height: 16),
        DashboardStatCard(
          title: 'Peak Usage Time',
          value: peakUsageTime,
          subtitle: 'Highest total power demand period',
          icon: Icons.access_time,
        ),
        const SizedBox(height: 16),
        DashboardStatCard(
          title: 'Trend',
          value: trendLabel,
          subtitle: trendPercent <= 0
              ? 'Total usage lower than previous period'
              : 'Total usage higher than previous period',
          icon: trendPercent <= 0
              ? Icons.trending_down
              : Icons.trending_up,
        ),
      ],
    );
  }
}

class SettingsScreen extends StatelessWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;
  final double tariff;
  final VoidCallback onEditTariff;
  final VoidCallback onResetData;
  final bool notificationsEnabled;
  final ValueChanged<bool> onNotificationsChanged;

  const SettingsScreen({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
    required this.tariff,
    required this.onEditTariff,
    required this.onResetData,
    required this.notificationsEnabled,
    required this.onNotificationsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.attach_money),
            title: const Text('Electricity Tariff'),
            subtitle: Text('UGX ${tariff.toStringAsFixed(0)} per kWh'),
            trailing: const Icon(Icons.edit),
            onTap: onEditTariff,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: SwitchListTile(
            secondary: const Icon(Icons.dark_mode),
            title: const Text('Dark Mode'),
            subtitle: const Text('Toggle light or dark appearance'),
            value: isDarkMode,
            onChanged: onThemeChanged,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: SwitchListTile(
            secondary: const Icon(Icons.notifications_active_outlined),
            title: const Text('Notifications'),
            subtitle: const Text('Enable EcoWatt alerts and updates'),
            value: notificationsEnabled,
            onChanged: onNotificationsChanged,
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: onResetData,
          icon: const Icon(Icons.restore),
          label: const Text('Reset Data'),
        ),
      ],
    );
  }
}

class ResponsiveCardGrid extends StatelessWidget {
  final bool isWide;
  final List<Widget> children;

  const ResponsiveCardGrid({
    super.key,
    required this.isWide,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    if (!isWide) {
      return Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1) const SizedBox(height: 16),
          ],
        ],
      );
    }

    final rows = <Widget>[];
    for (int i = 0; i < children.length; i += 2) {
      final left = children[i];
      final right = i + 1 < children.length ? children[i + 1] : const SizedBox();

      rows.add(
        Row(
          children: [
            Expanded(child: left),
            const SizedBox(width: 16),
            Expanded(child: right),
          ],
        ),
      );

      if (i + 2 < children.length) {
        rows.add(const SizedBox(height: 16));
      }
    }

    return Column(children: rows);
  }
}

class UsageChartCard extends StatelessWidget {
  final String title;
  final String unit;
  final List<double> values;

  const UsageChartCard({
    super.key,
    required this.title,
    required this.unit,
    required this.values,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final chartLine = dark
        ? const Color(0xFF66FFA6)
        : const Color(0xFF19A95A);

    final safeValues = values.isEmpty ? [0.0] : values;
    final spots = safeValues.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();

    double minY = safeValues.reduce((a, b) => a < b ? a : b);
    double maxY = safeValues.reduce((a, b) => a > b ? a : b);

    if (minY == maxY) {
      maxY = minY + 1;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Measured trend data ($unit)',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  minY: minY * 0.98,
                  maxY: maxY * 1.02,
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: dark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.06),
                    ),
                    getDrawingVerticalLine: (_) => FlLine(
                      color: dark
                          ? Colors.white.withValues(alpha: 0.04)
                          : Colors.black.withValues(alpha: 0.04),
                    ),
                  ),
                  titlesData: const FlTitlesData(
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: chartLine,
                      barWidth: 3.2,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: chartLine.withValues(alpha: 0.10),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ApplianceBarChartCard extends StatelessWidget {
  final List<ApplianceData> appliances;
  final double livePower;

  const ApplianceBarChartCard({
    super.key,
    required this.appliances,
    required this.livePower,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final barColor = dark ? const Color(0xFF63F5A6) : const Color(0xFF19A95A);

    final totalRatedLoad = appliances.fold<double>(
      0,
      (sum, item) => sum + item.configuredLoadWatts,
    );

    final topItems = [...appliances]..sort(
        (a, b) => b.configuredLoadWatts.compareTo(a.configuredLoadWatts),
      );

    if (topItems.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: Text('Add appliances to generate this chart.')),
        ),
      );
    }

    double liveWattsFor(ApplianceData item) {
      if (totalRatedLoad == 0) return 0;
      return livePower * (item.configuredLoadWatts / totalRatedLoad);
    }

    final maxValue = topItems
        .map(liveWattsFor)
        .fold<double>(1, (a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Live Appliance Power', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('Live measured power from EcoWatt hardware (W)', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 18),
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxValue * 1.2,
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: dark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.06),
                    ),
                    getDrawingVerticalLine: (_) => FlLine(color: Colors.transparent),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 34,
                        getTitlesWidget: (value, meta) => Text(
                          value.toStringAsFixed(0),
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 || i >= topItems.length) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(topItems[i].name, style: const TextStyle(fontSize: 10)),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: List.generate(
                    topItems.length,
                    (index) => BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: liveWattsFor(topItems[index]),
                          color: barColor,
                          width: 20,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MiniTrendChart extends StatelessWidget {
  final List<double> values;
  final Color chartLine;

  const MiniTrendChart({
    super.key,
    required this.values,
    required this.chartLine,
  });

  @override
  Widget build(BuildContext context) {
    final safeValues = values.isEmpty ? [0.0] : values;
    final spots = safeValues.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();

    double minY = safeValues.reduce((a, b) => a < b ? a : b);
    double maxY = safeValues.reduce((a, b) => a > b ? a : b);

    if (minY == maxY) {
      maxY = minY + 1;
    }

    return LineChart(
      LineChartData(
        minY: minY * 0.98,
        maxY: maxY * 1.02,
        gridData: FlGridData(show: true),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            barWidth: 3.2,
            color: chartLine,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: chartLine.withValues(alpha: 0.10),
            ),
          ),
        ],
      ),
    );
  }
}