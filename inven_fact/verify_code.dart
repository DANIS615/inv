import 'dart:io';

void main() async {
  print('🔍 Verificando código antes de compilar...\n');
  
  // Verificar que estamos en el directorio correcto
  if (!File('pubspec.yaml').existsSync()) {
    print('❌ No se encontró pubspec.yaml. Ejecuta desde la raíz del proyecto Flutter.');
    exit(1);
  }
  
  // Ejecutar flutter analyze
  print('📊 Ejecutando flutter analyze...');
  final analyzeResult = await Process.run('flutter', ['analyze'], runInShell: true);
  
  if (analyzeResult.exitCode == 0) {
    print('✅ flutter analyze: Sin errores encontrados');
  } else {
    print('❌ flutter analyze encontró errores:');
    print(analyzeResult.stdout);
    print(analyzeResult.stderr);
  }
  
  // Verificar archivos específicos
  await checkSpecificFiles();
  
  print('\n🎯 Verificación completada');
}

Future<void> checkSpecificFiles() async {
  final filesToCheck = [
    'lib/screens/client_invoice_screen.dart',
    'lib/screens/clients_screen.dart',
    'lib/screens/invoice_screen.dart',
  ];
  
  for (final filePath in filesToCheck) {
    final file = File(filePath);
    if (file.existsSync()) {
      print('\n📄 Verificando: $filePath');
      await checkFileContent(file);
    } else {
      print('⚠️  Archivo no encontrado: $filePath');
    }
  }
}

Future<void> checkFileContent(File file) async {
  final content = await file.readAsString();
  final lines = content.split('\n');
  
  bool hasIssues = false;
  
  // Verificar clases anidadas
  for (int i = 0; i < lines.length; i++) {
    final line = lines[i].trim();
    
    if (line.startsWith('class ') && line.contains('{')) {
      // Contar llaves abiertas antes de esta línea
      int openBraces = 0;
      for (int j = 0; j < i; j++) {
        final prevLine = lines[j];
        openBraces += prevLine.split('{').length - 1;
        openBraces -= prevLine.split('}').length - 1;
      }
      
      if (openBraces > 0) {
        print('  ❌ Línea ${i + 1}: Clase anidada: $line');
        hasIssues = true;
      }
    }
    
    // Verificar imports faltantes para tipos comunes
    if (line.contains('InvoiceItem') && !content.contains("import '../models/invoice.dart'")) {
      print('  ❌ Línea ${i + 1}: InvoiceItem sin import: $line');
      hasIssues = true;
    }
    
    if (line.contains('Client') && !content.contains("import '../models/client.dart'")) {
      print('  ❌ Línea ${i + 1}: Client sin import: $line');
      hasIssues = true;
    }
    
    if (line.contains('Product') && !content.contains("import '../models/product.dart'")) {
      print('  ❌ Línea ${i + 1}: Product sin import: $line');
      hasIssues = true;
    }
  }
  
  if (!hasIssues) {
    print('  ✅ Sin problemas detectados');
  }
}
