class ApiConfig {
  const ApiConfig._();

  // Host base del backend web usado por los servicios HTTP de la app.
  // Producción expone el backend en la IP estática 34.71.120.235 vía HTTP.
  static const String backendAuthority = '34.71.120.235';

  // API key para consultar Google Routes API desde el móvil.
  static const String googleRoutesApiKey =
      'AIzaSyD2nBzXx8kYDxeZsUyvA74PdRO3wpJ25nk';

  // POST /api/clientes
  // Registro de clientes enviado como application/json.
  static const String clientRegistrationPath = '/api/clientes';

  // POST /api/auth/login
  // Inicio de sesión enviado como application/json.
  static const String loginPath = '/api/auth/login';

  // POST /api/auth/account-type
  // Detección del tipo de cuenta por correo.
  static const String accountTypePath = '/api/auth/account-type';

  // POST /api/auth/forgot-password
  // Restablecimiento unificado de contraseña para cliente y taller.
  static const String forgotPasswordPath = '/api/auth/forgot-password';

  // POST /api/devices/fcm-token
  // Registro o actualización del token FCM del dispositivo móvil.
  static const String fcmTokenPath = '/api/devices/fcm-token';

  // GET /api/vehiculos
  // POST /api/vehiculos
  // PUT /api/vehiculos/{id}
  // DELETE /api/vehiculos/{id}
  // Registro y consulta de vehículos. Alta/edición usan multipart/form-data.
  static const String vehicleRegistrationPath = '/api/vehiculos';

  // POST /api/emergencias
  // Reporte de emergencias enviado como multipart/form-data con photos repetido
  // por imagen y audio opcional.
  static const String emergencyRegistrationPath = '/api/emergencias';

  // GET /api/workshops
  // Devuelve talleres con coordenadas para dibujar marcadores en el mapa.
  static const String workshopMapPath = '/api/workshops';
}
