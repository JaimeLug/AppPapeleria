import 'package:flutter/material.dart';

/// Feedback animado que se muestra bajo el cursor al arrastrar una tarjeta.
/// Da una sensación de "agarre/levantar": un pop de escala con rebote suave
/// y una sombra que crece, en vez de aparecer de golpe.
class _DragFeedback extends StatefulWidget {
  final Widget child;
  const _DragFeedback({required this.child});

  @override
  State<_DragFeedback> createState() => _DragFeedbackState();
}

class _DragFeedbackState extends State<_DragFeedback>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _lift;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..forward();
    _scale = Tween<double>(begin: 0.92, end: 1.06).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _lift = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        return Transform.scale(
          scale: _scale.value,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28 * _lift.value),
                  blurRadius: 28 * _lift.value,
                  offset: Offset(0, 14 * _lift.value),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: Opacity(opacity: 0.9, child: child),
            ),
          ),
        );
      },
    );
  }
}

class DashboardWidgetWrapper extends StatefulWidget {
  final Widget child;
  final String title;
  final bool isDragging;
  final VoidCallback? onRemove;
  final Color? backgroundColor;
  final Gradient? backgroundGradient;
  final String? widgetId; 
  final Color? overrideTextColor;
  final Color? overrideIconColor;
  final VoidCallback? onResizeWidth;
  final VoidCallback? onResizeHeight;

  const DashboardWidgetWrapper({
    super.key, 
    required this.child, 
    required this.title,
    this.isDragging = false,
    this.onRemove,
    this.backgroundColor,
    this.backgroundGradient,
    this.widgetId,
    this.overrideTextColor,
    this.overrideIconColor,
    VoidCallback? onResize, 
    this.onResizeHeight,
  }) : onResizeWidth = onResize;

  @override
  State<DashboardWidgetWrapper> createState() => _DashboardWidgetWrapperState();
}

class _DashboardWidgetWrapperState extends State<DashboardWidgetWrapper> {
  @override
  Widget build(BuildContext context) {
    final isColored = widget.backgroundColor != null || widget.backgroundGradient != null;
    
    // Determine colors
    final textColor = widget.overrideTextColor ?? (isColored ? Colors.white : Theme.of(context).primaryColor);
    final iconColor = widget.overrideIconColor ?? (isColored ? Colors.white.withValues(alpha: 0.8) : Theme.of(context).iconTheme.color?.withValues(alpha: 0.3));

    return Container(
      decoration: BoxDecoration(
        color: widget.isDragging 
            ? (widget.backgroundColor?.withValues(alpha: 0.5) ?? Colors.white.withValues(alpha: 0.5)) 
            : (widget.backgroundColor ?? Theme.of(context).cardColor),
        gradient: widget.backgroundGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: widget.isDragging ? [] : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: widget.isDragging 
            ? Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.5), width: 2) 
            : null,
      ),
      child: Stack(
        children: [
          // Content
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: widget.child,
          ),
          
          // Header Row (Title + Resize + Drag)
          Positioned(
            top: 12,
            left: 16,
            right: 8, // Ensure it doesn't touch edge
            child: Row(
              children: [
                // Title
                Expanded(
                  child: widget.title.isNotEmpty 
                  ? Text(
                      widget.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: textColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    )
                  : const SizedBox(),
                ),
                
                // Actions Group
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Width Resize Button (↔)
                    if (widget.onResizeWidth != null)
                      Material(
                        color: Colors.transparent,
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: widget.onResizeWidth,
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Icon(
                              Icons.compare_arrows,
                              color: iconColor,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      
                    if (widget.onResizeWidth != null)
                      const SizedBox(width: 4),

                    // Height Resize Button (↕)
                    if (widget.onResizeHeight != null)
                      Material(
                        color: Colors.transparent,
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: widget.onResizeHeight,
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Icon(
                              Icons.height,
                              color: iconColor,
                              size: 20,
                            ),
                          ),
                        ),
                      ),

                    if (widget.onResizeHeight != null)
                      const SizedBox(width: 8),

                    // Drag Handle
                    widget.widgetId != null 
                    ? Draggable<String>(
                        data: widget.widgetId,
                        feedback: _DragFeedback(
                          child: SizedBox(
                            width: 240,
                            height: 180,
                            child: DashboardWidgetWrapper(
                              title: widget.title,
                              isDragging: true,
                              backgroundColor: widget.backgroundColor,
                              backgroundGradient: widget.backgroundGradient,
                              overrideTextColor: widget.overrideTextColor,
                              overrideIconColor: widget.overrideIconColor,
                              child: widget.child,
                            ),
                          ),
                        ),
                        childWhenDragging: const SizedBox(), 
                        child: MouseRegion(
                          cursor: SystemMouseCursors.grab,
                          child: Icon(
                            Icons.drag_indicator,
                            color: iconColor,
                            size: 24,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.drag_indicator,
                        color: iconColor,
                        size: 24,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}