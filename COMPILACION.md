# Guia de Compilacion - sis_xray

Esta guia proporciona instrucciones detalladas para compilar la aplicacion Flutter `sis_xray` para diferentes plataformas.

---

## Requisitos Previos

### Flutter SDK

Asegurese de tener Flutter instalado y configurado:

```powershell
flutter --version
```

Si Flutter no esta instalado, descargue e instale desde:
- Windows: https://flutter.dev/docs/get-started/install/windows
- Linux: https://flutter.dev/docs/get-started/install/linux
- macOS: https://flutter.dev/docs/get-started/install/macos

### Verificar Configuracion

Ejecute el siguiente comando para verificar que todo este correctamente configurado:

```powershell
flutter doctor -v
```

Resuelva cualquier problema que aparezca marcado con una X roja.

---

## Configuracion de Endpoints de API

Antes de compilar, verifique que los endpoints de API esten correctamente configurados en:

**Archivo:** `lib/services/api_service.dart`

```dart
static const String _baseUrl = 'https://savings-nearly-wise-largest.trycloudflare.com';
```

### Para Desarrollo Local

Si desea usar servidores locales en lugar del tunel de Cloudflare, modifique la URL:

```dart
static const String _baseUrl = 'http://localhost:8000';
```

### Para Produccion

Asegurese de que la URL apunte a su servidor de produccion antes de compilar la version final.

---

## Compilacion para Android

### Opcion 1: Usar Script Automatizado (Recomendado)

```powershell
cd d:\PERSONAL\Git\x_ray_sis\flutter\sis_xray
.\build_android.bat
```

Este script generara:
- **APK** (para instalacion directa): `build\app\outputs\flutter-apk\app-release.apk`
- **App Bundle** (para Google Play): `build\app\outputs\bundle\release\app-release.aab`

### Opcion 2: Comandos Manuales

```powershell
# Limpiar builds anteriores
flutter clean

# Obtener dependencias
flutter pub get

# Compilar APK
flutter build apk --release

# Compilar App Bundle
flutter build appbundle --release
```

### Firmar el APK (Opcional - Para Produccion)

Para publicar en Google Play Store, necesita firmar la aplicacion:

1. **Crear keystore:**
   ```powershell
   keytool -genkey -v -keystore d:\PERSONAL\Git\x_ray_sis\flutter\sis_xray\android\app\upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. **Crear archivo de configuracion de firma:**
   
   Cree `android/key.properties`:
   ```properties
   storePassword=<password del keystore>
   keyPassword=<password de la key>
   keyAlias=upload
   storeFile=upload-keystore.jks
   ```

3. **Configurar build.gradle:**
   
   Edite `android/app/build.gradle` y agregue antes de `android {`:
   ```gradle
   def keystoreProperties = new Properties()
   def keystorePropertiesFile = rootProject.file('key.properties')
   if (keystorePropertiesFile.exists()) {
       keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
   }
   ```

   Dentro de `buildTypes`, modifique `release`:
   ```gradle
   signingConfig signingConfigs.release
   ```

   Y agregue antes de `buildTypes`:
   ```gradle
   signingConfigs {
       release {
           keyAlias keystoreProperties['keyAlias']
           keyPassword keystoreProperties['keyPassword']
           storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
           storePassword keystoreProperties['storePassword']
       }
   }
   ```

---

## Compilacion para Windows

### Opcion 1: Usar Script Automatizado (Recomendado)

```powershell
cd d:\PERSONAL\Git\x_ray_sis\flutter\sis_xray
.\build_windows.bat
```

El ejecutable se generara en:
```
build\windows\x64\runner\Release\xray_sis_project.exe
```

### Opcion 2: Comandos Manuales

```powershell
# Limpiar builds anteriores
flutter clean

# Obtener dependencias
flutter pub get

# Compilar para Windows
flutter build windows --release
```

### Distribuir la Aplicacion Windows

Para distribuir la aplicacion, debe copiar **toda la carpeta Release** que contiene:
- `xray_sis_project.exe` (ejecutable principal)
- `data\` (carpeta con recursos)
- Archivos `.dll` (bibliotecas necesarias)

**NO** distribuya solo el archivo .exe, ya que no funcionara sin sus dependencias.

### Crear Instalador (Opcional)

Puede usar herramientas como:
- **Inno Setup**: https://jrsoftware.org/isinfo.php
- **NSIS**: https://nsis.sourceforge.io/
- **Advanced Installer**: https://www.advancedinstaller.com/

---

## Compilacion para Linux

### Requisitos Adicionales para Linux

```bash
sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev
```

### Opcion 1: Usar Script Automatizado (Recomendado)

```bash
cd /d/PERSONAL/Git/x_ray_sis/flutter/sis_xray
chmod +x build_linux.sh
./build_linux.sh
```

El ejecutable se generara en:
```
build/linux/x64/release/bundle/xray_sis_project
```

### Opcion 2: Comandos Manuales

```bash
# Limpiar builds anteriores
flutter clean

# Obtener dependencias
flutter pub get

# Compilar para Linux
flutter build linux --release
```

### Distribuir la Aplicacion Linux

Para distribuir, copie **toda la carpeta bundle** que contiene:
- `xray_sis_project` (ejecutable principal)
- `data/` (carpeta con recursos)
- `lib/` (bibliotecas necesarias)

### Crear Paquete .deb (Opcional)

Puede crear un paquete Debian usando herramientas como `dpkg-deb`.

---

## Compilacion para Todas las Plataformas

En Windows, puede usar el script maestro para compilar Android y Windows simultaneamente:

```powershell
cd d:\PERSONAL\Git\x_ray_sis\flutter\sis_xray
.\build_all.bat
```

---

## Ubicaciones de Archivos Generados

### Android
```
build/app/outputs/flutter-apk/app-release.apk
build/app/outputs/bundle/release/app-release.aab
```

### Windows
```
build/windows/x64/runner/Release/xray_sis_project.exe
build/windows/x64/runner/Release/data/
build/windows/x64/runner/Release/*.dll
```

### Linux
```
build/linux/x64/release/bundle/xray_sis_project
build/linux/x64/release/bundle/data/
build/linux/x64/release/bundle/lib/
```

---

## Solucion de Problemas

### Error: "Flutter no esta instalado"

**Solucion:**
- Verifique que Flutter este instalado
- Agregue Flutter al PATH del sistema
- Reinicie la terminal/PowerShell

### Error: "Gradle build failed" (Android)

**Solucion:**
- Verifique que Java JDK este instalado
- Limpie el proyecto: `flutter clean`
- Elimine la carpeta `android/.gradle` y vuelva a compilar

### Error: "CMake not found" (Windows/Linux)

**Solucion:**
- Instale Visual Studio con "Desktop development with C++" (Windows)
- Instale cmake: `sudo apt-get install cmake` (Linux)

### Error: "Unable to locate Android SDK"

**Solucion:**
- Instale Android Studio
- Configure ANDROID_HOME en las variables de entorno
- Ejecute `flutter doctor` y siga las instrucciones

### La aplicacion no se conecta a los microservicios

**Solucion:**
- Verifique que la URL en `api_service.dart` sea correcta
- Si usa localhost, asegurese de que los servicios esten ejecutandose
- En dispositivos fisicos, use la IP de su computadora en lugar de localhost
- Verifique que el firewall no este bloqueando las conexiones

---

## Optimizaciones de Compilacion

### Reducir Tamano del APK

```powershell
flutter build apk --release --split-per-abi
```

Esto genera APKs separados para cada arquitectura (arm64-v8a, armeabi-v7a, x86_64).

### Compilacion con Ofuscacion (Seguridad)

```powershell
flutter build apk --release --obfuscate --split-debug-info=./debug-info
```

Esto ofusca el codigo Dart para dificultar la ingenieria inversa.

---

## Notas Importantes

1. **Configuracion de API**: Siempre verifique que las URLs de API sean correctas antes de compilar para produccion.

2. **Permisos de Android**: La aplicacion requiere permisos de camara y almacenamiento. Estos estan configurados en `android/app/src/main/AndroidManifest.xml`.

3. **Firma de Aplicaciones**: Para publicar en tiendas oficiales (Google Play, Microsoft Store), debe firmar las aplicaciones.

4. **Pruebas**: Siempre pruebe los ejecutables en dispositivos reales antes de distribuir.

5. **Versionado**: Actualice la version en `pubspec.yaml` antes de cada compilacion de produccion:
   ```yaml
   version: 1.0.0+1
   ```

---

## Recursos Adicionales

- Documentacion oficial de Flutter: https://flutter.dev/docs
- Publicar en Google Play: https://flutter.dev/docs/deployment/android
- Compilacion para Windows: https://flutter.dev/docs/deployment/windows
- Compilacion para Linux: https://flutter.dev/docs/deployment/linux

---

Para soporte adicional, contacte a: **th3alb0@protonmail.com**
