# LetMeTalk (CAA)

Aplicación de **Comunicación Aumentativa y Alternativa (CAA)** desarrollada en **Flutter** con capa de datos CRUD en **API C# (.NET 8 + SQL Server)** e integración con los más de **9,000 pictogramas de ARASAAC**.

Inspirada en el concepto original creado por **AppNotize UG**.

## Estructura del proyecto

- `LetMeTalkApi/`: API Web ASP.NET Core 8.0 (`ConexionSQLServer`, `Controllers`, `Models`, `Database.sql`) con CRUD completo (`GET`, `POST`, `PUT`, `DELETE`) para **Categorías**, **Pictogramas** y **Frases rápidas**.
- `lib/main.dart` y `lib/src/`: Aplicación Flutter organizada con `models/`, `services/` (`app_services.dart`, `categoria_service.dart`, `pictograma_service.dart`, `frase_service.dart`, `arasaac_service.dart`, `tts_service.dart`), `screens/`, `widgets/` y `theme/`.

## Puesta en marcha

1. **Crear base de datos SQL Server**: ejecutar `LetMeTalkApi/Database.sql` en SQL Server (`DESKTOP-6VG3PNM\SQLEXPRESS`).
2. **Iniciar la API C#**:
   ```bash
   cd LetMeTalkApi
   dotnet run
   ```
   Swagger estará disponible en `http://localhost:5238/swagger`.
3. **Ejecutar la app Flutter**:
   ```bash
   flutter pub get
   flutter run
   ```

## Atribución

Pictogramas proporcionados por **ARASAAC** (https://arasaac.org) — Gobierno de Aragón, bajo licencia Creative Commons (BY-NC-SA).
