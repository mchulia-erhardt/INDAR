# 🎯 PROPUESTA FINAL: GESTIÓN DE USUARIOS PARA INDAR/RUIAR

**Autor:** GitHub Copilot  
**Fecha:** 24 de Noviembre de 2025  
**Versión:** 2.0 - Integración RUIAR  
**Basado en:** Análisis de 4 propuestas + Documentación RASMIA + Requisitos RUIAR

---

## 📊 CAMBIOS RESPECTO A VERSIÓN 1.0

### **NUEVA ARQUITECTURA: DOS ESQUEMAS**

Esta versión 2.0 introduce el **esquema RUIAR_OWN** como registro único multi-aplicación, separando responsabilidades:

- **RUIAR_OWN**: Maestros de entidades compartidos entre múltiples aplicaciones
- **INDAR_OWN**: Gestión de permisos, perfiles y operaciones específicas de INDAR

---

## 🏗️ ARQUITECTURA PROPUESTA

### **Modelo: Dos Esquemas Independientes con Referencias Cross-Schema**

```
┌─────────────────────────────────────────────────────┐
│          MFE Gobierno de Aragón                      │
│     (Cl@ve / Certificado Digital)                    │
└──────────────────┬──────────────────────────────────┘
                   │ Autenticación
                   │ Token JWT
                   ▼
┌─────────────────────────────────────────────────────┐
│         INDAR Backend (Spring Boot + Java 17+)       │
│                                                       │
│  ┌────────────────────────────────────────────┐     │
│  │  1. Sincronización Usuario MFE             │     │
│  │  2. Gestión Perfiles y Permisos            │     │
│  │  3. Control Accesos por Versión            │     │
│  │  4. Auditoría Completa                     │     │
│  │  5. Sincronización con RUIAR               │     │
│  └────────────────────────────────────────────┘     │
│                                                       │
│  ┌──────────────────┐  ┌─────────────────────┐     │
│  │  ESQUEMA:        │  │  ESQUEMA:           │     │
│  │  INDAR_OWN       │←→│  RUIAR_OWN          │     │
│  │  (Permisos)      │  │  (Maestros)         │     │
│  └──────────────────┘  └─────────────────────┘     │
│         Oracle 19c Database                          │
└─────────────────────────────────────────────────────┘
                   ↑
                   │ Acceso RUIAR
                   │
         ┌─────────┴──────────┐
         │                    │
   App Externa 1      App Externa 2
```

---

## 📋 DISEÑO DE BASE DE DATOS

### **Principios de Diseño:**
1. ✅ **Separación de responsabilidades** - RUIAR (maestros) vs INDAR (permisos)
2. ✅ **Registro único** - RUIAR como fuente única de verdad para entidades
3. ✅ **Multi-aplicación** - RUIAR accesible por múltiples sistemas
4. ✅ **Referencias cross-schema** - Foreign Keys entre esquemas
5. ✅ **Normalización 3NF** - Sin duplicidad de datos
6. ✅ **JSON para flexibilidad** - Datos adicionales sin modificar esquema
7. ✅ **Auditoría completa** - Trazabilidad de cambios y sincronizaciones

---

## 🗄️ ESQUEMA RUIAR_OWN (Maestros Compartidos)

### **TABLA: RUIAR_PERSONAS**
**Antes:** `DATOS_PERSONALES` en INDAR_OWN  
**Ahora:** Maestro único de personas para todas las aplicaciones.

```sql
CREATE TABLE RUIAR_PERSONAS (
    ID_RUIAR_PERSONA    NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    IDENTIFICADOR       VARCHAR2(50) NOT NULL UNIQUE,
    TIPO_IDENTIFICADOR  VARCHAR2(20) NOT NULL,
    NOMBRE              VARCHAR2(100),
    APELLIDO1           VARCHAR2(100),
    APELLIDO2           VARCHAR2(100),
    NOMBRE_COMPLETO     VARCHAR2(300) GENERATED ALWAYS AS (
        CASE 
            WHEN APELLIDO1 IS NOT NULL THEN NOMBRE || ' ' || APELLIDO1 || ' ' || COALESCE(APELLIDO2, '')
            ELSE NOMBRE
        END
    ) VIRTUAL,
    EMAIL               VARCHAR2(200),
    TELEFONO            VARCHAR2(20),
    TIPO_PERSONA        VARCHAR2(20) NOT NULL,
    DATOS_ADICIONALES   CLOB CHECK (DATOS_ADICIONALES IS JSON),
    FECHA_ALTA          TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    FECHA_MODIFICACION  TIMESTAMP,
    FUENTE_ORIGEN       VARCHAR2(50),
    ACTIVO              CHAR(1) DEFAULT 'Y',
    CONSTRAINT CHK_RPER_TIPO_ID CHECK (TIPO_IDENTIFICADOR IN ('NIF','NIE','CIF','PASAPORTE','VAT')),
    CONSTRAINT CHK_RPER_TIPO_PERSONA CHECK (TIPO_PERSONA IN ('FISICA','JURIDICA')),
    CONSTRAINT CHK_RPER_ACTIVO CHECK (ACTIVO IN ('Y','N'))
) TABLESPACE INDAR_DAT;

CREATE INDEX IDX_RPER_IDENTIFICADOR ON RUIAR_PERSONAS(IDENTIFICADOR) TABLESPACE INDAR_IDX;
CREATE INDEX IDX_RPER_TIPO_PERSONA ON RUIAR_PERSONAS(TIPO_PERSONA) TABLESPACE INDAR_IDX;
CREATE INDEX IDX_RPER_EMAIL ON RUIAR_PERSONAS(EMAIL) TABLESPACE INDAR_IDX;

COMMENT ON TABLE RUIAR_PERSONAS IS 'Maestro único de personas para todas las aplicaciones';
COMMENT ON COLUMN RUIAR_PERSONAS.FUENTE_ORIGEN IS 'Aplicación que creó el registro (INDAR, APP_EXTERNA_1, etc)';
COMMENT ON COLUMN RUIAR_PERSONAS.DATOS_ADICIONALES IS 'JSON: {"direccion":{"calle":"...","cp":"..."},"datos_empresa":{"razon_social":"..."}}';
```

---

### **TABLA: RUIAR_TIPOS_ENTIDAD**
**Antes:** `TIPOS_MAESTRO` en INDAR_OWN  
**Ahora:** Catálogo compartido de tipos de entidades.

```sql
CREATE TABLE RUIAR_TIPOS_ENTIDAD (
    ID_TIPO_ENTIDAD     NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    CODIGO              VARCHAR2(50) NOT NULL UNIQUE,
    NOMBRE              VARCHAR2(200) NOT NULL,
    DESCRIPCION         VARCHAR2(500),
    REQUIERE_VALIDACION CHAR(1) DEFAULT 'N',
    ACTIVO              CHAR(1) DEFAULT 'Y',
    CONSTRAINT CHK_RTE_REQ_VAL CHECK (REQUIERE_VALIDACION IN ('Y','N')),
    CONSTRAINT CHK_RTE_ACTIVO CHECK (ACTIVO IN ('Y','N'))
) TABLESPACE INDAR_DAT;

CREATE INDEX IDX_RTE_CODIGO ON RUIAR_TIPOS_ENTIDAD(CODIGO) TABLESPACE INDAR_IDX;

COMMENT ON TABLE RUIAR_TIPOS_ENTIDAD IS 'Catálogo de tipos de entidades compartido';

-- Datos iniciales
INSERT INTO RUIAR_TIPOS_ENTIDAD (CODIGO, NOMBRE, DESCRIPCION, REQUIERE_VALIDACION) VALUES
('TITULAR', 'Titular Individual', 'Persona física titular', 'N');
INSERT INTO RUIAR_TIPOS_ENTIDAD (CODIGO, NOMBRE, DESCRIPCION, REQUIERE_VALIDACION) VALUES
('EMPRESA', 'Empresa', 'Persona jurídica / Empresa', 'Y');
INSERT INTO RUIAR_TIPOS_ENTIDAD (CODIGO, NOMBRE, DESCRIPCION, REQUIERE_VALIDACION) VALUES
('OCA', 'Organismo de Control Autorizado', 'OCA autorizado', 'Y');
INSERT INTO RUIAR_TIPOS_ENTIDAD (CODIGO, NOMBRE, DESCRIPCION, REQUIERE_VALIDACION) VALUES
('SERVICIO_PROVINCIAL', 'Servicio Provincial', 'Servicio Provincial DGA', 'Y');
INSERT INTO RUIAR_TIPOS_ENTIDAD (CODIGO, NOMBRE, DESCRIPCION, REQUIERE_VALIDACION) VALUES
('SERVICIO_CENTRAL', 'Servicio Central', 'Servicio Central DGA', 'Y');
COMMIT;
```

---

### **TABLA: RUIAR_ENTIDADES**
**Antes:** `MAESTROS_USUARIOS` en INDAR_OWN  
**Ahora:** Maestro único de entidades (Titulares, Empresas, OCAs).

```sql
CREATE TABLE RUIAR_ENTIDADES (
    ID_RUIAR_ENTIDAD    NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ID_TIPO_ENTIDAD     NUMBER NOT NULL,
    ID_RUIAR_PERSONA    NUMBER NOT NULL,
    CODIGO_ENTIDAD      VARCHAR2(100),
    ID_PROVINCIA        NUMBER,
    METADATA            CLOB CHECK (METADATA IS JSON),
    ESTADO              VARCHAR2(20) DEFAULT 'ACTIVO',
    FECHA_ALTA          TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    FECHA_BAJA          TIMESTAMP,
    FECHA_VALIDACION    TIMESTAMP,
    USUARIO_VALIDACION  VARCHAR2(50),
    FUENTE_ORIGEN       VARCHAR2(50),
    CONSTRAINT FK_RENT_TIPO FOREIGN KEY (ID_TIPO_ENTIDAD) 
        REFERENCES RUIAR_TIPOS_ENTIDAD(ID_TIPO_ENTIDAD),
    CONSTRAINT FK_RENT_PERSONA FOREIGN KEY (ID_RUIAR_PERSONA) 
        REFERENCES RUIAR_PERSONAS(ID_RUIAR_PERSONA),
    CONSTRAINT CHK_RENT_ESTADO CHECK (ESTADO IN ('ACTIVO','INACTIVO','PENDIENTE_VALIDACION','RECHAZADO'))
) TABLESPACE INDAR_DAT;

CREATE INDEX IDX_RENT_TIPO ON RUIAR_ENTIDADES(ID_TIPO_ENTIDAD) TABLESPACE INDAR_IDX;
CREATE INDEX IDX_RENT_PERSONA ON RUIAR_ENTIDADES(ID_RUIAR_PERSONA) TABLESPACE INDAR_IDX;
CREATE INDEX IDX_RENT_ESTADO ON RUIAR_ENTIDADES(ESTADO) TABLESPACE INDAR_IDX;
CREATE INDEX IDX_RENT_PROVINCIA ON RUIAR_ENTIDADES(ID_PROVINCIA) TABLESPACE INDAR_IDX;
CREATE INDEX IDX_RENT_CODIGO ON RUIAR_ENTIDADES(CODIGO_ENTIDAD) TABLESPACE INDAR_IDX;

COMMENT ON TABLE RUIAR_ENTIDADES IS 'Entidades principales compartidas (Titulares, Empresas, OCAs, Servicios)';
COMMENT ON COLUMN RUIAR_ENTIDADES.METADATA IS 'JSON: info específica tipo entidad {"actividades":[],"ambito":"provincial"}';
COMMENT ON COLUMN RUIAR_ENTIDADES.FUENTE_ORIGEN IS 'Aplicación que creó el registro';
```

---

### **TABLA: RUIAR_EXPEDIENTES_CONSOLIDADOS**
**Nueva tabla:** Foto final de expedientes cerrados para consulta multi-aplicación.

```sql
CREATE TABLE RUIAR_EXP_CONSOLIDADOS (
    ID_RUIAR_EXPEDIENTE NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    NUMERO_EXPEDIENTE   VARCHAR2(100) NOT NULL UNIQUE,
    ID_TITULAR          NUMBER NOT NULL,
    ID_EMPRESA          NUMBER,
    ID_OCA              NUMBER,
    TIPO_EXPEDIENTE     VARCHAR2(100),
    ESTADO_FINAL        VARCHAR2(50),
    FECHA_INICIO        DATE,
    FECHA_CIERRE        DATE,
    FECHA_CONSOLIDACION TIMESTAMP DEFAULT SYSTIMESTAMP,
    DATOS_CONSOLIDADOS  CLOB CHECK (DATOS_CONSOLIDADOS IS JSON),
    ID_INDAR_EXPEDIENTE NUMBER,
    FUENTE_APLICACION   VARCHAR2(50),
    CONSTRAINT FK_REXP_TITULAR FOREIGN KEY (ID_TITULAR) 
        REFERENCES RUIAR_ENTIDADES(ID_RUIAR_ENTIDAD),
    CONSTRAINT FK_REXP_EMPRESA FOREIGN KEY (ID_EMPRESA) 
        REFERENCES RUIAR_ENTIDADES(ID_RUIAR_ENTIDAD),
    CONSTRAINT FK_REXP_OCA FOREIGN KEY (ID_OCA) 
        REFERENCES RUIAR_ENTIDADES(ID_RUIAR_ENTIDAD),
    CONSTRAINT CHK_REXP_ESTADO CHECK (ESTADO_FINAL IN ('CERRADO','ARCHIVADO','DESISTIDO'))
) TABLESPACE INDAR_DAT;

CREATE INDEX IDX_REXP_NUMERO ON RUIAR_EXP_CONSOLIDADOS(NUMERO_EXPEDIENTE) TABLESPACE INDAR_IDX;
CREATE INDEX IDX_REXP_TITULAR ON RUIAR_EXP_CONSOLIDADOS(ID_TITULAR) TABLESPACE INDAR_IDX;
CREATE INDEX IDX_REXP_EMPRESA ON RUIAR_EXP_CONSOLIDADOS(ID_EMPRESA) TABLESPACE INDAR_IDX;
CREATE INDEX IDX_REXP_OCA ON RUIAR_EXP_CONSOLIDADOS(ID_OCA) TABLESPACE INDAR_IDX;
CREATE INDEX IDX_REXP_INDAR_REF ON RUIAR_EXP_CONSOLIDADOS(ID_INDAR_EXPEDIENTE) TABLESPACE INDAR_IDX;

COMMENT ON TABLE RUIAR_EXP_CONSOLIDADOS IS 'Foto final de expedientes cerrados - solo agentes finales sin histórico';
COMMENT ON COLUMN RUIAR_EXP_CONSOLIDADOS.ID_INDAR_EXPEDIENTE IS 'Referencia lógica al expediente en INDAR (sin FK para independencia)';
COMMENT ON COLUMN RUIAR_EXP_CONSOLIDADOS.DATOS_CONSOLIDADOS IS 'JSON: resumen datos finales del expediente';
```

---

### **TABLA: RUIAR_SYNC_CONTROL**
**Nueva tabla:** Control y auditoría de sincronizaciones multi-aplicación.

```sql
CREATE TABLE RUIAR_SYNC_CONTROL (
    ID_SYNC             NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    APLICACION_ORIGEN   VARCHAR2(50) NOT NULL,
    TABLA_DESTINO       VARCHAR2(100) NOT NULL,
    ID_REGISTRO_DESTINO NUMBER NOT NULL,
    OPERACION           VARCHAR2(20) NOT NULL,
    DATOS_SINCRONIZADOS CLOB CHECK (DATOS_SINCRONIZADOS IS JSON),
    FECHA_SYNC          TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    USUARIO_SYNC        VARCHAR2(100),
    RESULTADO           VARCHAR2(20) DEFAULT 'EXITO',
    MENSAJE_ERROR       VARCHAR2(2000),
    CONSTRAINT CHK_RSYNC_OPER CHECK (OPERACION IN ('INSERT','UPDATE','DELETE')),
    CONSTRAINT CHK_RSYNC_RESULT CHECK (RESULTADO IN ('EXITO','ERROR','CONFLICTO'))
) TABLESPACE INDAR_DAT;

CREATE INDEX IDX_RSYNC_APP ON RUIAR_SYNC_CONTROL(APLICACION_ORIGEN) TABLESPACE INDAR_IDX;
CREATE INDEX IDX_RSYNC_TABLA ON RUIAR_SYNC_CONTROL(TABLA_DESTINO, ID_REGISTRO_DESTINO) TABLESPACE INDAR_IDX;
CREATE INDEX IDX_RSYNC_FECHA ON RUIAR_SYNC_CONTROL(FECHA_SYNC) TABLESPACE INDAR_IDX;

COMMENT ON TABLE RUIAR_SYNC_CONTROL IS 'Control y auditoría de sincronizaciones desde todas las aplicaciones';
```

---

## 🗄️ ESQUEMA INDAR_OWN (Permisos y Operaciones)

### **TABLA: TIPOS_RELACION**
**Sin cambios** - Permanece en INDAR_OWN.

```sql
CREATE TABLE TIPOS_RELACION (
    ID_TIPO_RELACION    NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    CODIGO              VARCHAR2(50) NOT NULL UNIQUE,
    NOMBRE              VARCHAR2(200) NOT NULL,
    DESCRIPCION         VARCHAR2(500),
    REQUIERE_MAESTRO    CHAR(1) DEFAULT 'N',
    REQUIERE_APROBACION CHAR(1) DEFAULT 'N',
    NIVEL_JERARQUICO    NUMBER DEFAULT 0,
    ACTIVO              CHAR(1) DEFAULT 'Y',
    CONSTRAINT CHK_TR_REQ_MAESTRO CHECK (REQUIERE_MAESTRO IN ('Y','N')),
    CONSTRAINT CHK_TR_REQ_APROB CHECK (REQUIERE_APROBACION IN ('Y','N')),
    CONSTRAINT CHK_TR_ACTIVO CHECK (ACTIVO IN ('Y','N'))
) TABLESPACE INDAR_DAT;

CREATE INDEX IDX_TR_CODIGO ON TIPOS_RELACION(CODIGO) TABLESPACE INDAR_IDX;

-- Datos iniciales (iguales que v1.0)
INSERT INTO TIPOS_RELACION (CODIGO, NOMBRE, REQUIERE_MAESTRO, REQUIERE_APROBACION, NIVEL_JERARQUICO) VALUES
('TITULAR', 'Titular', 'N', 'N', 10);
INSERT INTO TIPOS_RELACION (CODIGO, NOMBRE, REQUIERE_MAESTRO, REQUIERE_APROBACION, NIVEL_JERARQUICO) VALUES
('REPRESENTANTE_TITULAR', 'Representante de Titular', 'Y', 'Y', 15);
INSERT INTO TIPOS_RELACION (CODIGO, NOMBRE, REQUIERE_MAESTRO, REQUIERE_APROBACION, NIVEL_JERARQUICO) VALUES
('ADMINISTRATIVO_EMPRESA', 'Administrativo de Empresa', 'Y', 'Y', 20);
INSERT INTO TIPOS_RELACION (CODIGO, NOMBRE, REQUIERE_MAESTRO, REQUIERE_APROBACION, NIVEL_JERARQUICO) VALUES
('TECNICO_EMPRESA', 'Técnico de Empresa', 'Y', 'Y', 25);
INSERT INTO TIPOS_RELACION (CODIGO, NOMBRE, REQUIERE_MAESTRO, REQUIERE_APROBACION, NIVEL_JERARQUICO) VALUES
('TECNICO_OCA', 'Técnico de OCA', 'Y', 'Y', 30);
INSERT INTO TIPOS_RELACION (CODIGO, NOMBRE, REQUIERE_MAESTRO, REQUIERE_APROBACION, NIVEL_JERARQUICO) VALUES
('RESPONSABLE_OCA', 'Responsable de OCA', 'Y', 'Y', 35);
INSERT INTO TIPOS_RELACION (CODIGO, NOMBRE, REQUIERE_MAESTRO, REQUIERE_APROBACION, NIVEL_JERARQUICO) VALUES
('TRAMITADOR_PROVINCIAL', 'Tramitador Servicio Provincial', 'Y', 'Y', 40);
INSERT INTO TIPOS_RELACION (CODIGO, NOMBRE, REQUIERE_MAESTRO, REQUIERE_APROBACION, NIVEL_JERARQUICO) VALUES
('JEFE_SECCION_PROVINCIAL', 'Jefe Sección Provincial', 'Y', 'Y', 45);
INSERT INTO TIPOS_RELACION (CODIGO, NOMBRE, REQUIERE_MAESTRO, REQUIERE_APROBACION, NIVEL_JERARQUICO) VALUES
('GESTOR_CENTRAL', 'Gestor Servicio Central', 'N', 'Y', 50);
INSERT INTO TIPOS_RELACION (CODIGO, NOMBRE, REQUIERE_MAESTRO, REQUIERE_APROBACION, NIVEL_JERARQUICO) VALUES
('ADMINISTRADOR', 'Administrador Sistema', 'N', 'Y', 100);
COMMIT;
```

---

### **TABLA: USUARIOS_RELACIONADOS** ⚠️ MODIFICADA
**Cambio:** Ahora referencia a `RUIAR_PERSONAS` y `RUIAR_ENTIDADES` mediante FK cross-schema.

```sql
CREATE TABLE USUARIOS_RELACIONADOS (
    ID_USUARIO_REL      NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ID_RUIAR_PERSONA    NUMBER NOT NULL,
    ID_TIPO_RELACION    NUMBER NOT NULL,
    ID_RUIAR_ENTIDAD    NUMBER,
    ESTADO              VARCHAR2(20) DEFAULT 'ACTIVO',
    FECHA_ALTA          TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    FECHA_BAJA          TIMESTAMP,
    FECHA_APROBACION    TIMESTAMP,
    USUARIO_APROBACION  VARCHAR2(50),
    MOTIVO_BAJA         VARCHAR2(500),
    MFE_ULTIMA_SYNC     TIMESTAMP,
    MFE_TOKEN_HASH      VARCHAR2(500),
    CONSTRAINT FK_USUREL_PERSONA FOREIGN KEY (ID_RUIAR_PERSONA) 
        REFERENCES RUIAR_OWN.RUIAR_PERSONAS(ID_RUIAR_PERSONA),
    CONSTRAINT FK_USUREL_TIPO FOREIGN KEY (ID_TIPO_RELACION) 
        REFERENCES TIPOS_RELACION(ID_TIPO_RELACION),
    CONSTRAINT FK_USUREL_ENTIDAD FOREIGN KEY (ID_RUIAR_ENTIDAD) 
        REFERENCES RUIAR_OWN.RUIAR_ENTIDADES(ID_RUIAR_ENTIDAD),
    CONSTRAINT CHK_USUREL_ESTADO CHECK (ESTADO IN ('ACTIVO','PENDIENTE','INACTIVO','RECHAZADO','BLOQUEADO'))
) TABLESPACE INDAR_DAT;

CREATE UNIQUE INDEX UQ_USU_PERFIL_ENTIDAD 
    ON USUARIOS_RELACIONADOS(ID_RUIAR_PERSONA, ID_TIPO_RELACION, COALESCE(ID_RUIAR_ENTIDAD, -1)) 
    TABLESPACE INDAR_IDX;
CREATE INDEX IDX_USUREL_PERSONA ON USUARIOS_RELACIONADOS(ID_RUIAR_PERSONA) TABLESPACE INDAR_IDX;
CREATE INDEX IDX_USUREL_TIPO ON USUARIOS_RELACIONADOS(ID_TIPO_RELACION) TABLESPACE INDAR_IDX;
CREATE INDEX IDX_USUREL_ENTIDAD ON USUARIOS_RELACIONADOS(ID_RUIAR_ENTIDAD) TABLESPACE INDAR_IDX;
CREATE INDEX IDX_USUREL_ESTADO ON USUARIOS_RELACIONADOS(ESTADO) TABLESPACE INDAR_IDX;

COMMENT ON TABLE USUARIOS_RELACIONADOS IS 'Perfiles asignados a usuarios INDAR. Referencias cross-schema a RUIAR_OWN';
COMMENT ON COLUMN USUARIOS_RELACIONADOS.ID_RUIAR_PERSONA IS 'FK cross-schema a RUIAR_OWN.RUIAR_PERSONAS';
COMMENT ON COLUMN USUARIOS_RELACIONADOS.ID_RUIAR_ENTIDAD IS 'FK cross-schema a RUIAR_OWN.RUIAR_ENTIDADES (nullable)';
```

---

### **TABLAS SIN CAMBIOS EN INDAR_OWN:**

Las siguientes tablas permanecen idénticas a la v1.0:
- `VERSIONES_APLICACION`
- `MENUS`
- `ACCIONES`
- `PERMISOS_RELACION_VERSION`
- `AUDITORIA_ACCESOS`
- `AUDITORIA_ACCIONES`

*(Consultar v1.0 para definiciones completas)*

---

## 🔍 VISTAS DE COMPATIBILIDAD

### **Vista: V_DATOS_PERSONALES**
Mantiene compatibilidad con código existente que usaba `DATOS_PERSONALES`.

```sql
CREATE OR REPLACE VIEW V_DATOS_PERSONALES AS
SELECT 
    ID_RUIAR_PERSONA AS ID_DATOS,
    IDENTIFICADOR,
    TIPO_IDENTIFICADOR,
    NOMBRE,
    APELLIDO1,
    APELLIDO2,
    NOMBRE_COMPLETO,
    EMAIL,
    TELEFONO,
    TIPO_PERSONA,
    DATOS_ADICIONALES,
    FECHA_ALTA,
    FECHA_MODIFICACION,
    ACTIVO
FROM RUIAR_OWN.RUIAR_PERSONAS;

COMMENT ON VIEW V_DATOS_PERSONALES IS 'Vista de compatibilidad - mantiene interfaz de DATOS_PERSONALES';
```

### **Vista: V_MAESTROS_USUARIOS**
Mantiene compatibilidad con código existente que usaba `MAESTROS_USUARIOS`.

```sql
CREATE OR REPLACE VIEW V_MAESTROS_USUARIOS AS
SELECT 
    re.ID_RUIAR_ENTIDAD AS ID_MAESTRO,
    re.ID_TIPO_ENTIDAD AS ID_TIPO_MAESTRO,
    re.ID_RUIAR_PERSONA AS ID_DATOS,
    re.CODIGO_ENTIDAD AS CODIGO_MAESTRO,
    re.ID_PROVINCIA,
    re.METADATA,
    re.ESTADO,
    re.FECHA_ALTA,
    re.FECHA_BAJA,
    re.FECHA_VALIDACION,
    re.USUARIO_VALIDACION
FROM RUIAR_OWN.RUIAR_ENTIDADES re;

COMMENT ON VIEW V_MAESTROS_USUARIOS IS 'Vista de compatibilidad - mantiene interfaz de MAESTROS_USUARIOS';
```

### **Vista: V_USUARIOS_PERFILES_ACTIVOS** ⚠️ ACTUALIZADA

```sql
CREATE OR REPLACE VIEW V_USUARIOS_PERFILES_ACTIVOS AS
SELECT 
    rp.ID_RUIAR_PERSONA AS ID_DATOS,
    rp.IDENTIFICADOR,
    rp.NOMBRE_COMPLETO,
    rp.EMAIL,
    ur.ID_USUARIO_REL,
    tr.CODIGO AS CODIGO_PERFIL,
    tr.NOMBRE AS NOMBRE_PERFIL,
    tr.NIVEL_JERARQUICO,
    re.ID_RUIAR_ENTIDAD AS ID_MAESTRO,
    rte.NOMBRE AS TIPO_MAESTRO,
    rp_entidad.NOMBRE_COMPLETO AS NOMBRE_MAESTRO,
    ur.ESTADO,
    ur.FECHA_ALTA,
    ur.FECHA_APROBACION
FROM RUIAR_OWN.RUIAR_PERSONAS rp
INNER JOIN USUARIOS_RELACIONADOS ur ON rp.ID_RUIAR_PERSONA = ur.ID_RUIAR_PERSONA
INNER JOIN TIPOS_RELACION tr ON ur.ID_TIPO_RELACION = tr.ID_TIPO_RELACION
LEFT JOIN RUIAR_OWN.RUIAR_ENTIDADES re ON ur.ID_RUIAR_ENTIDAD = re.ID_RUIAR_ENTIDAD
LEFT JOIN RUIAR_OWN.RUIAR_TIPOS_ENTIDAD rte ON re.ID_TIPO_ENTIDAD = rte.ID_TIPO_ENTIDAD
LEFT JOIN RUIAR_OWN.RUIAR_PERSONAS rp_entidad ON re.ID_RUIAR_PERSONA = rp_entidad.ID_RUIAR_PERSONA
WHERE rp.ACTIVO = 'Y'
  AND ur.ESTADO = 'ACTIVO'
  AND tr.ACTIVO = 'Y';

COMMENT ON VIEW V_USUARIOS_PERFILES_ACTIVOS IS 'Vista actualizada con referencias cross-schema a RUIAR_OWN';
```

---

## 🔄 SINCRONIZACIÓN INDAR → RUIAR

### **Procedimiento: SYNC_EXPEDIENTE_A_RUIAR**

```sql
CREATE OR REPLACE PROCEDURE SYNC_EXPEDIENTE_A_RUIAR(
    p_id_expediente IN NUMBER
) AS
    v_numero_expediente VARCHAR2(100);
    v_id_titular_ruiar NUMBER;
    v_id_empresa_ruiar NUMBER;
    v_id_oca_ruiar NUMBER;
    v_estado VARCHAR2(50);
    v_tipo_expediente VARCHAR2(100);
    v_fecha_inicio DATE;
    v_fecha_cierre DATE;
    v_existe NUMBER;
BEGIN
    -- Obtener datos del expediente INDAR
    SELECT 
        e.NUMERO_EXPEDIENTE,
        e.ESTADO,
        e.TIPO_EXPEDIENTE,
        e.FECHA_INICIO,
        e.FECHA_CIERRE
    INTO 
        v_numero_expediente,
        v_estado,
        v_tipo_expediente,
        v_fecha_inicio,
        v_fecha_cierre
    FROM EXPEDIENTES e
    WHERE e.ID_EXPEDIENTE = p_id_expediente;
    
    -- Solo sincronizar si está cerrado
    IF v_estado NOT IN ('CERRADO','ARCHIVADO') THEN
        RETURN;
    END IF;
    
    -- Obtener agentes finales (última participación activa de cada tipo)
    SELECT ID_RUIAR_ENTIDAD
    INTO v_id_titular_ruiar
    FROM (
        SELECT re.ID_RUIAR_ENTIDAD
        FROM EXPEDIENTE_PARTICIPANTES ep
        JOIN RUIAR_OWN.RUIAR_ENTIDADES re ON ep.ID_ENTIDAD = re.ID_RUIAR_ENTIDAD
        JOIN RUIAR_OWN.RUIAR_TIPOS_ENTIDAD rte ON re.ID_TIPO_ENTIDAD = rte.ID_TIPO_ENTIDAD
        WHERE ep.ID_EXPEDIENTE = p_id_expediente
          AND rte.CODIGO = 'TITULAR'
          AND ep.FECHA_BAJA IS NULL
        ORDER BY ep.FECHA_ALTA DESC
        FETCH FIRST 1 ROW ONLY
    );
    
    -- Obtener empresa final (si existe)
    BEGIN
        SELECT ID_RUIAR_ENTIDAD
        INTO v_id_empresa_ruiar
        FROM (
            SELECT re.ID_RUIAR_ENTIDAD
            FROM EXPEDIENTE_PARTICIPANTES ep
            JOIN RUIAR_OWN.RUIAR_ENTIDADES re ON ep.ID_ENTIDAD = re.ID_RUIAR_ENTIDAD
            JOIN RUIAR_OWN.RUIAR_TIPOS_ENTIDAD rte ON re.ID_TIPO_ENTIDAD = rte.ID_TIPO_ENTIDAD
            WHERE ep.ID_EXPEDIENTE = p_id_expediente
              AND rte.CODIGO = 'EMPRESA'
              AND ep.FECHA_BAJA IS NULL
            ORDER BY ep.FECHA_ALTA DESC
            FETCH FIRST 1 ROW ONLY
        );
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_id_empresa_ruiar := NULL;
    END;
    
    -- Obtener OCA final (si existe)
    BEGIN
        SELECT ID_RUIAR_ENTIDAD
        INTO v_id_oca_ruiar
        FROM (
            SELECT re.ID_RUIAR_ENTIDAD
            FROM EXPEDIENTE_PARTICIPANTES ep
            JOIN RUIAR_OWN.RUIAR_ENTIDADES re ON ep.ID_ENTIDAD = re.ID_RUIAR_ENTIDAD
            JOIN RUIAR_OWN.RUIAR_TIPOS_ENTIDAD rte ON re.ID_TIPO_ENTIDAD = rte.ID_TIPO_ENTIDAD
            WHERE ep.ID_EXPEDIENTE = p_id_expediente
              AND rte.CODIGO = 'OCA'
              AND ep.FECHA_BAJA IS NULL
            ORDER BY ep.FECHA_ALTA DESC
            FETCH FIRST 1 ROW ONLY
        );
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_id_oca_ruiar := NULL;
    END;
    
    -- Verificar si ya existe en RUIAR
    SELECT COUNT(*)
    INTO v_existe
    FROM RUIAR_OWN.RUIAR_EXP_CONSOLIDADOS
    WHERE NUMERO_EXPEDIENTE = v_numero_expediente;
    
    IF v_existe > 0 THEN
        -- Actualizar
        UPDATE RUIAR_OWN.RUIAR_EXP_CONSOLIDADOS
        SET ID_TITULAR = v_id_titular_ruiar,
            ID_EMPRESA = v_id_empresa_ruiar,
            ID_OCA = v_id_oca_ruiar,
            ESTADO_FINAL = v_estado,
            FECHA_CIERRE = v_fecha_cierre,
            FECHA_CONSOLIDACION = SYSTIMESTAMP
        WHERE NUMERO_EXPEDIENTE = v_numero_expediente;
        
        -- Registrar sincronización
        INSERT INTO RUIAR_OWN.RUIAR_SYNC_CONTROL (
            APLICACION_ORIGEN, TABLA_DESTINO, ID_REGISTRO_DESTINO, OPERACION, USUARIO_SYNC
        ) VALUES (
            'INDAR', 'RUIAR_EXP_CONSOLIDADOS', 
            (SELECT ID_RUIAR_EXPEDIENTE FROM RUIAR_OWN.RUIAR_EXP_CONSOLIDADOS WHERE NUMERO_EXPEDIENTE = v_numero_expediente),
            'UPDATE', USER
        );
    ELSE
        -- Insertar
        INSERT INTO RUIAR_OWN.RUIAR_EXP_CONSOLIDADOS (
            NUMERO_EXPEDIENTE, ID_TITULAR, ID_EMPRESA, ID_OCA, 
            TIPO_EXPEDIENTE, ESTADO_FINAL, FECHA_INICIO, FECHA_CIERRE,
            ID_INDAR_EXPEDIENTE, FUENTE_APLICACION
        ) VALUES (
            v_numero_expediente, v_id_titular_ruiar, v_id_empresa_ruiar, v_id_oca_ruiar,
            v_tipo_expediente, v_estado, v_fecha_inicio, v_fecha_cierre,
            p_id_expediente, 'INDAR'
        );
        
        -- Registrar sincronización
        INSERT INTO RUIAR_OWN.RUIAR_SYNC_CONTROL (
            APLICACION_ORIGEN, TABLA_DESTINO, ID_REGISTRO_DESTINO, OPERACION, USUARIO_SYNC
        ) VALUES (
            'INDAR', 'RUIAR_EXP_CONSOLIDADOS', 
            (SELECT ID_RUIAR_EXPEDIENTE FROM RUIAR_OWN.RUIAR_EXP_CONSOLIDADOS WHERE NUMERO_EXPEDIENTE = v_numero_expediente),
            'INSERT', USER
        );
    END IF;
    
    COMMIT;
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        -- Registrar error
        INSERT INTO RUIAR_OWN.RUIAR_SYNC_CONTROL (
            APLICACION_ORIGEN, TABLA_DESTINO, OPERACION, RESULTADO, MENSAJE_ERROR
        ) VALUES (
            'INDAR', 'RUIAR_EXP_CONSOLIDADOS', 'INSERT', 'ERROR', SQLERRM
        );
        COMMIT;
        RAISE;
END SYNC_EXPEDIENTE_A_RUIAR;
/
```

---

## 📊 RESUMEN DE CAMBIOS v1.0 → v2.0

| Tabla Original (v1.0) | Nueva Ubicación (v2.0) | Cambios |
|----------------------|------------------------|---------|
| **DATOS_PERSONALES** | **RUIAR_PERSONAS** | Movida a RUIAR + campo FUENTE_ORIGEN |
| **TIPOS_MAESTRO** | **RUIAR_TIPOS_ENTIDAD** | Movida a RUIAR |
| **MAESTROS_USUARIOS** | **RUIAR_ENTIDADES** | Movida a RUIAR + campo FUENTE_ORIGEN |
| **USUARIOS_RELACIONADOS** | **USUARIOS_RELACIONADOS** | Modificada: FK a RUIAR_OWN |
| - | **RUIAR_EXP_CONSOLIDADOS** | Nueva: Foto final expedientes |
| - | **RUIAR_SYNC_CONTROL** | Nueva: Control sincronizaciones |
| TIPOS_RELACION | TIPOS_RELACION | Sin cambios |
| VERSIONES_APLICACION | VERSIONES_APLICACION | Sin cambios |
| MENUS | MENUS | Sin cambios |
| ACCIONES | ACCIONES | Sin cambios |
| PERMISOS_RELACION_VERSION | PERMISOS_RELACION_VERSION | Sin cambios |
| AUDITORIA_ACCESOS | AUDITORIA_ACCESOS | Sin cambios |
| AUDITORIA_ACCIONES | AUDITORIA_ACCIONES | Sin cambios |

---

## ✅ VENTAJAS DE LA ARQUITECTURA v2.0

| Aspecto | Beneficio |
|---------|-----------|
| **Autonomía RUIAR** | ✅ RUIAR completamente independiente, accesible por múltiples apps |
| **Registro Único** | ✅ Un solo maestro de personas y entidades para todo el ecosistema |
| **Integridad** | ✅ Foreign Keys cross-schema mantienen consistencia |
| **Escalabilidad** | ✅ Nuevas aplicaciones pueden integrarse con RUIAR fácilmente |
| **Compatibilidad** | ✅ Vistas mantienen código INDAR existente funcionando |
| **Trazabilidad** | ✅ RUIAR_SYNC_CONTROL audita origen de cada dato |
| **Rendimiento** | ✅ Consultas optimizadas con índices específicos |
| **Mantenibilidad** | ✅ Separación clara de responsabilidades |

---

## 📚 REFERENCIAS

- **Propuesta v1.0:** PropuestaFinal_GestionUsuarios_INDAR.md
- **Diagrama UML v1.0:** DiagramaUML_GestionUsuarios_INDAR.md
- **Oracle Cross-Schema FK:** https://docs.oracle.com/en/database/oracle/oracle-database/19/sqlrf/constraint.html
- **Oracle JSON Support:** https://docs.oracle.com/en/database/oracle/oracle-database/19/adjsn/

---

**Generado por:** GitHub Copilot  
**Fecha:** 24 de Noviembre de 2025  
**Versión:** 2.0 con RUIAR
