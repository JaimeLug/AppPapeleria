import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../utils/dashboard_constants.dart';
import 'dashboard_widget_wrapper.dart';

class ClockWidget extends StatefulWidget {
  final bool isDragging;
  final VoidCallback? onRemove;
  final VoidCallback? onResize;
  final VoidCallback? onResizeHeight;
    
  const ClockWidget({super.key, this.isDragging = false, this.onRemove, this.onResize, this.onResizeHeight});

  @override
  State<ClockWidget> createState() => _ClockWidgetState();
}

class _ClockWidgetState extends State<ClockWidget> {
  late Stream<DateTime> _timerStream;

  @override
  void initState() {
    super.initState();
    _timerStream = Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now()).asBroadcastStream();
  }

  @override
  Widget build(BuildContext context) {
    return DashboardWidgetWrapper(
      title: 'Hora Local',
      widgetId: DashboardWidgetIds.clock,
      isDragging: widget.isDragging,
      onRemove: widget.onRemove,
      onResize: widget.onResize,
      onResizeHeight: widget.onResizeHeight,
      backgroundGradient: LinearGradient(
        colors: [
          Colors.white,
          Theme.of(context).primaryColor.withValues(alpha: 0.05),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      overrideTextColor: Theme.of(context).primaryColor,
      overrideIconColor: Theme.of(context).primaryColor.withValues(alpha: 0.5),
      child: StreamBuilder<DateTime>(
        stream: _timerStream,
        initialData: DateTime.now(),
        builder: (context, snapshot) {
          final now = snapshot.data!;
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('HH:mm:ss').format(now),
                  style: GoogleFonts.outfit(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  DateFormat('EEEE d, MMMM', 'es_ES').format(now).toUpperCase(),
                  style: GoogleFonts.quicksand(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}