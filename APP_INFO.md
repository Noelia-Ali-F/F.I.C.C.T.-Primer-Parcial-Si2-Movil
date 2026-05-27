# Datos Importantes de la App

## Nombre
- `Taller ACB`

## Descripción
- Aplicación móvil Flutter para asistencia y emergencias vehiculares.

## Roles
- `Cliente`
- `Socio del Taller`
- `Administrador`

## Flujo principal del cliente
1. `Inicio de sesión`
2. `Reportar Emergencia`
3. `Confirma tu ubicación`
4. `Revisar y Enviar`
5. `Enviando emergencia`
6. `Emergencia registrada`

## Módulos principales
- `Login`
- `Registro de cliente`
- `Gestión de vehículos`
- `Reporte de emergencia`
- `Ubicación en mapa`
- `Resumen y envío de emergencia`

## Integración backend de vehículos
- `POST /api/vehiculos`
- `GET /api/vehiculos?client_id={id}`
- `PUT /api/vehiculos/{id}`
- `DELETE /api/vehiculos/{id}`

## Datos enviados en vehículos
- `client_id`
- `brand`
- `model`
- `year`
- `plate`
- `color`
- `is_primary`
- `photo` opcional

## Mensajes de login alineados con backend
- `401`: `Correo o contraseña incorrectos`
- `403`: `Cuenta suspendida`

## Navegación importante
- Las vistas autenticadas usan protección para que el botón físico no cierre sesión con una sola pulsación.
- En vistas raíz autenticadas, se requieren `2` pulsaciones para salir al login.

## Archivos clave
- `lib/screens/login_screen.dart`
- `lib/screens/client_home_screen.dart`
- `lib/screens/emergency_request_screen.dart`
- `lib/screens/emergency_review_screen.dart`
- `lib/screens/emergency_sending_screen.dart`
- `lib/screens/emergency_success_screen.dart`
- `lib/services/vehicle_service.dart`
- `lib/models/vehicle_models.dart`
- `lib/models/emergency_models.dart`

## Observaciones
- La carga de vehículos del cliente usa `client_id`.
- La foto de vehículos en `MIS VEHÍCULOS` sigue siendo local si no se conecta a backend para actualización.
- La vista de búsqueda de dirección usa geocodificación para mover el marcador en el mapa.
