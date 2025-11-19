# Arquitectura Correcta para Gestión de Usuarios, Roles y Representantes

## 1. Introducción
Este documento describe la forma más correcta y escalable para gestionar usuarios, roles y representantes en una aplicación **Spring Boot** con base de datos **Oracle 19c** y un frontend en Angular (aunque aquí nos centramos en backend y base de datos). El objetivo es evitar duplicidad de datos, garantizar integridad y permitir crecimiento futuro.

---

## 2. Problemas Detectados en la Arquitectura Actual
- **Duplicidad de datos personales**: Usuarios repetidos en distintos perfiles.
- **Roles fijos acoplados a tipos de usuario**: Dificultad para añadir nuevos roles.
- **Falta de normalización**: Representantes duplican información del usuario principal.
- **Escalabilidad limitada**: Cambios en perfiles implican modificaciones complejas.

---

## 3. Objetivos
- Un único registro por usuario principal (Titular, Empresa, OCA).
- Representantes independientes, referenciando al usuario principal.
- Roles desacoplados del tipo de usuario.
- Diseño normalizado y preparado para permisos granulares.
- Backend modular y mantenible.

---

## 4. Diseño de Base de Datos

### 4.1 Entidades Principales
- **users**: Datos únicos del usuario principal.
- **roles**: Roles fijos (SERVICIO_PROVINCIAL, TRAMITADOR, JEFE_SECCION, etc.).
- **user_roles**: Relación Many-to-Many entre usuarios y roles.
- **representantes**: Representantes asociados a un usuario principal.

### 4.2 Diagrama Conceptual (Texto)
```
users (id, username, email, password, tipo_usuario, nombre, apellidos, documento)
roles (id, nombre)
user_roles (user_id, role_id)
representantes (id, nombre, apellidos, documento, user_id)
```
Relaciones:
- users ↔ roles: Many-to-Many.
- users ↔ representantes: One-to-Many.

### 4.3 Consideraciones
- **tipo_usuario**: ENUM (TITULAR, EMPRESA, OCA).
- Si cada tipo tiene atributos específicos, usar **herencia JPA** (`@Inheritance(strategy = JOINED)`).
- Constraints para evitar duplicidad de documentos.

---

## 5. Arquitectura Backend (Spring Boot)

### 5.1 Módulos
- **Módulo de Autenticación**: Spring Security + JWT/OAuth2.
- **Módulo de Gestión de Usuarios**: CRUD usuarios principales + roles.
- **Módulo de Representantes**: CRUD representantes, referenciando `user_id`.

### 5.2 Buenas Prácticas
- **DTOs y MapStruct**: Evitar exponer entidades directamente.
- **Validaciones**: Bean Validation para datos personales.
- **Migraciones**: Flyway o Liquibase para versionado.
- **Multi-DB**: Solo si es estrictamente necesario; preferible un solo esquema normalizado.

---

## 6. Recomendación Final
- **Una sola base de datos** con diseño normalizado.
- **Roles desacoplados** del tipo de usuario.
- **Representantes referenciados** sin duplicar datos del usuario principal.
- **Backend modular** con servicios separados.
- Preparar la arquitectura para permisos granulares y herencia si los tipos de usuario crecen.

Esta solución es escalable, mantenible y preparada para futuras integraciones.


---

## 7. Resolución de Problemas Detectados
### Problema 1: Duplicidad de datos personales
**Solución:** Un único registro por usuario principal en la tabla `users`. Representantes referenciados mediante `user_id`.

### Problema 2: Roles acoplados a tipos de usuario
**Solución:** Roles en tabla independiente (`roles`) con relación Many-to-Many. Tipos de usuario gestionados por ENUM o herencia JPA.

### Problema 3: Falta de normalización
**Solución:** Diseño relacional con claves foráneas y constraints. Evitar columnas vacías mediante herencia.

### Problema 4: Escalabilidad limitada
**Solución:** Arquitectura modular en backend, migraciones con Flyway, y posibilidad de añadir permisos granulares.

---

## 8. Diagramas Conceptuales

### 8.1 Diagrama ER (Texto)
```
[USERS] ---< [USER_ROLES] >--- [ROLES]
   |
   |---< [REPRESENTANTES]
```

### 8.2 Arquitectura Lógica Backend
```
+-------------------+
|  API REST (Spring)|
+-------------------+
        |
        v
+-------------------+
| Service Layer     |
+-------------------+
        |
        v
+-------------------+
| Repository Layer  |
+-------------------+
        |
        v
+-------------------+
| Oracle 19c DB     |
+-------------------+
```

---

## 9. Ventajas y Desventajas

### Ventajas
- **Escalabilidad:** Fácil añadir roles, permisos y nuevos tipos de usuario.
- **Mantenibilidad:** Código modular y base de datos normalizada.
- **Integridad:** Evita duplicidad y garantiza consistencia.
- **Compatibilidad:** Preparado para integrarse con Spring Security y JWT.

### Desventajas
- **Complejidad inicial:** Requiere diseño cuidadoso y migraciones.
- **Curva de aprendizaje:** Herencia JPA y relaciones Many-to-Many pueden ser complejas.
- **Sobrecarga en validaciones:** Necesario implementar reglas para evitar inconsistencias.

---

## 10. Recomendación Final
La arquitectura propuesta es la opción más correcta para garantizar escalabilidad, mantenibilidad y consistencia. Aunque implica mayor esfuerzo inicial, reduce problemas futuros y facilita la evolución del sistema.


---

## 11. ¿Por qué esta arquitectura es la más correcta?

### 11.1 Normalización de Datos
La normalización evita duplicidad y garantiza integridad referencial. En tu caso, tener un único registro por usuario principal y referencias para representantes elimina inconsistencias y facilita actualizaciones. Si un titular cambia su documento, se actualiza en un solo lugar.

### 11.2 Roles Desacoplados
Separar roles del tipo de usuario permite flexibilidad. Hoy tienes roles fijos, pero mañana podrías necesitar permisos granulares o nuevos roles. Con una tabla independiente y relación Many-to-Many, no necesitas modificar la estructura para añadir roles.

### 11.3 Herencia JPA
Si los tipos de usuario (Titular, Empresa, OCA) tienen atributos específicos, usar herencia JPA (`@Inheritance(strategy = JOINED)`) evita columnas vacías y mantiene la base normalizada. Esto es más limpio que tener una sola tabla con muchas columnas opcionales.

### 11.4 Modularidad en Backend
Separar servicios (usuarios, roles, representantes) permite escalabilidad y mantenibilidad. Cada módulo puede evolucionar sin afectar a los demás. Además, facilita la integración con Spring Security para autenticación y autorización.

### 11.5 Preparación para el Futuro
Esta arquitectura soporta:
- Permisos granulares (añadiendo tabla `permissions`).
- Multi-tenancy si el sistema crece.
- Integración con OAuth2/JWT para autenticación distribuida.

En resumen, esta solución equilibra simplicidad inicial con capacidad de crecimiento.