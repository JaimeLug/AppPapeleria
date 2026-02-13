import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../../features/settings/presentation/providers/settings_provider.dart';
import '../utils/dashboard_constants.dart';
import 'dashboard_widget_wrapper.dart';
import 'dart:async';

class QuickNoteWidget extends ConsumerStatefulWidget {
  final bool isDragging;
  final VoidCallback? onRemove;
  final VoidCallback? onResize;
  final VoidCallback? onResizeHeight;

  const QuickNoteWidget({super.key, this.isDragging = false, this.onRemove, this.onResize, this.onResizeHeight});

  @override
  ConsumerState<QuickNoteWidget> createState() => _QuickNoteWidgetState();
}



class _QuickNoteWidgetState extends ConsumerState<QuickNoteWidget> {
  late TextEditingController _controller;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Initialize with stored content
    final savedContent = ref.read(settingsProvider).quickNoteContent;
    _controller = TextEditingController(text: savedContent);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _saveNote(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 1000), () {
      ref.read(settingsProvider.notifier).updateQuickNote(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listen to external changes if necessary (though rare for this field)
    // ref.listen(settingsProvider.select((s) => s.quickNoteContent), (prev, next) {
    //   if (next != _controller.text) {
    //     _controller.text = next;
    //   }
    // });

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

     return DashboardWidgetWrapper(
       title: 'Notas Rápidas',
       widgetId: DashboardWidgetIds.quickNote,
       isDragging: widget.isDragging,
       onRemove: widget.onRemove,
       backgroundColor: isDarkMode ? Theme.of(context).cardColor : Colors.yellow[50],
       overrideTextColor: isDarkMode ? Colors.white : AppTheme.primaryColor,
       overrideIconColor: isDarkMode ? Colors.white70 : AppTheme.primaryColor.withOpacity(0.5),
       onResize: widget.onResize,
       onResizeHeight: widget.onResizeHeight,
       child: Container(
         padding: const EdgeInsets.fromLTRB(16, 40, 16, 8),
         child: Container(
           decoration: isDarkMode ? BoxDecoration(
              color: const Color(0xFFFFF8E1), // Cream color for the "paper" (lighter)
              borderRadius: BorderRadius.circular(12),
           ) : null,
           padding: isDarkMode ? const EdgeInsets.all(12) : EdgeInsets.zero,
           child: TextField(
             controller: _controller,
             onChanged: _saveNote,
             maxLines: null,
             expands: true,
             style: GoogleFonts.handlee(
               fontSize: 16,
               color: isDarkMode ? Colors.black87 : Colors.grey[800], // Force Dark text
             ),
             decoration: InputDecoration(
               border: InputBorder.none,
               hintText: 'Escribe algo importante...',
               filled: false, // Disable global theme fill to show the cream container
               hintStyle: TextStyle(color: isDarkMode ? Colors.black54 : Colors.grey),
             ),
           ),
         ),
       ),
    );
  }
}
