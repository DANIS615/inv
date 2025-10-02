# Plan Detallado: Sistema Multi-Cliente con Gestión de Productos y Clientes de Crédito/Contado

## 🎯 Concepto General
Sistema donde cada cliente empresarial tiene su propio código único y puede gestionar su inventario y clientes independientemente.

## 📋 Flujo Principal del Sistema

### 1. **Pantalla de Bienvenida (Actual)**
- ✅ Usuario introduce código de 6 dígitos
- ✅ Sistema valida y accede a su "espacio" empresarial

### 2. **Base de Datos por Cliente**
```
Estructura de datos:
├── Cliente_123456/
│   ├── productos/
│   ├── clientes_credito/
│   ├── clientes_contado/
│   ├── facturas/
│   └── configuracion_empresa/
```

### 3. **Dashboard Principal Personalizado**
**Después del login con código:**
- Header: "Bienvenido [Nombre de Empresa] - Cliente: 123456"
- Métricas específicas del cliente:
  - Total productos en inventario
  - Clientes de crédito activos
  - Ventas del mes
  - Facturas pendientes de cobro

### 4. **Gestión de Productos (Mejorada)**
**Funcionalidades por cliente:**
- ✅ Agregar/editar/eliminar productos (actual)
- 🆕 **Precios diferenciados**: 
  - Precio contado
  - Precio crédito (con margen adicional)
- 🆕 **Categorización avanzada**
- 🆕 **Control de stock mínimo**
- 🆕 **Historial de movimientos por cliente**

### 5. **Gestión de Clientes (Nueva Funcionalidad)**

#### **5.1 Tipos de Clientes:**
**A) Clientes de Contado:**
- Datos básicos (nombre, teléfono)
- Sin límite de crédito
- Pago inmediato

**B) Clientes de Crédito:**
- Datos completos (nombre, dirección, referencias)
- Límite de crédito asignado
- Historial de pagos
- Estado: Activo/Suspendido/Moroso

#### **5.2 Pantallas de Clientes:**
```
📱 Pantalla "Mis Clientes"
├── Tabs: [Contado] [Crédito]
├── Lista con búsqueda
├── Botón: + Nuevo Cliente
└── Acciones: Ver historial, Editar, Estado
```

### 6. **Sistema de Facturación Avanzado**

#### **6.1 Proceso de Venta:**
1. **Seleccionar tipo de venta**: Contado | Crédito
2. **Seleccionar cliente** (nuevo o existente)
3. **Agregar productos** con precios automáticos según tipo
4. **Aplicar descuentos** (si aplica)
5. **Generar factura** con términos de pago
6. **Procesar pago** o **registrar crédito**

#### **6.2 Facturas de Contado:**
- Pago inmediato
- Descuento por pronto pago (opcional)
- Recibo de caja

#### **6.3 Facturas de Crédito:**
- Verificar límite disponible
- Términos de pago (15, 30, 60 días)
- Seguimiento de vencimientos
- Alertas de cobro

### 7. **Módulo de Cobranza (Nuevo)**
```
📊 Dashboard de Cobranza
├── Facturas por vencer (próximos 7 días)
├── Facturas vencidas
├── Clientes con mayor deuda
├── Reporte de cartera por antigüedad
└── Botones de acción rápida
```

### 8. **Reportes por Cliente**
- **Ventas**: Por período, por tipo de cliente
- **Inventario**: Movimientos, productos más vendidos
- **Cartera**: Antigüedad de saldos, clientes morosos
- **Rentabilidad**: Margen por producto/cliente

## 🛠️ Implementación Técnica

### **Estructura de Base de Datos:**
```sql
-- Tabla de códigos de cliente (maestra)
clientes_sistema (
  codigo_cliente VARCHAR(6) PRIMARY KEY,
  nombre_empresa VARCHAR(100),
  activo BOOLEAN
)

-- Cada cliente tiene sus propias tablas con prefijo
productos_123456 (...)
clientes_credito_123456 (...)
facturas_123456 (...)
```

### **Modificaciones de UI:**
1. **Navegación contextual** con código de cliente visible
2. **Colores/tema personalizable** por cliente
3. **Dashboard específico** con métricas relevantes
4. **Menú lateral expandido** con nuevas opciones

### **Nuevas Pantallas a Crear:**
1. `customer_management_screen.dart` - Gestión de clientes
2. `credit_customers_screen.dart` - Clientes a crédito
3. `cash_customers_screen.dart` - Clientes de contado  
4. `collection_dashboard_screen.dart` - Dashboard de cobranza
5. `advanced_invoice_screen.dart` - Facturación mejorada
6. `reports_screen.dart` - Reportes avanzados

## 🎯 Beneficios del Sistema

### **Para el Cliente Empresarial:**
- Gestión completa independiente
- Control de cartera de clientes
- Diferenciación de precios
- Reportes específicos
- Seguimiento de cobranza

### **Para ti (Proveedor del Sistema):**
- Escalabilidad multi-cliente
- Base de datos organizada
- Facturación recurrente potencial
- Datos centralizados para análisis

## 📱 Flujo de Usuario Mejorado

```
1. Login con código → 
2. Dashboard personalizado → 
3. Gestión separada de:
   ├── Productos (precios diferenciados)
   ├── Clientes contado/crédito
   ├── Facturación inteligente  
   ├── Seguimiento de cobranza
   └── Reportes específicos
```

## 🚀 Desarrollo por Fases

### **Fase 1: Fundación Multi-Cliente**
- [x] Pantalla de bienvenida con código
- [x] Escáner de códigos de barras
- [ ] Modificar base de datos para multi-cliente
- [ ] Dashboard personalizado
- [ ] Navegación contextual

### **Fase 2: Gestión de Clientes**
- [ ] Modelo de datos para clientes
- [ ] Pantalla gestión de clientes
- [ ] Diferenciación contado/crédito
- [ ] CRUD de clientes

### **Fase 3: Precios Diferenciados**
- [ ] Modificar modelo de productos
- [ ] Precios contado/crédito
- [ ] Interfaz para gestión de precios
- [ ] Lógica de aplicación automática

### **Fase 4: Facturación Avanzada**
- [ ] Sistema de selección de tipo de venta
- [ ] Verificación de límites de crédito
- [ ] Términos de pago
- [ ] Generación de facturas mejorada

### **Fase 5: Módulo de Cobranza**
- [ ] Dashboard de cobranza
- [ ] Alertas y notificaciones
- [ ] Seguimiento de vencimientos
- [ ] Reportes de cartera

### **Fase 6: Reportes y Analytics**
- [ ] Reportes por cliente
- [ ] Métricas de rendimiento
- [ ] Análisis de rentabilidad
- [ ] Exportación de datos