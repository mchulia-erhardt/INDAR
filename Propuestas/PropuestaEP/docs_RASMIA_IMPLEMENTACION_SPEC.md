# RASMIA — Especificación de implementación (Backlog + reglas + entregables)
**Fecha:** 2026-03-31  
**Objetivo del documento:** servir como **única fuente de verdad** para que **Copilot Agent (VS Code)** implemente RASMIA en el repositorio de trabajo (back + front + scripts BD), apoyándose en las tablas existentes del esquema INDAR y cumpliendo las restricciones técnicas indicadas.

---

## 0) Contexto y premisa del proyecto

  es una herramienta web para **tramitar expedientes** de diferentes ámbitos y procedimientos, donde:

- Hay **partes comunes** entre expedientes (datos generales, interesados, documentación, estados, auditoría, etc.).
- Hay partes **específicas** por ámbito/procedimiento (datos técnicos).
- La configuración debe ser **dinámica**: desde gestión/administración se puede definir qué pantallas, componentes/campos y documentos se exigen.
- Debe existir **versionado**:
  - Si un expediente se inicia con una versión, **continúa con esa versión hasta su cierre** (cambios evolutivos).
  - Debe poder contemplarse (no necesariamente en MVP) el caso de **cambio reglamentario** con fecha de corte donde expedientes abiertos puedan migrar o forzarse (ver campo de “bloqueo/forzado de versión”).
- La implementación target: **Backend Java**, **Frontend Angular**, **BBDD Oracle**, con compatibilidad **Oracle 10g**.

Repositorio de referencia (modelo INDAR):  
- `mchulia-erhardt/INDAR`  
- Script base: `INDAR_BD/02_INDAR_create_tables.sql`  
- Esquemas: `ESQUEMA_INDAR_BBDD.md` y `ESQUEMA_RUIBK_BBDD.md`  
- Documentación funcional: `Análisis Funcional - RASMIA_v3.md` y ASIs adjuntos (EP y piloto AT, etc.)

---

## 1) Reglas no negociables (para Copilot Agent)

### 1.1 Oracle / BBDD
- **Compatibilidad Oracle 10g**:
  - NO usar `JSON_VALUE`, `IS JSON`, columnas virtuales, `IDENTITY`, `FETCH FIRST`, etc.
  - El JSON se almacenará como `CLOB` (validación de JSON se hará en Java si aplica).
- Límite de **30 caracteres máximo** en:
  - nombres de tablas, columnas, índices, constraints, secuencias
  - nombres de paquetes/funciones/procedimientos
  - nombres de variables PL/SQL
- **Tablespaces obligatorios**:
  - Tablas: `INDAR_DAT`
  - LOB (CLOB/BLOB): `INDAR_LOB`
  - Índices: `INDAR_IDX`
- Secuencias Oracle: **siempre `NOCACHE`**.
- Auditoría: preferir que la haga Oracle **por triggers** (BI/BU), evitando peso en Java.

### 1.2 Reutilización / coherencia con INDAR
- Reutilizar al máximo las tablas existentes del esquema INDAR, especialmente:
  - Catálogos y configuración: `INDAR_TM_*`, `INDAR_CONFIGURATION`
  - Versionado y formularios dinámicos: `INDAR_TM_COMPONENTES`, `INDAR_TM_VERSION_COMP`
  - Trámites y versiones: `INDAR_TM_TRAMITES`, `INDAR_TM_VERSION_TRAMITES`
  - Documentación por trámite: `INDAR_TM_TRAMITES_DOCUMENTOS`, `INDAR_TM_TIPOS_DOC`, `INDAR_TM_DOC_ESTADOS`
  - Pantallas/flujo: `INDAR_TM_PANTALLAS`, `INDAR_TM_VERSION_PANTALLAS`, `INDAR_TM_VERSION_PANTALLA_COMP`, `INDAR_TM_ESTADOS_FLUJOS`, `INDAR_TM_ESTADOS_EXPEDIENTE`
  - Expedientes y datos por componente: `INDAR_EXPEDIENTES`, `INDAR_EXPE_COMP_DATOS`
- No duplicar estructuras si basta con:
  - añadir columnas
  - añadir tablas auxiliares (históricos, documentos, auditoría, etc.)

### 1.3 Tecnologías
- Backend: Java + framework moderno (por defecto **Spring Boot**).
- Frontend: Angular moderno (por defecto **Angular 17/18**).
- Validaciones:
  - Front: validaciones UI
  - Back: validación final (incluye JSON en CLOB, reglas de negocio, etc.)
- Observabilidad/seguridad: mínimo viable con buenas prácticas (logs, errores estándar, etc.).

---

## 2) Principios funcionales (lo que debe cumplir el sistema)

### 2.1 Configuración dinámica por versión
- Una **versión de trámite** define:
  - pantallas del flujo
  - componentes por pantalla (y su orden)
  - documentos exigibles (obligatorios/opcionales; firmar/sellar)
  - transiciones de estado permitidas (eventos)
- La UI debe poder **renderizar** formularios dinámicos basados en configuración (`ESTRUCTURA_JSON`, `VALIDACION_DATOS`, etc.).

### 2.2 Congelación de versión por expediente
- Cuando se crea un expediente, se asigna una `ID_VERSION_TRAMITE`.
- Esa versión queda fija durante toda la vida del expediente.
- Los nuevos expedientes deben usar **la última versión activa/vigente**.

### 2.3 Estados + workflow
- Debe existir:
  - estado actual del expediente
  - histórico de cambios de estado
  - validación de transiciones según tabla de flujo
- Debe contemplarse ��pendiente de acción interesado / administración”, cancelado, trasladado, etc. (según análisis funcional).

### 2.4 Documentación
- Debe contemplarse:
  - definición de documentos por trámite/versión (ya existe como TM)
  - persistencia de documentos aportados en cada expediente
  - estados documentales (pendiente firma, firmado, sellado, etc.)
  - justificantes de registro (entrada/salida) como documentos especiales (en MVP, persistencia; integraciones externas por stubs)

---

## 3) Alcance MVP propuesto (en PRs pequeños)

> Copilot Agent debe crear PRs pequeños y autocontenidos.

### PR1 — BBDD: ampliación mínima para versionado/estados/documentos
Objetivo: dejar persistencia lista para motor y UI.

### PR2 — Backend: endpoints mínimos (expedientes + TM + estados)
Objetivo: API base para alta/consulta/detalle + transiciones.

### PR3 — Frontend: listado/detalle + renderer dinámico mínimo
Objetivo: UI mínima funcional con formularios dinámicos.

### PR4 — Documentos de expediente (UI + API + BD)
Objetivo: subir/listar/ver + estado documental + auditoría.

### PR5 — Piloto (uno de estos)
- Piloto EP (NIEP/MIEP/BEP o MEPEP/MEPCEP) **o**
- Piloto AT inspección periódica (según `202406 26 Piloto propuesto.md`)

---

## 4) Tareas detalladas (Backlog ejecutable por Copilot Agent)

### EPIC-01 — BBDD base RASMIA sobre INDAR (Oracle 10g)
**Meta:** soportar versionado congelado, workflow, histórico y documentos.

#### 01.1 Extender cabecera de expediente (`INDAR_EXPEDIENTES`)
- [ ] Añadir columna `ID_VERSION_TRAMITE` (FK a `INDAR_TM_VERSION_TRAMITES`) **NOT NULL** (si hay expedientes antiguos, definir default/control de migración).
- [ ] Asegurar estado actual:
  - O bien mantener `ESTADO` existente pero documentar su semántica,
  - o bien crear `ID_ESTADO_EXP` (FK a `INDAR_TM_ESTADOS_EXPEDIENTE`) y migrar.
- [ ] Añadir auditoría:
  - `FECHA_ULT_MOD` (DATE)
  - `USU_ULT_MOD` (VARCHAR2(50/100))
  - opcional: `FECHA_ALTA`, `USU_ALTA` si no existe
- [ ] Índices recomendados para búsqueda: estado, versión trámite, fechas.

> **Restricción**: nombres <=30 caracteres, índices en `INDAR_IDX`.

#### 01.2 Crear histórico de estados de expediente
- [ ] Crear tabla `INDAR_EXPE_EST_HIST` (nombre definitivo <=30)
  - PK numérica con secuencia `NOCACHE`
  - `ID_EXPEDIENTE` FK
  - `ID_ESTADO_ORI` / `ID_ESTADO_DST` (o `ID_ESTADO`)
  - `FECHA_CAMBIO`
  - `USUARIO_CAMBIO`
  - `MOTIVO` (varchar2 400-1000)
- [ ] Índice por `(ID_EXPEDIENTE, FECHA_CAMBIO)`.

#### 01.3 Persistencia de documentos por expediente
- [ ] Crear tabla `INDAR_EXPE_DOC` (o nombre <=30)
  - `ID_EXPE_DOC` PK + secuencia `NOCACHE`
  - `ID_EXPEDIENTE` FK
  - `ID_TRAMITE_DOC` FK a `INDAR_TM_TRAMITES_DOCUMENTOS` (si aplica)
  - `ID_TIPO_DOC` FK a `INDAR_TM_TIPOS_DOC` (si aplica)
  - `NOMBRE` / `DESCRIPCION`
  - `CSV` (varchar2 100)
  - `ID_ESTADO_DOC` FK a `INDAR_TM_DOC_ESTADOS`
  - flags: `FIRMADO`, `SELLADO` (NUMBER(1) o CHAR(1))
  - `FECHA_ALTA`, `FECHA_MOD`
  - `METADATA` CLOB (en `INDAR_LOB`) para info adicional (registro, firma, integraciones)
- [ ] Índices: `ID_EXPEDIENTE`, `ID_ESTADO_DOC`, `ID_TIPO_DOC`.

#### 01.4 Triggers de auditoría (Oracle)
- [ ] Trigger BI/BU para:
  - autocompletar `FECHA_ALTA/FECHA_MOD` y `USU_ALTA/USU_MOD` si aplica
- [ ] Trigger para insertar en histórico de estados al cambiar estado en `INDAR_EXPEDIENTES`.
- [ ] Trigger para histórico documental si se decide (opcional MVP):
  - cuando un documento se marca como borrado/reemplazado o cambia estado.

#### 01.5 Scripts y orden de ejecución
- [ ] Crear carpeta de scripts BD (si no existe) y un README de ejecución.
- [ ] Separar scripts:
  - `01_tables.sql`
  - `02_sequences.sql`
  - `03_indexes.sql`
  - `04_triggers.sql`
  - `05_grants.sql` (si corresponde)
- [ ] Manejo de “ya existe”:
  - capturar ORA-955 / ORA-01430 según tipo (tabla/columna)
- [ ] Confirmar uso de tablespaces: datos/índices/lob.

---

### EPIC-02 — Modelo de versionado y “vigencia”
**Meta:** seleccionar automáticamente versión vigente y congelarla.

- [ ] Revisar `INDAR_TM_VERSION_TRAMITES`:
  - Si faltan campos de vigencia: proponer extensión con `FEC_INI_VIG`, `FEC_FIN_VIG`, `ESTADO_VER`.
  - Si no se puede alterar TM en MVP, definir regla: “última versión activa por ID o fecha alta”.
- [ ] Implementar criterio de selección de versión para `crearExpediente()`:
  - por fecha y activo
  - fallback seguro si hay varias activas.

---

### EPIC-03 — Backend Java (API base)
**Meta:** API mínima que permita:
- alta/consulta/detalle de expedientes
- leer la configuración dinámica (TM)
- transición de estados con validación

#### 03.1 Endpoints de Expedientes
- [ ] `POST /api/expedientes`
  - input: ámbito, trámite, datos iniciales
  - asigna `ID_VERSION_TRAMITE` vigente
  - crea cabecera y estado inicial
- [ ] `GET /api/expedientes`
  - filtros: estado, ámbito, trámite, fechas, número expediente, provincia, etc.
- [ ] `GET /api/expedientes/{id}`
  - devuelve cabecera + estado + documentos + componentes guardados (de `INDAR_EXPE_COMP_DATOS`)
- [ ] `POST /api/expedientes/{id}/estado`
  - input: evento + estado destino + motivo
  - valida transición contra `INDAR_TM_ESTADOS_FLUJOS`
  - actualiza estado actual y registra histórico

#### 03.2 Endpoints de configuración dinámica (TM)
- [ ] `GET /api/tm/ambitos`
- [ ] `GET /api/tm/tramites?ambito=...`
- [ ] `GET /api/tm/tramites/{id}/versiones`
- [ ] `GET /api/tm/version-tramite/{id}/pantallas`
- [ ] `GET /api/tm/version-comp/{id}` (estructura + validación)
- [ ] `GET /api/tm/version-tramite/{id}/docs` (documentos requeridos)

#### 03.3 Persistencia de datos técnicos (JSON en CLOB)
- [ ] Usar `INDAR_EXPE_COMP_DATOS` como tabla base:
  - guardar un registro por `ID_EXPEDIENTE + ID_VERSION_COMP`
  - `DATOS_EXPEDIENTE_COMPONENTE` (CLOB)
- [ ] Añadir campos de auditoría en la tabla si es necesario (o triggers).

#### 03.4 Validación de JSON
- [ ] Implementar validación en Java (mínimo):
  - comprobar JSON bien formado
  - validar required/format/range con `VALIDACION_DATOS` (si existe)
  - devolver errores estructurados para UI

#### 03.5 Seguridad / usuario
- [ ] Propagar “usuario” a triggers:
  - estrategia A: variable de sesión / `DBMS_SESSION.SET_CONTEXT`
  - estrategia B: columna `USU_*` actualizada desde Java (si triggers no pueden inferir usuario)
- [ ] Autenticación: integrable (en MVP se puede dejar stub y usar usuario fijo de pruebas si es necesario).

---

### EPIC-04 — Front Angular (UI base)
**Meta:** UI mínima operativa con formularios dinámicos.

#### 04.1 Pantallas
- [ ] Login/entrada (si aplica)
- [ ] Listado de expedientes con filtros
- [ ] Alta expediente (selección ámbito/procedimiento/trámite)
- [ ] Detalle expediente:
  - wizard por pantallas (TM)
  - estado actual + acciones disponibles
  - pestaña documentación

#### 04.2 Renderer dinámico de componentes
- [ ] Renderizar desde `ESTRUCTURA_JSON`:
  - text, textarea
  - number
  - date
  - select (lista fija)
  - checkbox (sí/no)
  - multiselect (si aplica)
  - repetibles simples (arrays)
- [ ] Mapeo de valores a JSON final por componente
- [ ] Validación:
  - front para UX
  - errores del back mostrados por campo

---

### EPIC-05 — Documentación (flujo mínimo)
**Meta:** permitir aportar/gestionar documentos por expediente.

- [ ] UI para:
  - subir individual
  - subir en bloque (opcional MVP)
  - listar documentos aportados + estado + CSV
  - ver/descargar
- [ ] API para:
  - alta documento
  - cambio estado documento (firmado/sellado)
  - marcar como borrado (mantener histórico)
- [ ] Persistencia en `INDAR_EXPE_DOC` + triggers auditoría
- [ ] **No implementar integraciones reales** (SRT/SNT/SGA/CCSV) en MVP:
  - crear interfaces y stubs
  - dejar endpoints o servicios simulados si hace falta

---

### EPIC-06 — Workflow / acciones (motor mínimo)
**Meta:** que las acciones disponibles dependan de:
- estado actual
- rol/perfil
- transición configurada en TM

- [ ] Calcular acciones disponibles desde `INDAR_TM_ESTADOS_FLUJOS`.
- [ ] Soportar eventos enumerados (`EVENTO_ENUM`) con naming estable.
- [ ] Registrar trazabilidad de quién ejecuta la transición.

---

## 5) Pilotos (configuración inicial recomendada)

### Piloto A: EP Equipos a Presión (Comunicaciones)
Basado en:
- `ASI_EP_Ficha.md`
- `ASI_EP_Flujo_EITitularDGA.md`
- `ASI_EP_Flujo_DGA.md`
- `ASI_EP_AD.md`, `ASI_EP_OF.md`
- `ASI_EP_E0005b.md`

Objetivo piloto:
- Implementar alta y tramitación básica de:
  - NIEP / MIEP / BEP (E0005a)
  - opcional MEPEP / MEPCEP (E0005b, solo DGA)
- Documentos obligatorios según “requiere proyecto”.
- Flujo registrar / remitir / sellar / trasladar (integración real fuera; persistencia y estados dentro).

### Piloto B: AT inspección periódica (OC)
Basado en: `202406 26 Piloto propuesto.md`

Objetivo piloto:
- Alta expediente inspección
- Emplazamiento = ubicación + instalación
- 1 visita por expediente, estados: iniciado/planificado/pendiente firma/registrado/trasladado
- Documentos: acta firmada, otros, medidas provisionales
- Post-revisión por administración (estados de revisión)

---

## 6) Decisiones técnicas recomendadas (para implementación)

### 6.1 Modelo de datos técnicos
- Guardar datos técnicos como **JSON en CLOB** por componente en `INDAR_EXPE_COMP_DATOS`.
- Las definiciones (estructura/validación) viven en TM (`INDAR_TM_VERSION_COMP`).

### 6.2 Congelación de versión
- `INDAR_EXPEDIENTES.ID_VERSION_TRAMITE` fija al crear.
- Opcional: bandera `VER_BLOQ` para forzar no migración.

### 6.3 Auditoría
- Triggers para:
  - fechas y usuario
  - histórico estados
  - histórico documental (opcional)

---

## 7) Entregables obligatorios por PR

Cada PR debe incluir:
- Cambios de código/scripts + descripción clara del alcance.
- Documentación mínima de ejecución:
  - si es BD: orden de scripts
  - si es API: endpoints añadidos + ejemplo payload
  - si es front: rutas/pantallas y cómo probar
- Cumplimiento de restricciones:
  - Oracle 10g
  - nombres <=30 en BD
  - tablespaces correctos
  - secuencias NOCACHE

---

## 8) Checklist de control final (antes de merge)
- [ ] Ningún objeto BD supera 30 caracteres (tabla/columna/índice/constraint/secuencia).
- [ ] Todas las tablas en `INDAR_DAT`, índices en `INDAR_IDX`, LOBs en `INDAR_LOB`.
- [ ] Secuencias `NOCACHE`.
- [ ] No se han introducido features no compatibles con Oracle 10g.
- [ ] Congelación de versión funcionando (expedientes existentes no cambian de versión).
- [ ] Histórico de estados poblado por trigger/servicio.
- [ ] Renderer dinámico funcional con JSON en CLOB.
- [ ] API devuelve errores de validación consumibles por UI.

---

## 9) Instrucciones para Copilot Agent (cómo ejecutar)
1) Implementar en PRs pequeños (PR1, PR2, PR3...).
2) En cada PR:
   - no mezclar BD con UI si no es necesario
   - añadir pruebas mínimas donde sea viable
3) Si faltan rutas/carpetas del repo:
   - detectar estructura del repo primero
   - proponer convenciones (ej.: `/backend`, `/frontend`, `/db/scripts`)

---

## 10) Notas de compatibilidad y discrepancias detectadas
- En scripts INDAR actuales aparecen checks tipo `CLOB IS JSON` y uso de `JSON_VALUE`/virtual columns en algún punto del SQL proporcionado: **esto NO es Oracle 10g**.
- Para Oracle 10g:
  - JSON en CLOB se permite como texto
  - la validación “es JSON” debe hacerse en aplicación o mediante validaciones custom
  - evitar funciones JSON nativas

---

## 11) Definiciones mínimas (glosario)
- **Ámbito:** categoría reglamentaria (EP, AT, BT, etc.).
- **Tipo de procedimiento:** comunicación, inspección, autorización, aportación documental, cambio titular, etc.
- **Trámite:** acción concreta dentro del tipo (NIEP, MIEP, BEP...).
- **Versión de trámite:** versión de configuración del trámite (pantallas, docs, flujo).
- **Componente:** bloque reutilizable de datos (con `ESTRUCTURA_JSON`).
- **Pantalla:** agrupación ordenada de componentes dentro del flujo.
- **Expediente:** instancia tramitada que referencia una versión concreta.

---
Fin del documento.
