import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'api.dart';
import 'config.dart';
import 'simulator.dart';

enum AppRole { rider, customer }

void main() {
  runApp(const DeliveryApp());
}

class DeliveryApp extends StatelessWidget {
  const DeliveryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Delivery Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3B82F6),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const RoleSelectScreen(),
    );
  }
}

class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Icon(Icons.local_shipping, size: 64, color: Color(0xFF3B82F6)),
              const SizedBox(height: 16),
              Text(
                'Delivery Tracker',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Choose your role for the demo',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DeliveryScreen(role: AppRole.rider),
                  ),
                ),
                icon: const Icon(Icons.two_wheeler),
                label: const Text('Rider App'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DeliveryScreen(role: AppRole.customer),
                  ),
                ),
                icon: const Icon(Icons.person),
                label: const Text('Customer App'),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class DeliveryScreen extends StatefulWidget {
  const DeliveryScreen({super.key, required this.role});

  final AppRole role;

  @override
  State<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends State<DeliveryScreen> {
  Map<String, dynamic>? _delivery;
  bool _loading = true;
  String? _error;
  double? _etaSeconds;
  MovementSimulator? _simulator;
  WebSocketChannel? _ws;
  StreamSubscription? _wsSub;

  static const _deliveryId = 'delivery-001';
  static const _riderId = 'rider-001';

  @override
  void initState() {
    super.initState();
    _load();
    _connectWs();
  }

  @override
  void dispose() {
    _simulator?.stop();
    _wsSub?.cancel();
    _ws?.sink.close();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await DeliveryApi.getDeliveries();
      final d = list.firstWhere((e) => e['id'] == _deliveryId);
      setState(() {
        _delivery = d as Map<String, dynamic>;
        _etaSeconds = (d['eta_seconds'] as num?)?.toDouble();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _connectWs() {
    _ws = WebSocketChannel.connect(Uri.parse(ApiConfig.wsUrl));
    _wsSub = _ws!.stream.listen((data) {
      try {
        final event = jsonDecode(data as String) as Map<String, dynamic>;
        if (event['deliveryId'] != _deliveryId) return;

        if (event['type'] == 'delivery.eta_updated') {
          setState(() {
            _etaSeconds = (event['etaSeconds'] as num?)?.toDouble();
          });
        }
        if (event['type'] == 'delivery.status_changed') {
          _load();
        }
      } catch (_) {}
    });
  }

  Future<void> _accept() async {
    await DeliveryApi.accept(_deliveryId);
    await _load();
  }

  Future<void> _startTrip() async {
    await DeliveryApi.startTrip(_deliveryId);
    await _load();

    final origin = _delivery!['origin'] as Map<String, dynamic>;
    final dest = _delivery!['destination'] as Map<String, dynamic>;

    _simulator?.stop();
    _simulator = MovementSimulator(
      startLat: (origin['lat'] as num).toDouble(),
      startLng: (origin['lng'] as num).toDouble(),
      destLat: (dest['lat'] as num).toDouble(),
      destLng: (dest['lng'] as num).toDouble(),
      deliveryId: _deliveryId,
      riderId: _riderId,
      speedMps: (_delivery!['assumed_speed_mps'] as num?)?.toDouble() ?? 5.0,
      onLocationUpdate: (_, _) {},
    );
    _simulator!.start();
    if (mounted) setState(() {});
  }

  Future<void> _handover() async {
    _simulator?.stop();
    await DeliveryApi.handover(_deliveryId);
    await _load();
  }

  Future<void> _received() async {
    await DeliveryApi.received(_deliveryId);
    await _load();
  }

  String _formatEta(double? seconds) {
    if (seconds == null) return '—';
    if (seconds < 60) return '${seconds.round()}s';
    final m = seconds ~/ 60;
    final s = (seconds % 60).round();
    return '${m}m ${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final isRider = widget.role == AppRole.rider;
    final title = isRider ? 'Rider' : 'Customer';

    return Scaffold(
      appBar: AppBar(title: Text('$title — $_deliveryId')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : _buildContent(isRider),
    );
  }

  Widget _buildContent(bool isRider) {
    final status = _delivery!['status'] as String;
    final dest = _delivery!['destination'] as Map<String, dynamic>;
    final notes = _delivery!['notes'] as String?;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StatusChip(status: status),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dest['label'] ?? 'Destination',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (notes != null) ...[
                    const SizedBox(height: 8),
                    Text(notes, style: const TextStyle(color: Colors.grey)),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: const Color(0xFF1E293B),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.timer, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 12),
                  Text(
                    'ETA: ${_formatEta(_etaSeconds)}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: const Color(0xFFF59E0B),
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          if (isRider) ..._riderActions(status) else ..._customerActions(status),
        ],
      ),
    );
  }

  List<Widget> _riderActions(String status) {
    return [
      if (status == 'PENDING')
        FilledButton(onPressed: _accept, child: const Text('Accept Delivery')),
      if (status == 'ASSIGNED')
        FilledButton(onPressed: _startTrip, child: const Text('Start Trip')),
      if (status == 'EN_ROUTE') ...[
        if (_simulator?.isRunning == true)
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text('🛵 Simulating movement…', style: TextStyle(color: Colors.grey)),
            ),
          ),
        FilledButton(onPressed: _handover, child: const Text('Confirm Handover')),
      ],
      if (status == 'HANDOVER_CONFIRMED')
        const Center(child: Text('Waiting for customer confirmation…')),
      if (status == 'RECEIVED')
        const Center(child: Text('✅ Delivery complete')),
    ];
  }

  List<Widget> _customerActions(String status) {
    return [
      if (status == 'RECEIVED')
        const Center(child: Text('✅ Delivery received — thank you!'))
      else
        FilledButton(
          onPressed: status == 'HANDOVER_CONFIRMED' ? _received : null,
          child: const Text('Confirm Received'),
        ),
      if (status != 'HANDOVER_CONFIRMED' && status != 'RECEIVED')
        const Padding(
          padding: EdgeInsets.only(top: 12),
          child: Center(
            child: Text(
              'Button activates when rider confirms handover',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
        ),
    ];
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  static const _colors = {
    'PENDING': Color(0xFF94A3B8),
    'ASSIGNED': Color(0xFF3B82F6),
    'EN_ROUTE': Color(0xFFF59E0B),
    'HANDOVER_CONFIRMED': Color(0xFF8B5CF6),
    'RECEIVED': Color(0xFF22C55E),
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[status] ?? Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
        textAlign: TextAlign.center,
      ),
    );
  }
}
