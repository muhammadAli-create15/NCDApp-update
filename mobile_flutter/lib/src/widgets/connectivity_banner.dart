import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityBanner extends StatefulWidget {
  final Color? backgroundColor;
  final Color? textColor;
  final String offlineMessage;

  const ConnectivityBanner({
    super.key, 
    this.backgroundColor,
    this.textColor,
    this.offlineMessage = 'No internet connection. Some features may be unavailable.',
  });

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner> {
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    try {
      final ConnectivityResult result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      if (mounted) {
        setState(() {
          _isConnected = false;
        });
      }
    }
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    if (mounted) {
      setState(() {
        _isConnected = result != ConnectivityResult.none;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // If connected, don't show anything
    if (_isConnected) {
      return const SizedBox.shrink();
    }

    // If disconnected, show the banner
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      color: widget.backgroundColor ?? Colors.orange.shade100,
      child: Row(
        children: [
          Icon(
            Icons.wifi_off,
            size: 18,
            color: widget.textColor ?? Colors.orange.shade800,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.offlineMessage,
              style: TextStyle(
                color: widget.textColor ?? Colors.orange.shade800,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}