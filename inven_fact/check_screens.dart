import 'dart:io';

void main() async {
  print('🔍 Verificando archivos de pantallas...');
  
  final screensDir = Directory('lib/screens');
  if (!screensDir.existsSync()) {
    print('❌ Directorio lib/screens no encontrado');
    return;
  }
  
  final files = screensDir.listSync()
      .where((file) => file.path.endsWith('.dart'))
      .cast<File>();
  
  for (final file in files) {
    print('\n📄 Verificando: ${file.path}');
    await checkFile(file);
  }
  
  print('\n✅ Verificación completada');
}

Future<void> checkFile(File file) async {
  final content = await file.readAsString();
  final lines = content.split('\n');
  
  bool hasIssues = false;
  
  // Verificar clases anidadas
  for (int i = 0; i < lines.length; i++) {
    final line = lines[i].trim();
    
    // Buscar clases dentro de otras clases
    if (line.startsWith('class ') && line.contains('{')) {
      // Verificar si está dentro de otra clase
      int braceCount = 0;
      for (int j = 0; j < i; j++) {
        final prevLine = lines[j].trim();
        if (prevLine.contains('{')) {
          braceCount++;
        }
        if (prevLine.contains('}')) {
          braceCount--;
        }
      }
      
      if (braceCount > 0) {
        print('  ⚠️  Línea ${i + 1}: Clase anidada encontrada: $line');
        hasIssues = true;
      }
    }
    
    // Verificar imports faltantes
    if (line.contains('InvoiceItem') && !content.contains("import '../models/invoice.dart'")) {
      print('  ⚠️  Línea ${i + 1}: InvoiceItem usado pero import faltante');
      hasIssues = true;
    }
    
    // Verificar tipos no definidos
    if (line.contains('List<') && line.contains('>') && !line.contains('String') && !line.contains('int') && !line.contains('double') && !line.contains('bool')) {
      final typeMatch = RegExp(r'List<(\w+)>').firstMatch(line);
      if (typeMatch != null) {
        final typeName = typeMatch.group(1)!;
        if (!content.contains('class $typeName') && !content.contains('import.*$typeName')) {
          print('  ⚠️  Línea ${i + 1}: Tipo $typeName no definido: $line');
          hasIssues = true;
        }
      }
    }
  }
  
  if (!hasIssues) {
    print('  ✅ Sin problemas detectados');
  }
}
