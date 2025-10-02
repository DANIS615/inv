# 🚀 Mejores Prácticas para Evitar Errores de Compilación

## ❌ **Errores Comunes a Evitar:**

### 1. **Clases Anidadas (Nested Classes)**
```dart
// ❌ INCORRECTO - No permitido en Dart
class MyScreen extends StatefulWidget {
  class MyHelperClass {  // ❌ Error: Classes can't be declared inside other classes
    // ...
  }
}

// ✅ CORRECTO - Clases al nivel superior
class MyHelperClass {
  // ...
}

class MyScreen extends StatefulWidget {
  // ...
}
```

### 2. **Imports Faltantes**
```dart
// ❌ INCORRECTO - Usar tipo sin importar
class MyScreen extends StatefulWidget {
  List<InvoiceItem> items = []; // ❌ Error: Type 'InvoiceItem' not found
}

// ✅ CORRECTO - Importar el modelo
import '../models/invoice.dart';

class MyScreen extends StatefulWidget {
  List<InvoiceItem> items = []; // ✅ Funciona correctamente
}
```

### 3. **Tipos No Definidos**
```dart
// ❌ INCORRECTO - Tipo no existe
List<MyCustomType> items = []; // ❌ Error: Type 'MyCustomType' not found

// ✅ CORRECTO - Definir el tipo primero
class MyCustomType {
  // ...
}

List<MyCustomType> items = []; // ✅ Funciona correctamente
```

## ✅ **Estructura Correcta de Archivos:**

### **1. Orden de Imports:**
```dart
// 1. Imports de Flutter
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// 2. Imports de paquetes externos
import 'package:shared_preferences/shared_preferences.dart';

// 3. Imports de modelos
import '../models/client.dart';
import '../models/product.dart';

// 4. Imports de servicios
import '../services/client_service.dart';
import '../services/inventory_service.dart';

// 5. Imports de pantallas
import 'home_screen.dart';
```

### **2. Estructura de Clases:**
```dart
// Clases auxiliares al nivel superior
class MyHelperClass {
  // ...
}

// Clase principal de la pantalla
class MyScreen extends StatefulWidget {
  // ...
}

// Clase de estado
class _MyScreenState extends State<MyScreen> {
  // ...
}
```

### **3. Manejo de Controllers:**
```dart
class _MyScreenState extends State<MyScreen> {
  // Declarar controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  
  @override
  void dispose() {
    // Siempre dispose de los controllers
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}
```

## 🔧 **Herramientas de Verificación:**

### **1. Flutter Analyze:**
```bash
flutter analyze
```

### **2. Verificación de Imports:**
```bash
flutter pub deps
```

### **3. Limpieza de Proyecto:**
```bash
flutter clean
flutter pub get
```

## 📋 **Checklist Antes de Compilar:**

- [ ] ✅ Todas las clases están al nivel superior
- [ ] ✅ Todos los imports están presentes
- [ ] ✅ Todos los tipos están definidos
- [ ] ✅ Todos los controllers tienen dispose()
- [ ] ✅ No hay variables no utilizadas
- [ ] ✅ No hay métodos no utilizados
- [ ] ✅ Todas las llaves están balanceadas
- [ ] ✅ Todos los paréntesis están balanceados

## 🚨 **Errores Específicos y Soluciones:**

### **Error: "Classes can't be declared inside other classes"**
**Solución:** Mover la clase al nivel superior del archivo

### **Error: "Type 'X' not found"**
**Solución:** Agregar el import correspondiente o definir el tipo

### **Error: "The method 'X' isn't defined"**
**Solución:** Verificar que el método existe y está importado correctamente

### **Error: "The getter 'X' isn't defined"**
**Solución:** Verificar que la propiedad existe en la clase

### **Error: "RenderFlex overflowed by X pixels"**
**Solución:** Usar `Expanded` o `Flexible` en lugar de `spaceBetween`

```dart
// ❌ INCORRECTO - Puede causar overflow
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Text('Texto muy largo que puede desbordarse'),
    Text('Valor'),
  ],
)

// ✅ CORRECTO - Usar Expanded
Row(
  children: [
    Expanded(
      child: Text(
        'Texto muy largo que puede desbordarse',
        overflow: TextOverflow.ellipsis,
      ),
    ),
    const SizedBox(width: 8),
    Text('Valor'),
  ],
)

// ✅ MEJOR - Función helper reutilizable
Widget _buildSafeRow({
  required String label,
  required String value,
  TextStyle? labelStyle,
  TextStyle? valueStyle,
}) {
  return Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: labelStyle,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      const SizedBox(width: 8),
      Text(value, style: valueStyle),
    ],
  );
}
```

## 💡 **Consejos Adicionales:**

1. **Usar IDE con soporte Dart** (VS Code, Android Studio)
2. **Habilitar análisis estático** en el IDE
3. **Revisar errores antes de compilar**
4. **Usar nombres descriptivos** para variables y métodos
5. **Comentar código complejo**
6. **Mantener archivos pequeños** y bien organizados
7. **Usar constantes** para valores mágicos
8. **Validar datos de entrada** antes de procesar

## 🔄 **Flujo de Desarrollo Seguro:**

1. **Escribir código** siguiendo las mejores prácticas
2. **Verificar con flutter analyze** antes de compilar
3. **Corregir errores** inmediatamente
4. **Probar funcionalidad** en dispositivo/emulador
5. **Refactorizar** si es necesario
6. **Documentar** cambios importantes

---

**¡Siguiendo estas prácticas evitarás la mayoría de errores de compilación!** 🎯
