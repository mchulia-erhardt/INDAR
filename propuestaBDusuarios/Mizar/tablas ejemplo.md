# Modelo de permisos por versión y relación

Este documento describe cómo estructurar los permisos de la aplicación, vinculados a **roles/relaciones** y a **versiones de la aplicación**.

---

## Tabla: versiones
| ID Versión | Nombre Versión | Fecha Publicación | Descripción                  |
|------------|----------------|-------------------|------------------------------|
| 1          | v1.0           | 2025-01-01        | Versión inicial              |
| 2          | v1.1           | 2025-06-01        | Añade módulo de informes     |
| 3          | v2.0           | 2025-11-01        | Rediseño completo de permisos|

---

## Tabla: menus
| ID Menu | Nombre Menu   | Descripción                  |
|---------|---------------|------------------------------|
| 1       | Expedientes   | Gestión de expedientes       |
| 2       | Usuarios      | Administración de usuarios   |
| 3       | Informes      | Consultas y reportes         |

---

## Tabla: acciones
| ID Acción | Nombre Acción | Descripción                          |
|-----------|---------------|--------------------------------------|
| 1         | Crear         | Crear un expediente nuevo            |
| 2         | Firmar        | Firmar electrónicamente              |
| 3         | Guardar       | Guardar cambios                      |
| 4         | Editar        | Modificar expediente existente       |
| 5         | Remitir       | Enviar expediente a otra entidad     |
| 6         | Trasladar     | Trasladar expediente a otro usuario  |

---

## Opción A: Tabla normalizada
Cada permiso se guarda como un registro independiente.

### Tabla: permisos_relacion_version
| ID Tipo Relación | ID Versión | ID Menu | ID Acción |
|------------------|------------|---------|-----------|
| 1 (Administrativo) | 1        | 1       | 1 (Crear) |
| 1 (Administrativo) | 1        | 1       | 3 (Guardar) |
| 1 (Administrativo) | 1        | 1       | 4 (Editar) |
| 2 (Técnico)        | 1        | 1       | 2 (Firmar) |
| 2 (Técnico)        | 1        | 1       | 5 (Remitir) |
| 3 (Responsable)    | 1        | 1       | 6 (Trasladar) |
| 4 (Titular)        | 2        | 2       | 3 (Guardar) |
| 5 (Representante Legal) | 2   | 2       | 2 (Firmar) |
| 6 (Delegado)       | 3        | 1       | 5 (Remitir) |

---

## Opción B: Columna JSON/XML
Los permisos se guardan agrupados en una sola columna por relación y versión.

### Tabla: permisos_relacion_version (con JSON)
| ID Tipo Relación | ID Versión | Permisos JSON |
|------------------|------------|---------------|
| 1 (Administrativo) | 1        | `{ "expedientes": ["crear","guardar","editar"] }` |
| 2 (Técnico)        | 1        | `{ "expedientes": ["firmar","remitir"] }` |
| 4 (Titular)        | 2        | `{ "usuarios": ["guardar"] }` |
| 5 (Representante Legal) | 2   | `{ "usuarios": ["firmar"] }` |
| 6 (Delegado)       | 3        | `{ "expedientes": ["remitir"] }` |

---

## Comparativa
- **Tabla normalizada**: más registros, pero consultas SQL sencillas y auditables.  
- **Columna JSON/XML**: más compacto y flexible, ideal para APIs, pero requiere funciones específicas para consultar.  
- **Solución híbrida**: almacenar en JSON y expandir en vistas auxiliares para auditoría.

---

## Ejemplo práctico
- En **v1.0**, un Administrativo puede *crear, guardar y editar* expedientes.  
- En **v1.1**, un Técnico puede *firmar y remitir*.  
- En **v2.0**, un Titular puede *guardar datos en Usuarios* y un Representante Legal puede *firmar*.  


# Diagrama conceptual de entidades y relaciones

Este esquema muestra cómo se conectan las tablas del modelo.

---

## Entidades principales
- **maestros_usuarios**
  - ID Maestro (PK)
  - Razón social / Nombre
  - ID Tipo Maestro (FK → tipos_maestro)
  - Identificador (NIF/CIF/NIE/VAT)
  - Fecha Alta / Fecha Baja

- **tipos_maestro**
  - ID Tipo Maestro (PK)
  - Nombre Tipo Maestro
  - Descripción

---

## Usuarios y datos personales
- **datos_personales**
  - ID Datos (PK)
  - Nombre completo
  - Documento (DNI/NIE/Pasaporte)
  - Correo electrónico

- **usuarios_relacionados**
  - ID Usuario (PK)
  - ID Maestro (FK → maestros_usuarios)
  - ID Datos (FK → datos_personales)
  - ID Tipo Relación (FK → tipos_relacion)
  - Fecha Alta / Fecha Baja

- **tipos_relacion**
  - ID Tipo Relación (PK)
  - Nombre Tipo Relación
  - Descripción

---

## Permisos y versiones
- **versiones**
  - ID Versión (PK)
  - Nombre Versión
  - Fecha Publicación
  - Descripción

- **menus**
  - ID Menu (PK)
  - Nombre Menu
  - Descripción

- **acciones**
  - ID Acción (PK)
  - Nombre Acción
  - Descripción

- **permisos_relacion_version**
  - ID Tipo Relación (FK → tipos_relacion)
  - ID Versión (FK → versiones)
  - ID Menu (FK → menus)
  - ID Acción (FK → acciones)
  - (Opcional: columna JSON/XML con permisos agrupados)

---

## Relaciones clave
- Un **Maestro** puede ser Empresa, OCA o Titular (según `tipos_maestro`).  
- Un **Usuario Relacionado** se vincula a un Maestro y a sus **Datos Personales**.  
- Cada Usuario Relacionado tiene un **Tipo de Relación** (Administrativo, Técnico, Titular, etc.).  
- Los **Permisos** se definen por Tipo de Relación y Versión de la aplicación.  
- Los Permisos se aplican sobre **Menús** y **Acciones**.  

---

## Ejemplo: Juan López
- En `maestros_usuarios` aparece:
  - Como **Titular de inmueble** (Tipo Maestro = 3).
  - Como **Empresa autónoma** (Tipo Maestro = 1).
- En `usuarios_relacionados`:
  - Es **Titular** de su casa.
  - Es **Titular** de su empresa autónoma.
  - Es **Técnico** en OCA Norte.
- En `permisos_relacion_version`:
  - Como Técnico (v1.0) puede firmar y remitir expedientes.
  - Como Titular (v2.0) puede guardar datos en Usuarios.



# Pseudodiagrama de entidades y relaciones (estilo árbol)

## maestros_usuarios
├── ID Maestro
├── Razón social / Nombre
├── ID Tipo Maestro → (tipos_maestro)
├── Identificador (NIF/CIF/NIE/VAT)
├── Fecha Alta / Fecha Baja
│
├── Relacionado con:
│   └── usuarios_relacionados
│       ├── ID Usuario
│       ├── ID Maestro (FK → maestros_usuarios)
│       ├── ID Datos (FK → datos_personales)
│       ├── ID Tipo Relación (FK → tipos_relacion)
│       ├── Fecha Alta / Fecha Baja
│       │
│       └── datos_personales
│           ├── ID Datos
│           ├── Nombre completo
│           ├── Documento (DNI/NIE/Pasaporte)
│           └── Correo electrónico

---

## tipos_maestro
├── ID Tipo Maestro
├── Nombre Tipo Maestro
└── Descripción

## tipos_relacion
├── ID Tipo Relación
├── Nombre Tipo Relación
└── Descripción

---

## versiones
├── ID Versión
├── Nombre Versión
├── Fecha Publicación
└── Descripción

## menus
├── ID Menu
├── Nombre Menu
└── Descripción

## acciones
├── ID Acción
├── Nombre Acción
└── Descripción

---

## permisos_relacion_version
├── ID Tipo Relación (FK → tipos_relacion)
├── ID Versión (FK → versiones)
├── ID Menu (FK → menus)
├── ID Acción (FK → acciones)
└── (Opcional: columna JSON/XML con permisos agrupados)

---

# Ejemplo: Juan López
- En **maestros_usuarios**:
  - ID=3 → Titular de inmueble (Tipo Maestro = 3).
  - ID=4 → Empresa autónoma (Tipo Maestro = 1).
- En **usuarios_relacionados**:
  - ID=301 → Titular de inmueble (ID Maestro=3).
  - ID=302 → Titular de su empresa autónoma (ID Maestro=4).
  - ID=201 → Técnico en OCA Norte (ID Maestro=2).
- En **permisos_relacion_version**:
  - Como Técnico (v1.0) → puede firmar y remitir expedientes.
  - Como Titular (v2.0) → puede guardar datos en Usuarios.