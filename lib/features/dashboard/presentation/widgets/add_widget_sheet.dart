import 'package:flutter/material.dart';
import '../../../../config/theme/app_theme.dart';
import '../utils/dashboard_constants.dart';
import '../utils/dashboard_widgets_registry.dart';

class AddWidgetSheet extends StatelessWidget {
  final List<String> currentLayout;
  final Function(String) onAdd;

  const AddWidgetSheet({
    super.key,
    required this.currentLayout,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final allIds = DashboardWidgetRegistry.availableWidgetIds;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Agregar Widget',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: allIds.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final id = allIds[index];
                final meta = DashboardWidgetRegistry.getMetadata(id)!;
                final isAdded = currentLayout.contains(id);

                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isAdded ? Colors.grey[200] : AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      meta.icon,
                      color: isAdded ? Colors.grey : AppTheme.primaryColor,
                    ),
                  ),
                  title: Text(
                    meta.displayName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isAdded ? Colors.grey : null,
                    ),
                  ),
                  subtitle: Text(
                    meta.description,
                    style: TextStyle(
                      color: isAdded ? Colors.grey[400] : null,
                      fontSize: 12,
                    ),
                  ),
                  trailing: isAdded
                      ? const Icon(Icons.check, color: Colors.green)
                      : ElevatedButton(
                          onPressed: () {
                            onAdd(id);
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            shape: const CircleBorder(),
                            padding: const EdgeInsets.all(8),
                          ),
                          child: const Icon(Icons.add, size: 20),
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
