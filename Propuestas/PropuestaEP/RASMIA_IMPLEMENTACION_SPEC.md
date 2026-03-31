# RASMIA – Especificación de Implementación (EP)

## Contexto y aclaraciones previas

- **Evolución de INDAR**: el nuevo desarrollo es un **nuevo trámite** dentro del sistema INDAR.
- **Esquema objetivo**: `INDAR_OWN`.
- **Oracle**: versión real ≈ **19c**, con **compatibilidad hacia 10g** (evitar features modernas donde sea posible). Dado que el esquema actual ya usa `IS JSON` y `JSON_VALUE`, se permite continuar usando dichas características.

---

## 1) Decisión base: "Catálogo + Versionado + Ejecución (runtime)"

Para que un expediente iniciado con una versión siga con ella, el sistema debe separar claramente:

1. **Definición (catálogo)**: qué es el trámite, qué pantallas tiene, qué campos, qué docs, qué reglas.
2. **Versión**: snapshot inmutable de esa definición (v1, v2, …).
3. **Ejecución**: expediente concreto con sus datos, documentos, estados y auditoría.

---

## 2) Ámbito EP: Alta nueva instalación (NIEP – Comunicación)

### Particularidades del ámbito EP

- **1 instalación por expediente EP**, pero la instalación contiene **N equipos** (y en MIEP se pueden añadir/bajar equipos).
- En el **alta** no se busca instalación directamente: se busca **Ubicación** (hoy contra INDAR, a futuro contra RUI).
- Integración con **SRT/SNT/SGA/CCSV** sí o sí.
- Roles existentes sí (aprovechar `INDAR_TM_TIPOS_RELACION`).
- Generación de IDs y códigos: **en BD (Oracle)** con secuencias + triggers.

### Modelo funcional mínimo para EP – NIEP (Comunicación)

**Pestañas/pantallas típicas (base)**

1. Datos expediente (ámbito=EP, trámite=NIEP, requiere proyecto SI/NO, interesado/notificaciones, etc.)
2. Instalación (búsqueda por Ubicación en INDAR/RUI; creación si no existe)
3. Agentes (empresa instaladora + proyectista/director técnico si requiere proyecto)
4. Documentación (subida, firma, registro SRT, sellado, traslado…)

**Reglas principales**

- Requiere instalación (sí).
- La documentación obligatoria depende de "requiere proyecto" (y de trámite).
- El flujo cambia según si se aportan docs por CSV/REGFIA o por subida normal y registro.
- En sellado/traslado se generan números (expediente DGA / instalación / etc.) y se consolidan en RUI.

---

## 3) Arquitectura propuesta (alto nivel)

### 3.1. Capas/módulos

**Backend (Java, última LTS + Spring Boot)**

- `core-auth`: integración MFE / perfiles / permisos (reutilizando tablas actuales INDAR).
- `core-catalog`: maestros de ámbitos, tipos procedimiento, trámites, versiones, pantallas, componentes, docs.
- `core-exp`: expedientes runtime (crear, consultar, guardar datos, histórico, asignaciones).
- `core-wf`: motor de workflow (estados, transiciones, acciones, roles).
- `int-rui`: integración con RUI (búsquedas de ubicación/instalación/equipos, traslado).
- `int-reg`: integración SRT/SNT/SGA.
- `int-ccsv`: expediente electrónico y metadatos/documentos CCSV.
- `docs`: gestión documental (metadatos, binarios, estados, firma/sello).

**Front (Angular última estable)**

- `shell`: entrada única, bandejas, buscadores.
- `expediente-ui`: renderer por pantallas + componentes (dinámico).
- `catalog-admin-ui`: administración de catálogos/versiones.
- `docs-ui`: subida, CSV REGFIA, firmar, registrar, sellar, justificantes, resumen.

**BD Oracle (INDAR_OWN)**

- Reutilizar lo existente (usuarios, permisos, configuración).
- Añadir "catálogo de trámites versionado + runtime expedientes" con JSON en CLOB.
- 3 tablespaces: `INDAR_DAT`, `INDAR_LOB`, `INDAR_IDX`.
- Nombres ≤ 30 chars.
- Secuencias: **NOCACHE**.
- Auditoría: triggers.

---

## 4) Modelo de datos (INDAR_OWN)

### 4.1. Catálogo versionado

Tablas (nombres ≤ 30 chars):

| Tabla | Descripción |
|---|---|
| `TM_AMBITO` | Ámbitos (EP, …) |
| `TM_TIPO_PROC` | Tipos de procedimiento (COMUNICACION, INSPECCION, AD, …) |
| `TM_TRAM` | Trámite lógico (EP.NIEP) |
| `TM_TRAM_VER` | Snapshot del trámite (vigencia/estado; **clave de versionado**) |
| `TM_COMP` | Catálogo de componentes reutilizables |
| `TM_COMP_VER` | Snapshot de componente (`ESTRUCT_JSON`, `VALID_JSON` como CLOB) |
| `TM_PANT` | Pantallas |
| `TM_PANT_VER` | Snapshot de pantalla |
| `TM_PANT_VER_COMP` | Composición pantalla-componentes (orden, reglas de visibilidad) |
| `TM_DOC_TIPO` | Tipos documentales |
| `TM_TRAM_VER_DOC` | Docs obligatorios/condiciones por versión de trámite |
| `TM_EST_EXP` | Estados de expediente |
| `TM_ACCION` | Acciones |
| `TM_TRANS` | Transiciones (por tipo procedimiento o versión de trámite) |

**Clave de versionado**: todo lo runtime referencia `TM_TRAM_VER`.

### 4.2. Runtime (expediente en ejecución)

**A) Expediente – `EXP`**

| Campo | Descripción |
|---|---|
| `ID_EXP` | PK (secuencia) |
| `COD_EXP` | Código legible (EP######YY); generado en BD |
| `ID_TRAM_VER` | FK → versión del trámite bloqueada al crear |
| `EST_ACT` | Estado actual |
| `ID_PROV` | Provincia (relevante en EP) |
| `ORIGEN` | INDAR/RASMIA/DIGITA/… |
| `VER_BLOQ` | S/N (por defecto S) |
| `FEC_ALTA`, `USR_ALTA`, `FEC_MOD`, `USR_MOD` | Auditoría (triggers) |

**B) Relación con Ubicación – `EXP_UBI`**

| Campo | Descripción |
|---|---|
| `ID_EXP_UBI` | PK |
| `ID_EXP` | FK → EXP |
| `ID_UBI_REF` | ID interno INDAR (hoy) / ID RUI (futuro) |
| `UBI_SRC` | INDAR / RUI |
| `UBI_JSON` | CLOB snapshot datos de ubicación |

> En alta se busca **Ubicación** (sobre `INDAR_UBICACION`; a futuro sobre RUI).  
> `INDAR_UBICACION` tiene su propio `INDAR_EMPLAZAMIENTO`.

**C) Instalación – `EXP_INST`**

| Campo | Descripción |
|---|---|
| `ID_EXP_INST` | PK |
| `ID_EXP` | FK → EXP |
| `ID_INST_REF` | FK → `INDAR_INSTALACION` (si ya existe) |
| `INST_SRC` | INDAR / RUI |
| `INST_JSON` | CLOB snapshot mínimo de instalación |

**D) Datos dinámicos por componente – `EXP_COMP_DAT`**

| Campo | Descripción |
|---|---|
| `ID_EXP_COMP_DAT` | PK |
| `ID_EXP` | FK → EXP |
| `ID_COMP_VER` | FK → TM_COMP_VER |
| `DATOS_JSON` | CLOB JSON (con `IS JSON`) |

- Unique: (`ID_EXP`, `ID_COMP_VER`)
- Índices por `ID_EXP`, `ID_COMP_VER` en `INDAR_IDX`
- CLOBs en `INDAR_LOB`

**E) Documentos – `EXP_DOC`**

| Campo | Descripción |
|---|---|
| `ID_EXP_DOC` | PK |
| `ID_EXP` | FK → EXP |
| `ID_TIPO_DOC` | FK → TM_DOC_TIPO |
| `EST_DOC` | Estado del documento |
| `CSV`, `ID_SRT`, `ID_SNT`, `HASH`, `NOMBRE` | Metadatos |

**F) Histórico de estados – `EXP_EST_HIST`**

| Campo | Descripción |
|---|---|
| `ID_HIST` | PK |
| `ID_EXP` | FK → EXP |
| `ESTADO` | Estado registrado |
| `FEC_EST` | Fecha |
| `USR` | Usuario |
| `MOTIVO` | Motivo del cambio |

### 4.3. Particularidad EP: equipos dentro de instalación

EP no tiene "N instalaciones por expediente" pero sí **N equipos por instalación** (→ `INDAR_EQUIPO`).

**Tabla `EXP_EP_EQUIPO`** (híbrido relacional + JSON):

| Campo | Descripción |
|---|---|
| `ID_EXP_EP_EQ` | PK |
| `ID_EXP` | FK → EXP |
| `EQ_TIPO` | RECIPIENTE/CALDERA/TUBERIA/… |
| `EQ_NUM` | AAUUXXXX (asignado en sellado/traslado) |
| `EQ_EST` | ALTA/BAJA |
| `FEC_BAJA` | Fecha de baja lógica |
| `EQ_JSON` | CLOB snapshot del equipo |

**Tabla contadora `EP_EQ_CONT`** (para numeración segura):

| Campo | Descripción |
|---|---|
| `ANIO` | Año |
| `PROV_COD` | Código de provincia |
| `ULT_NUM` | Último número asignado |

> La asignación usa `SELECT … FOR UPDATE` en PL/SQL para garantizar correlativos únicos.

**Flujo de numeración por uso de trámite**:

- **NIEP**: crear instalación + declarar N equipos (sin número) → al sellar/trasladar se asigna `EQ_NUM`.
- **MIEP**: cargar equipos existentes + permitir añadir/bajar.
- **MEPEP/MEPCEP**: trabajar sobre 1 equipo obligatoriamente existente.

### 4.4. Tablespaces, secuencias y auditoría

| Elemento | Tablespace / Norma |
|---|---|
| Tablas | `INDAR_DAT` |
| Índices | `INDAR_IDX` |
| CLOBs | `LOB (col) STORE AS (TABLESPACE INDAR_LOB …)` |
| Secuencias | `NOCACHE` |
| Nombres | ≤ 30 chars |

**Auditoría por triggers** (en tablas runtime):
- INSERT → `FEC_ALTA`, `USR_ALTA`
- UPDATE → `FEC_MOD`, `USR_MOD`

---

## 5) Versionado: garantizar "si se inició con V1, sigue con V1"

- `EXP.ID_TRAM_VER` + `VER_BLOQ='S'` fijan la versión en el momento de alta.
- El front **nunca** pide "definición por trámite", siempre pide "definición por expediente":
  - `GET /exp/{id}/ui-def` → backend resuelve `ID_TRAM_VER` y devuelve pantallas/componentes/docs de esa versión.
- Cambios reglamentarios (si algún día se necesitan): `TM_TRAM_VER` con `FEC_INI_VIG` y `MODO_MIG` (N/S) + proceso de migración.

---

## 6) Workflow para Comunicación EP (NIEP)

### Estados

| Estado | Descripción |
|---|---|
| `BORRADOR` | Expediente en edición |
| `PEND_FIRMA` | Pendiente de firma de documentos |
| `PEND_REG` | Pendiente de registro (si no viene por CSV REGFIA) |
| `PEND_SELL` | Pendiente de sellado orgánico |
| `PEND_TRAS_RUI` | Pendiente de traslado a RUI |
| `TRAS_RUI` | Trasladado a RUI |
| `DEVUELTO` | Devuelto al interesado/EI |
| `CANCEL` | Cancelado |

### Acciones

| Acción | Descripción |
|---|---|
| `GUARDAR` | Guardar estado borrador |
| `FIRMAR_DOC` | Firma de documento/lote |
| `REGISTRAR_ENT` | Registro de entrada (SRT) |
| `SELLAR` | Sello órgano (genera números si corresponde) |
| `TRAS_RUI` | Traslado a RUI (doc resumen + CCSV EE) |
| `DEVOLVER` | Devolución con motivo |
| `CANCELAR` | Cancelación (con reglas sobre borrado docs) |
| `REASIGNAR` | Reasignación de expediente |

Las transiciones son parametrizables en `TM_TRANS` por versión de trámite.

---

## 7) Buscador de Ubicaciones (hoy INDAR, mañana RUI)

- `GET /ubis/search?…`:
  - implementación actual: consulta en `INDAR_UBICACION` / `INDAR_EMPLAZAMIENTO`.
  - implementación futura: llamada al módulo `int-rui`; el backend unifica la respuesta.
- Se guarda en `EXP_UBI`:
  - `UBI_SRC='INDAR'` (o `'RUI'` en el futuro) + `ID_UBI_REF` + snapshot `UBI_JSON`.

---

## 8) Backend Java: APIs principales

| Método | Endpoint | Descripción |
|---|---|---|
| GET | `/tramites?ambito=EP` | Listar trámites del ámbito |
| GET | `/tramites/{id}/versiones` | Listar versiones de un trámite |
| GET | `/tramites/{id}/version-activa` | Obtener versión activa |
| POST | `/expedientes` | Crear expediente (fija `ID_TRAM_VER` = versión activa) |
| GET | `/expedientes/{id}/ui-def` | Definición UI según versión bloqueada |
| PUT | `/expedientes/{id}/componentes/{idCompVer}` | Guardar JSON del componente |
| POST | `/expedientes/{id}/acciones/{accion}` | Ejecutar transición de estado |
| GET | `/ubis/search` | Búsqueda de ubicaciones |

**Validación**:
- Cliente Angular: validación UX (rápida).
- Servidor Java: validación definitiva.
- BD: `IS JSON` + triggers de auditoría.

**Persistencia**:
- JSON como `String`/`Clob` sin mapear a columnas (modo compatible).
- Código de expediente (`COD_EXP`) generado en BD (trigger + secuencia + lógica de patrón).

---

## 9) Front Angular: UI dinámica

### 9.1. Componentes principales

| Componente | Descripción |
|---|---|
| `TramitadorShellComponent` | Layout del expediente (tabs/steps) |
| `PantallaRendererComponent` | Pinta una pantalla a partir de `TM_PANT_VER_COMP` |
| `ComponenteRendererComponent` | Elige el widget según `tipo` en `ESTRUCT_JSON` |
| `DocManagerComponent` | Subida/CSV/firmas/sellado (integrado con DIGITA/INDAR) |

### 9.2. JSON de componente (`TM_COMP_VER.ESTRUCT_JSON`)

Cada `ESTRUCT_JSON` describe:
- **campos**: nombre, etiqueta, tipo (`text`, `date`, `select`, `file`, `group`, `repeatable`, etc.).
- **constraints**: `min`, `max`, `maxLength`, `required`, etc.
- **visibilidad condicional**: p. ej. `"if requiereProyecto=SI then show proyectista"`.
- **data source**: combos dependientes / llamadas a WS.

---

## 10) Configuración inicial para EP-NIEP (scripts BD)

Para arrancar NIEP sin el editor visual, se crean a mano (scripts SQL):

1. `TM_TRAM`: EP-NIEP
2. `TM_TRAM_VER`: v1 activa
3. `TM_COMP` + `TM_COMP_VER`:
   - `COMP_DAT_EXP` (datos expediente)
   - `COMP_UBI` (búsqueda de ubicación)
   - `COMP_INST` (datos instalación + equipos)
   - `COMP_AGENTES_EP` (EI / proyectista / director)
   - `COMP_DOCS_EP` (documentación)
4. `TM_PANT` + `TM_PANT_VER` para las 4 pantallas
5. `TM_TRAM_VER_DOC` con reglas "requiere proyecto"

---

## 11) Extensión a otros trámites EP

Una vez operativo NIEP, el resto de trámites EP (MIEP, BEP, MEPEP, MEPCEP, AD, inspecciones de oficio) se incorporan creando nuevas configuraciones/versiones en catálogo y componentes específicos, **sin reprogramar pantallas** de base.

---

## 12) Stack tecnológico recomendado

| Capa | Tecnología |
|---|---|
| BD | Oracle 19c (INDAR_OWN); compatibilidad 10g en lo posible |
| Backend | Java LTS (21) + Spring Boot última estable |
| Frontend | Angular última estable (verificar compatibilidad con librería DESY) |
| Integración | SRT/SNT/SGA/CCSV; RUI (hoy INDAR, futuro WS externo) |
