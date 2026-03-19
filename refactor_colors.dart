import 'dart:io';

void main() {
  final dir = Directory('lib');
  final entities = dir.listSync(recursive: true);
  for (var entity in entities) {
    if (entity is File && entity.path.endsWith('.dart') && !entity.path.contains('app_theme.dart')) {
      var lines = entity.readAsLinesSync();
      var changed = false;
      for (int i = 0; i < lines.length; i++) {
        if (lines[i].contains('AppTheme.primaryColor') || lines[i].contains('AppTheme.secondaryColor') || lines[i].contains('AppTheme.backgroundColor')) {
           lines[i] = lines[i].replaceAll('AppTheme.primaryColor', 'Theme.of(context).primaryColor');
           lines[i] = lines[i].replaceAll('AppTheme.secondaryColor', 'Theme.of(context).colorScheme.secondary');
           
           // Remove const from this specific line or nearby if it throws off compilation
           lines[i] = lines[i].replaceAll('const Icon', 'Icon');
           lines[i] = lines[i].replaceAll('const TextStyle', 'TextStyle');
           lines[i] = lines[i].replaceAll('const BorderSide', 'BorderSide');
           lines[i] = lines[i].replaceAll('const [', '[');
           lines[i] = lines[i].replaceAll('const BoxDecoration', 'BoxDecoration');
           lines[i] = lines[i].replaceAll('const EdgeInsets', 'EdgeInsets');
           changed = true;
        }
      }
      if (changed) {
        entity.writeAsStringSync(lines.join('\n'));
        print('Updated \${entity.path}');
      }
    }
  }
}
