<div align="center">

<img src="https://img.shields.io/badge/Flutter-3.44.4-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
<img src="https://img.shields.io/badge/Dart-3.12.2-0175C2?style=for-the-badge&logo=dart&logoColor=white" />
<img src="https://img.shields.io/badge/Supabase-2.x-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white" />
<img src="https://img.shields.io/badge/Estado-En%20Desarrollo-orange?style=for-the-badge" />

</div>

<br />

<div align="center">
  <h1>Abarrotería Pro</h1>
  <p><strong>Sistema de Administración y Punto de Venta para Tienda de Abarrotes</strong></p>
  <p>Flutter · Dart · Supabase · Firebase · Riverpod</p>
</div>

---

## Descripción General

**Abarrotería Pro** es una aplicación móvil (Android/iOS) de gestión integral para tiendas de abarrotes: punto de venta (POS), escaneo de códigos de barras con la cámara del celular, gestión de inventario, caja, reportes y analítica de negocio.

### Estado actual

Implementado y funcionando contra Supabase real: **EP-01** (autenticación y usuarios), **EP-02** (apertura de caja), **EP-03** (CRUD de productos, escaneo por cámara, import CSV, foto de producto) y **EP-04** (inventario, ajustes de stock, restock). El punto de venta (EP-05) está en desarrollo; el resto de épicas (gastos, cierre de caja, reportes, estadísticas, notificaciones) siguen pendientes — ver la tabla de [Pantallas](#pantallas) para el detalle.

### Roles del Sistema

| Rol | Descripción |
|-----|-------------|
| **AdminMaster (AM)** | Acceso completo: gestión de usuarios, productos, inventario, reportes y analítica |
| **Cajero (CAJ)** | Operativo de punto de venta: ventas, caja, gastos del turno |

---

## Arquitectura

El proyecto sigue **Clean Architecture** por features, con separación clara en capas:

```
lib/
├── core/
│   ├── constants/         # Constantes de la app
│   ├── errors/            # Manejo de errores (Failures)
│   ├── router/            # GoRouter con guards de rol
│   ├── theme/             # Design system (colores, tipografía)
│   ├── utils/             # Utilitarios generales
│   └── widgets/           # Widgets compartidos entre features
│
└── features/
    ├── auth/              # EP-01: Login, sesiones, roles
    ├── cash_register/     # EP-02: Apertura de caja
    ├── products/          # EP-03: CRUD productos, escaneo, import CSV, foto
    ├── inventory/         # EP-04: Stock, movimientos, restock
    ├── pos/               # EP-05: Punto de venta (en desarrollo)
    ├── dashboard/         # Dashboard AM y CAJ
    ├── users/             # Gestión de cajeros (AM)
    └── settings/          # Configuración de la app
```

Cada feature contiene su propia capa `data/` (models, datasources, repository impl), sin una carpeta `data/` compartida a nivel raíz — así se mantiene cada épica autocontenida. Las épicas EP-06 en adelante (gastos, cierre de caja, reportes, estadísticas, Bluetooth, notificaciones) todavía no tienen feature propia.

### Patrón por Feature

Cada feature sigue la estructura:

```
feature/
├── data/         # Models, datasources, repository impl
├── domain/       # Entities, repository interface, use cases
└── presentation/
    ├── pages/    # Screens
    ├── widgets/  # Componentes propios del feature
    └── providers/# Riverpod providers
```

---

## Stack Tecnológico

| Capa | Tecnología | Uso |
|------|-----------|-----|
| **UI** | Flutter 3.44 + Dart 3.12 | Interfaz multiplataforma |
| **Estado** | Riverpod 2.x + riverpod_generator | Gestión de estado reactivo |
| **Backend** | Supabase (PostgreSQL) | Base de datos + Auth + Storage + Realtime |
| **Auth** | Supabase Auth (JWT + RLS) | Roles por metadata |
| **DB Local** | Drift (SQLite) | Modo offline (dependencia instalada, sin integrar aún) |
| **Push** | Firebase Messaging (FCM) | Notificaciones push (dependencia instalada, sin integrar aún) |
| **Barcode** | mobile_scanner | Escáner por cámara (reemplaza la pistola Bluetooth del backlog original) |
| **PDF** | pdf + printing | Recibos y reportes |
| **Charts** | fl_chart | Gráficas y tendencias |
| **Navegación** | GoRouter | Rutas con guards de rol |
| **Código gen.** | freezed + build_runner | Modelos inmutables |

---

## Modelo de Base de Datos (Supabase)

```sql
users              -- Perfil de usuarios con rol (adminmaster | cajero)
products           -- Catálogo de productos con barcode, stock, precio
sales              -- Cabecera de ventas POS
sale_items         -- Ítems de cada venta
cash_registers     -- Turnos de caja (apertura → cierre)
cash_movements     -- Movimientos de efectivo del turno
expenses           -- Gastos registrados por cajero
stock_movements    -- Historial de entradas/salidas de inventario
daily_closings     -- Cuadres diarios con diferencias de caja
expense_categories -- Categorías de gasto configurables
```

---

## Épicas del Product Backlog

| # | Épica | US | SP | Sprint |
|---|-------|----|----|--------|
| EP-01 | Autenticación y Gestión de Usuarios | 7 | 31 | 1-2 |
| EP-02 | Apertura de Caja y Arqueo | 5 | 26 | 2-3 |
| EP-03 | CRUD de Productos | 8 | 42 | 3-4 |
| EP-04 | Gestión de Inventario y Stock | 5 | 28 | 4-5 |
| EP-05 | Flujo de Ventas (POS) | 9 | 55 | 5-7 |
| EP-06 | Control de Caja y Gastos | 6 | 32 | 7-8 |
| EP-07 | Cierre de Caja y Cuadres | 5 | 30 | 8-9 |
| EP-08 | Historial y Reportes | 6 | 35 | 9-10 |
| EP-09 | Estadísticas y Tendencias | 5 | 38 | 10-11 |
| EP-10 | Pistola Bluetooth de Códigos de Barras | 4 | 22 | 3 |
| EP-11 | Notificaciones y Alertas | 4 | 18 | 6 |
| EP-12 | Funcionalidades Sugeridas | 7 | 40 | 11-13 |
| **Total** | | **71** | **397** | **~13 Sprints** |

---

## Configuración del Proyecto

### Prerrequisitos

- [Flutter SDK](https://flutter.dev) ≥ 3.44.4
- [Dart SDK](https://dart.dev) ≥ 3.12.2
- Cuenta en [Supabase](https://supabase.com)
- Cuenta en [Firebase](https://firebase.google.com) (para push notifications)
- Android Studio / VS Code con extensión Flutter

### 1. Clonar el repositorio

```bash
git clone https://github.com/johan-850/SIstema_AS.git
cd SIstema_AS
```

### 2. Configurar variables de entorno

```bash
cp .env.example .env
# Edita .env con tus credenciales de Supabase
```

```env
SUPABASE_URL=https://xxxx.supabase.co
SUPABASE_ANON_KEY=your_anon_key
```

### 3. Configurar Firebase (opcional por ahora)

La dependencia de Firebase Messaging ya está en `pubspec.yaml`, pero todavía no está conectada a ningún flujo del código (EP-11, notificaciones push, sigue pendiente). Puedes omitir este paso hasta que esa épica se implemente:

1. Crea un proyecto en [Firebase Console](https://console.firebase.google.com)
2. Descarga `google-services.json` → `android/app/`
3. Descarga `GoogleService-Info.plist` → `ios/Runner/`

### 4. Instalar dependencias

```bash
flutter pub get
```

### 5. Generar código (Riverpod + Freezed + Drift)

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 6. Ejecutar la app

```bash
flutter run
```

---

## Migraciones SQL — Supabase

Ejecuta los scripts, **en orden**, en el **SQL Editor** de tu proyecto Supabase (no hay CLI de Supabase configurada en este repo, así que se aplican manualmente):

| Migración | Contenido |
|-----------|-----------|
| `supabase/migrations/001_ep01_auth_users.sql` | `profiles`, `user_activity_logs`, triggers de alta/último login, RLS por rol |
| `supabase/migrations/002_ep03_product_images_storage.sql` | Bucket `product-images` + políticas RLS para fotos de producto |
| `supabase/migrations/003_ep04_inventory.sql` | `stock_movements`, `restock_requests`, función atómica `adjust_product_stock`, Realtime sobre `products` |

Las tablas `products`, `cash_registers` y `stock_movements` referenciadas en el código de EP-02/EP-03 aún no tienen una migración formal previa (se asumen creadas manualmente desde el Dashboard) — es una deuda técnica conocida, no un olvido de este README.

---

## Seguridad y RLS

- Todas las tablas tienen **Row Level Security** habilitado
- Los cajeros solo acceden a datos de su propio turno activo
- Los AdminMasters tienen acceso completo vía policy `role = 'adminmaster'`
- Las políticas se basan en claims del JWT de Supabase Auth

---

## Pantallas

| Pantalla | Rol | US | Estado |
|---------|-----|----|--------|
| Login | AM / CAJ | US-001, US-002 | Listo |
| Dashboard Admin | AM | US-048 | Listo |
| Gestión de Cajeros | AM | US-003 → US-007 | Listo |
| Apertura de Caja | CAJ | US-008, US-009 | Listo |
| Catálogo de Productos (AM) | AM | US-013 → US-019 | Listo |
| Catálogo de solo lectura (CAJ) | CAJ | US-018 | Listo |
| Inventario y Stock | AM | US-020 → US-024 | Listo |
| Punto de Venta (POS) | CAJ | US-025 → US-033 | En desarrollo |
| Gastos de Turno | CAJ | US-034, US-035 | Pendiente |
| Cierre de Caja | CAJ | US-039 → US-042 | Pendiente |
| Historial de Ventas | AM | US-044 → US-049 | Pendiente |
| Estadísticas | AM | US-050 → US-054 | Pendiente |
| Configuración BT | AM/CAJ | US-055 → US-058 | Pendiente (se reemplazó por escaneo con cámara en US-013/US-018) |
| Centro de Alertas | AM | US-059 → US-062 | Pendiente |

---

## Roadmap de Sprints

| Sprint | Foco | SP |
|--------|------|----|
| S-01 | Auth completo y gestión de usuarios | 31 |
| S-02 | Apertura de caja y arqueo inicial | 24 |
| S-03 | Pistola BT + CRUD productos (AM) | 38 |
| S-04 | Catálogo completo + inventario | 38 |
| S-05 | POS básico (carrito y búsqueda) | 26 |
| S-06 | POS completo + alertas | 42 |
| S-07 | Gastos de caja | 21 |
| S-08 | Cierre de caja y cuadre | 29 |
| S-09 | Historial y reportes | 34 |
| S-10 | Estadísticas básicas | 24 |
| S-11 | Estadísticas avanzadas | 16 |
| S-12 | Mejoras sugeridas vol.1 | 29 |
| S-13 | Mejoras sugeridas vol.2 | 39 |

---

## Contribución

Este es un proyecto privado de desarrollo activo. El flujo real que se viene usando es una rama por épica:

1. Crea una rama desde `develop`: `git checkout -b epica_N`
2. Implementa las historias de usuario de esa épica (commits con formato `feat(epN): US-XXX - descripción`)
3. Crea un Pull Request hacia `develop` referenciando los US-ID incluidos

---

## Licencia

Todos los derechos reservados © 2026 — Abarrotería Pro

---

<div align="center">
  <sub>Desarrollado con Flutter & Supabase</sub>
</div>
