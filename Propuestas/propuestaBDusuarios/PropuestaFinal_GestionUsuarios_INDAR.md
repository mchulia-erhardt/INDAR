# 🎯 PROPUESTA FINAL: GESTIÓN DE USUARIOS PARA RASMIA/INDAR

**Autor:** GitHub Copilot  
**Fecha:** 21 de Noviembre de 2025  
**Versión:** 1.0 Final  
**Basado en:** Análisis de 4 propuestas (Alejandro, Alex, Mizar, Oscar) + Documentación RASMIA

---

## 📊 ANÁLISIS DEL CONTEXTO

### Requisitos Clave Identificados:
1. **Sistema de tramitación de expedientes dinámicos** con versionado
2. **Múltiples tipos de perfiles**: Titular, Representante, Trabajador Empresa, Trabajador OCA, Servicio Provincial, Servicio Central
3. **Un mismo usuario puede tener múltiples perfiles** (ej: Juan López es Titular de su casa, Titular de su empresa autónoma, y Técnico en OCA Norte)
4. **Autenticación mediante MFE** (Cl@ve, Certificado Digital) del Gobierno de Aragón
5. **Permisos granulares** por perfil, menú y acción
6. **Versionado de permisos** según versión de la aplicación
7. **Gestión de entidades** (Empresas, OCAs, Servicios Provinciales)
8. **Representación legal** entre personas físicas y jurídicas
9. **Auditoría completa** de accesos y acciones

---

## 🏗️ ARQUITECTURA PROPUESTA

### **Modelo: Híbrido Normalizado con JSON Flexible**

```
┌─────────────────────────────────────────────────────┐
│          MFE Gobierno de Aragón                      │
│     (Cl@ve / Certificado Digital)                    │
└──────────────────┬──────────────────────────────────┘
                   │ Autenticación
                   │ Token JWT
                   ▼
┌─────────────────────────────────────────────────────┐
│         RASMIA Backend (Spring Boot + Java 11)       │
│                                                       │
│  ┌────────────────────────────────────────────┐     │
│  │  1. Sincronización Usuario MFE             │     │
│  │  2. Gestión Maestros (Empresas/OCAs)       │     │
│  │  3. Asignación de Perfiles a Usuarios      │     │
│  │  4. Control de Permisos por Versión        │     │
│  │  5. Auditoría Completa                     │     │
│  └────────────────────────────────────────────┘     │
│                                                       │
│  ┌────────────────────────────────────────────┐     │
│  │         Oracle 19c Database                │     │
│  │  - Tablas Normalizadas                     │     │
│  │  - Columnas JSON para Flexibilidad         │     │
│  │  - Índices Optimizados                     │     │
│  │  - Vistas Materializadas                   │     │
│  └────────────────────────────────────────────┘     │
└─────────────────────────────────────────────────────┘
```

---

## 📋 DISEÑO DE BASE DE DATOS

### **Principios de Diseño:**
1. ✅ **Normalización 3NF** - Evita duplicidad
2. ✅ **JSON para flexibilidad** - Datos adicionales sin modificar esquema
3. ✅ **Separación de concerns** - Usuario ≠ Perfil ≠ Permiso
4. ✅ **Versionado de permisos** - Por versión de aplicación
5. ✅ **Auditoría completa** - Todas las acciones registradas

---

### **CAPA 1: USUARIOS Y DATOS PERSONALES**

#### **Tabla: DATOS_PERSONALES**
Almacena información personal única, evitando duplicidad.

```sql
CREATE TABLE DATOS_PERSONALES (
    ID_DATOS            NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    IDENTIFICADOR       VARCHAR2(50) NOT NULL UNIQUE, -- NIF/NIE/CIF/VAT
    TIPO_IDENTIFICADOR  VARCHAR2(20) NOT NULL, -- NIF, NIE, CIF, PASAPORTE, VAT
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
    TIPO_PERSONA        VARCHAR2(20) NOT NULL, -- FISICA, JURIDICA
    DATOS_ADICIONALES   CLOB CHECK (DATOS_ADICIONALES IS JSON),
    FECHA_ALTA          TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    FECHA_MODIFICACION  TIMESTAMP,
    ACTIVO              CHAR(1) DEFAULT 'Y',
    CONSTRAINT CHK_DP_TIPO_ID CHECK (TIPO_IDENTIFICADOR IN ('NIF','NIE','CIF','PASAPORTE','VAT')),
    CONSTRAINT CHK_DP_TIPO_PERSONA CHECK (TIPO_PERSONA IN ('FISICA','JURIDICA')),
    CONSTRAINT CHK_DP_ACTIVO CHECK (ACTIVO IN ('Y','N'))
);

CREATE INDEX IDX_DP_IDENTIFICADOR ON DATOS_PERSONALES(IDENTIFICADOR);
CREATE INDEX IDX_DP_TIPO_PERSONA ON DATOS_PERSONALES(TIPO_PERSONA);
CREATE INDEX IDX_DP_EMAIL ON DATOS_PERSONALES(EMAIL);

COMMENT ON TABLE DATOS_PERSONALES IS 'Datos personales únicos sin duplicidad';
COMMENT ON COLUMN DATOS_PERSONALES.DATOS_ADICIONALES IS 'JSON: {"direccion":{"calle":"...","cp":"..."},"datos_empresa":{"razon_social":"..."}}';
```

---

### **CAPA 2: MAESTROS (ENTIDADES)**

#### **Tabla: TIPOS_MAESTRO**
Catálogo de tipos de entidades del sistema.

```sql
CREATE TABLE TIPOS_MAESTRO (
    ID_TIPO_MAESTRO     NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    CODIGO              VARCHAR2(50) NOT NULL UNIQUE,
    NOMBRE              VARCHAR2(200) NOT NULL,
    DESCRIPCION         VARCHAR2(500),
    REQUIERE_VALIDACION CHAR(1) DEFAULT 'N',
    ACTIVO              CHAR(1) DEFAULT 'Y',
    CONSTRAINT CHK_TM_REQ_VAL CHECK (REQUIERE_VALIDACION IN ('Y','N')),
    CONSTRAINT CHK_TM_ACTIVO CHECK (ACTIVO IN ('Y','N'))
);

-- Datos iniciales
INSERT INTO TIPOS_MAESTRO (CODIGO, NOMBRE, DESCRIPCION, REQUIERE_VALIDACION) VALUES
('TITULAR', 'Titular Individual', 'Persona física titular', 'N');
INSERT INTO TIPOS_MAESTRO (CODIGO, NOMBRE, DESCRIPCION, REQUIERE_VALIDACION) VALUES
('EMPRESA', 'Empresa', 'Persona jurídica / Empresa', 'Y');
INSERT INTO TIPOS_MAESTRO (CODIGO, NOMBRE, DESCRIPCION, REQUIERE_VALIDACION) VALUES
('OCA', 'Organismo de Control Autorizado', 'OCA autorizado', 'Y');
INSERT INTO TIPOS_MAESTRO (CODIGO, NOMBRE, DESCRIPCION, REQUIERE_VALIDACION) VALUES
('SERVICIO_PROVINCIAL', 'Servicio Provincial', 'Servicio Provincial DGA', 'Y');
INSERT INTO TIPOS_MAESTRO (CODIGO, NOMBRE, DESCRIPCION, REQUIERE_VALIDACION) VALUES
('SERVICIO_CENTRAL', 'Servicio Central', 'Servicio Central DGA', 'Y');
COMMIT;
```

#### **Tabla: MAESTROS_USUARIOS**
Entidades principales del sistema (Empresas, OCAs, Titulares).

```sql
CREATE TABLE MAESTROS_USUARIOS (
    ID_MAESTRO          NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ID_TIPO_MAESTRO     NUMBER NOT NULL,
    ID_DATOS            NUMBER NOT NULL, -- FK a DATOS_PERSONALES
    CODIGO_MAESTRO      VARCHAR2(100), -- Código interno si aplica
    ID_PROVINCIA        NUMBER, -- Para servicios provinciales
    METADATA            CLOB CHECK (METADATA IS JSON),
    ESTADO              VARCHAR2(20) DEFAULT 'ACTIVO',
    FECHA_ALTA          TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    FECHA_BAJA          TIMESTAMP,
    FECHA_VALIDACION    TIMESTAMP,
    USUARIO_VALIDACION  VARCHAR2(50),
    CONSTRAINT FK_MAESTRO_TIPO FOREIGN KEY (ID_TIPO_MAESTRO) 
        REFERENCES TIPOS_MAESTRO(ID_TIPO_MAESTRO),
    CONSTRAINT FK_MAESTRO_DATOS FOREIGN KEY (ID_DATOS) 
        REFERENCES DATOS_PERSONALES(ID_DATOS),
    CONSTRAINT CHK_MAESTRO_ESTADO CHECK (ESTADO IN ('ACTIVO','INACTIVO','PENDIENTE_VALIDACION','RECHAZADO'))
);

CREATE INDEX IDX_MAESTRO_TIPO ON MAESTROS_USUARIOS(ID_TIPO_MAESTRO);
CREATE INDEX IDX_MAESTRO_DATOS ON MAESTROS_USUARIOS(ID_DATOS);
CREATE INDEX IDX_MAESTRO_ESTADO ON MAESTROS_USUARIOS(ESTADO);
CREATE INDEX IDX_MAESTRO_PROVINCIA ON MAESTROS_USUARIOS(ID_PROVINCIA);

COMMENT ON TABLE MAESTROS_USUARIOS IS 'Entidades principales (Titulares, Empresas, OCAs, Servicios)';
COMMENT ON COLUMN MAESTROS_USUARIOS.METADATA IS 'JSON: info específica tipo maestro {"actividades":[],"ambito":"provincial"}';
```

---

### **CAPA 3: USUARIOS Y RELACIONES (PERFILES)**

#### **Tabla: TIPOS_RELACION**
Catálogo de perfiles/relaciones disponibles.

```sql
CREATE TABLE TIPOS_RELACION (
    ID_TIPO_RELACION    NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    CODIGO              VARCHAR2(50) NOT NULL UNIQUE,
    NOMBRE              VARCHAR2(200) NOT NULL,
    DESCRIPCION         VARCHAR2(500),
    REQUIERE_MAESTRO    CHAR(1) DEFAULT 'N', -- Si necesita estar vinculado a un maestro
    REQUIERE_APROBACION CHAR(1) DEFAULT 'N', -- Si necesita aprobación para activarse
    NIVEL_JERARQUICO    NUMBER DEFAULT 0, -- Para ordenar perfiles
    ACTIVO              CHAR(1) DEFAULT 'Y',
    CONSTRAINT CHK_TR_REQ_MAESTRO CHECK (REQUIERE_MAESTRO IN ('Y','N')),
    CONSTRAINT CHK_TR_REQ_APROB CHECK (REQUIERE_APROBACION IN ('Y','N')),
    CONSTRAINT CHK_TR_ACTIVO CHECK (ACTIVO IN ('Y','N'))
);

-- Datos iniciales
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

#### **Tabla: USUARIOS_RELACIONADOS**
Asignación de perfiles a usuarios. **Un usuario puede tener múltiples perfiles**.

```sql
CREATE TABLE USUARIOS_RELACIONADOS (
    ID_USUARIO_REL      NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ID_DATOS            NUMBER NOT NULL, -- Usuario (persona física)
    ID_TIPO_RELACION    NUMBER NOT NULL, -- Perfil
    ID_MAESTRO          NUMBER, -- NULL si el perfil no requiere maestro
    ESTADO              VARCHAR2(20) DEFAULT 'ACTIVO',
    FECHA_ALTA          TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    FECHA_BAJA          TIMESTAMP,
    FECHA_APROBACION    TIMESTAMP,
    USUARIO_APROBACION  VARCHAR2(50),
    MOTIVO_BAJA         VARCHAR2(500),
    MFE_ULTIMA_SYNC     TIMESTAMP, -- Última sincronización con MFE
    MFE_TOKEN_HASH      VARCHAR2(500), -- Hash del token JWT de MFE
    CONSTRAINT FK_USUREL_DATOS FOREIGN KEY (ID_DATOS) 
        REFERENCES DATOS_PERSONALES(ID_DATOS),
    CONSTRAINT FK_USUREL_TIPO FOREIGN KEY (ID_TIPO_RELACION) 
        REFERENCES TIPOS_RELACION(ID_TIPO_RELACION),
    CONSTRAINT FK_USUREL_MAESTRO FOREIGN KEY (ID_MAESTRO) 
        REFERENCES MAESTROS_USUARIOS(ID_MAESTRO),
    CONSTRAINT CHK_USUREL_ESTADO CHECK (ESTADO IN ('ACTIVO','PENDIENTE','INACTIVO','RECHAZADO','BLOQUEADO'))
);

CREATE UNIQUE INDEX UQ_USUARIO_PERFIL_MAESTRO 
    ON USUARIOS_RELACIONADOS(ID_DATOS, ID_TIPO_RELACION, COALESCE(ID_MAESTRO, -1));
CREATE INDEX IDX_USUREL_DATOS ON USUARIOS_RELACIONADOS(ID_DATOS);
CREATE INDEX IDX_USUREL_TIPO ON USUARIOS_RELACIONADOS(ID_TIPO_RELACION);
CREATE INDEX IDX_USUREL_MAESTRO ON USUARIOS_RELACIONADOS(ID_MAESTRO);
CREATE INDEX IDX_USUREL_ESTADO ON USUARIOS_RELACIONADOS(ESTADO);

COMMENT ON TABLE USUARIOS_RELACIONADOS IS 'Perfiles asignados a usuarios. Un usuario puede tener múltiples perfiles';
COMMENT ON COLUMN USUARIOS_RELACIONADOS.ID_MAESTRO IS 'NULL si perfil no requiere maestro (ej: TITULAR, ADMINISTRADOR)';
```

---

### **CAPA 4: PERMISOS Y VERSIONES**

#### **Tabla: VERSIONES_APLICACION**
Versionado de la aplicación para gestionar evolución de permisos.

```sql
CREATE TABLE VERSIONES_APLICACION (
    ID_VERSION          NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    CODIGO_VERSION      VARCHAR2(50) NOT NULL UNIQUE,
    NOMBRE_VERSION      VARCHAR2(100) NOT NULL,
    DESCRIPCION         VARCHAR2(1000),
    FECHA_PUBLICACION   DATE NOT NULL,
    ACTIVA              CHAR(1) DEFAULT 'N',
    CONSTRAINT CHK_VERSION_ACTIVA CHECK (ACTIVA IN ('Y','N'))
);

-- Datos iniciales
INSERT INTO VERSIONES_APLICACION (CODIGO_VERSION, NOMBRE_VERSION, DESCRIPCION, FECHA_PUBLICACION, ACTIVA) VALUES
('v1.0', 'Versión 1.0', 'Versión inicial del sistema', DATE '2026-01-01', 'Y');
INSERT INTO VERSIONES_APLICACION (CODIGO_VERSION, NOMBRE_VERSION, DESCRIPCION, FECHA_PUBLICACION, ACTIVA) VALUES
('v1.1', 'Versión 1.1', 'Añade módulo de informes', DATE '2026-06-01', 'N');
INSERT INTO VERSIONES_APLICACION (CODIGO_VERSION, NOMBRE_VERSION, DESCRIPCION, FECHA_PUBLICACION, ACTIVA) VALUES
('v2.0', 'Versión 2.0', 'Rediseño completo', DATE '2026-11-01', 'N');
COMMIT;
```

#### **Tabla: MENUS**
Catálogo de menús del sistema.

```sql
CREATE TABLE MENUS (
    ID_MENU             NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    CODIGO              VARCHAR2(100) NOT NULL UNIQUE,
    NOMBRE              VARCHAR2(200) NOT NULL,
    DESCRIPCION         VARCHAR2(500),
    ID_MENU_PADRE       NUMBER, -- Para jerarquía de menús
    RUTA_ANGULAR        VARCHAR2(500), -- Ruta del componente Angular
    ICONO               VARCHAR2(100),
    ORDEN               NUMBER DEFAULT 0,
    ACTIVO              CHAR(1) DEFAULT 'Y',
    CONSTRAINT FK_MENU_PADRE FOREIGN KEY (ID_MENU_PADRE) 
        REFERENCES MENUS(ID_MENU),
    CONSTRAINT CHK_MENU_ACTIVO CHECK (ACTIVO IN ('Y','N'))
);

CREATE INDEX IDX_MENU_CODIGO ON MENUS(CODIGO);
CREATE INDEX IDX_MENU_PADRE ON MENUS(ID_MENU_PADRE);

-- Datos iniciales
INSERT INTO MENUS (CODIGO, NOMBRE, RUTA_ANGULAR, ICONO, ORDEN) VALUES
('MENU_EXPEDIENTES', 'Expedientes', '/expedientes', 'folder', 1);
INSERT INTO MENUS (CODIGO, NOMBRE, RUTA_ANGULAR, ORDEN, ID_MENU_PADRE) VALUES
('MENU_EXP_LISTADO', 'Listado', '/expedientes/listado', 1, 
    (SELECT ID_MENU FROM MENUS WHERE CODIGO = 'MENU_EXPEDIENTES'));
INSERT INTO MENUS (CODIGO, NOMBRE, RUTA_ANGULAR, ORDEN, ID_MENU_PADRE) VALUES
('MENU_EXP_NUEVO', 'Nuevo Expediente', '/expedientes/nuevo', 2, 
    (SELECT ID_MENU FROM MENUS WHERE CODIGO = 'MENU_EXPEDIENTES'));
INSERT INTO MENUS (CODIGO, NOMBRE, RUTA_ANGULAR, ICONO, ORDEN) VALUES
('MENU_ADMINISTRACION', 'Administración', '/admin', 'settings', 2);
COMMIT;
```

#### **Tabla: ACCIONES**
Catálogo de acciones disponibles en el sistema.

```sql
CREATE TABLE ACCIONES (
    ID_ACCION           NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    CODIGO              VARCHAR2(100) NOT NULL UNIQUE,
    NOMBRE              VARCHAR2(200) NOT NULL,
    DESCRIPCION         VARCHAR2(500),
    TIPO_ACCION         VARCHAR2(50) NOT NULL, -- CREAR, EDITAR, ELIMINAR, FIRMAR, APROBAR, etc.
    ACTIVO              CHAR(1) DEFAULT 'Y',
    CONSTRAINT CHK_ACCION_ACTIVO CHECK (ACTIVO IN ('Y','N'))
);

CREATE INDEX IDX_ACCION_CODIGO ON ACCIONES(CODIGO);
CREATE INDEX IDX_ACCION_TIPO ON ACCIONES(TIPO_ACCION);

-- Datos iniciales
INSERT INTO ACCIONES (CODIGO, NOMBRE, TIPO_ACCION) VALUES
('ACCION_CREAR_EXPEDIENTE', 'Crear Expediente', 'CREAR');
INSERT INTO ACCIONES (CODIGO, NOMBRE, TIPO_ACCION) VALUES
('ACCION_EDITAR_EXPEDIENTE', 'Editar Expediente', 'EDITAR');
INSERT INTO ACCIONES (CODIGO, NOMBRE, TIPO_ACCION) VALUES
('ACCION_ELIMINAR_EXPEDIENTE', 'Eliminar Expediente', 'ELIMINAR');
INSERT INTO ACCIONES (CODIGO, NOMBRE, TIPO_ACCION) VALUES
('ACCION_FIRMAR_EXPEDIENTE', 'Firmar Expediente', 'FIRMAR');
INSERT INTO ACCIONES (CODIGO, NOMBRE, TIPO_ACCION) VALUES
('ACCION_APROBAR_EXPEDIENTE', 'Aprobar Expediente', 'APROBAR');
INSERT INTO ACCIONES (CODIGO, NOMBRE, TIPO_ACCION) VALUES
('ACCION_REMITIR_EXPEDIENTE', 'Remitir Expediente', 'REMITIR');
INSERT INTO ACCIONES (CODIGO, NOMBRE, TIPO_ACCION) VALUES
('ACCION_TRASLADAR_EXPEDIENTE', 'Trasladar Expediente', 'TRASLADAR');
COMMIT;
```

#### **Tabla: PERMISOS_RELACION_VERSION**
Permisos por perfil, menú, acción y versión. **Núcleo del sistema de permisos**.

```sql
CREATE TABLE PERMISOS_RELACION_VERSION (
    ID_PERMISO          NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ID_TIPO_RELACION    NUMBER NOT NULL,
    ID_VERSION          NUMBER NOT NULL,
    ID_MENU             NUMBER NOT NULL,
    ID_ACCION           NUMBER NOT NULL,
    TIPO_PERMISO        VARCHAR2(20) DEFAULT 'PERMITIDO',
    CONDICIONES         CLOB CHECK (CONDICIONES IS JSON), -- Condiciones adicionales
    ACTIVO              CHAR(1) DEFAULT 'Y',
    FECHA_ALTA          TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    USUARIO_ALTA        VARCHAR2(50),
    CONSTRAINT FK_PERM_TIPO FOREIGN KEY (ID_TIPO_RELACION) 
        REFERENCES TIPOS_RELACION(ID_TIPO_RELACION),
    CONSTRAINT FK_PERM_VERSION FOREIGN KEY (ID_VERSION) 
        REFERENCES VERSIONES_APLICACION(ID_VERSION),
    CONSTRAINT FK_PERM_MENU FOREIGN KEY (ID_MENU) 
        REFERENCES MENUS(ID_MENU),
    CONSTRAINT FK_PERM_ACCION FOREIGN KEY (ID_ACCION) 
        REFERENCES ACCIONES(ID_ACCION),
    CONSTRAINT UQ_PERMISO UNIQUE (ID_TIPO_RELACION, ID_VERSION, ID_MENU, ID_ACCION),
    CONSTRAINT CHK_PERM_TIPO CHECK (TIPO_PERMISO IN ('PERMITIDO','DENEGADO')),
    CONSTRAINT CHK_PERM_ACTIVO CHECK (ACTIVO IN ('Y','N'))
);

CREATE INDEX IDX_PERM_TIPO ON PERMISOS_RELACION_VERSION(ID_TIPO_RELACION);
CREATE INDEX IDX_PERM_VERSION ON PERMISOS_RELACION_VERSION(ID_VERSION);
CREATE INDEX IDX_PERM_MENU ON PERMISOS_RELACION_VERSION(ID_MENU);
CREATE INDEX IDX_PERM_ACCION ON PERMISOS_RELACION_VERSION(ID_ACCION);

COMMENT ON TABLE PERMISOS_RELACION_VERSION IS 'Permisos por perfil, versión, menú y acción';
COMMENT ON COLUMN PERMISOS_RELACION_VERSION.CONDICIONES IS 'JSON: {"solo_propios":true,"ambito":"provincial"}';
```

---

### **CAPA 5: AUDITORÍA**

#### **Tabla: AUDITORIA_ACCESOS**
Registro de accesos al sistema.

```sql
CREATE TABLE AUDITORIA_ACCESOS (
    ID_AUDITORIA        NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ID_USUARIO_REL      NUMBER NOT NULL,
    SESION_ID           VARCHAR2(255) NOT NULL,
    TIPO_AUTENTICACION  VARCHAR2(50), -- CLAVE, CERTIFICADO_DIGITAL
    IP_ORIGEN           VARCHAR2(50),
    NAVEGADOR           VARCHAR2(500),
    DISPOSITIVO         VARCHAR2(200),
    FECHA_LOGIN         TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    FECHA_LOGOUT        TIMESTAMP,
    DURACION_SEGUNDOS   NUMBER,
    CONSTRAINT FK_AUD_USUARIO FOREIGN KEY (ID_USUARIO_REL) 
        REFERENCES USUARIOS_RELACIONADOS(ID_USUARIO_REL)
) PARTITION BY RANGE (FECHA_LOGIN) 
  INTERVAL (NUMTOYMINTERVAL(1,'MONTH'))
  (PARTITION p_inicial VALUES LESS THAN (TO_DATE('2026-01-01','YYYY-MM-DD')));

CREATE INDEX IDX_AUD_USUARIO ON AUDITORIA_ACCESOS(ID_USUARIO_REL);
CREATE INDEX IDX_AUD_SESION ON AUDITORIA_ACCESOS(SESION_ID);
CREATE INDEX IDX_AUD_FECHA ON AUDITORIA_ACCESOS(FECHA_LOGIN);

COMMENT ON TABLE AUDITORIA_ACCESOS IS 'Auditoría de accesos al sistema con particionado mensual';
```

#### **Tabla: AUDITORIA_ACCIONES**
Registro detallado de acciones.

```sql
CREATE TABLE AUDITORIA_ACCIONES (
    ID_AUD_ACCION       NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ID_AUDITORIA        NUMBER NOT NULL,
    ID_ACCION           NUMBER NOT NULL,
    ENTIDAD_AFECTADA    VARCHAR2(100), -- Nombre tabla
    ID_REGISTRO         NUMBER,
    DATOS_ANTERIORES    CLOB CHECK (DATOS_ANTERIORES IS JSON),
    DATOS_NUEVOS        CLOB CHECK (DATOS_NUEVOS IS JSON),
    RESULTADO           VARCHAR2(20) DEFAULT 'EXITO',
    MENSAJE_ERROR       VARCHAR2(2000),
    FECHA_ACCION        TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    CONSTRAINT FK_AUDACC_AUD FOREIGN KEY (ID_AUDITORIA) 
        REFERENCES AUDITORIA_ACCESOS(ID_AUDITORIA),
    CONSTRAINT FK_AUDACC_ACCION FOREIGN KEY (ID_ACCION) 
        REFERENCES ACCIONES(ID_ACCION),
    CONSTRAINT CHK_AUDACC_RESULTADO CHECK (RESULTADO IN ('EXITO','ERROR'))
);

CREATE INDEX IDX_AUDACC_AUD ON AUDITORIA_ACCIONES(ID_AUDITORIA);
CREATE INDEX IDX_AUDACC_ACCION ON AUDITORIA_ACCIONES(ID_ACCION);
CREATE INDEX IDX_AUDACC_ENTIDAD ON AUDITORIA_ACCIONES(ENTIDAD_AFECTADA, ID_REGISTRO);
CREATE INDEX IDX_AUDACC_FECHA ON AUDITORIA_ACCIONES(FECHA_ACCION);

COMMENT ON TABLE AUDITORIA_ACCIONES IS 'Auditoría detallada de acciones en el sistema';
```

---

## 🔍 VISTAS ÚTILES

### **Vista: V_USUARIOS_PERFILES_ACTIVOS**
Muestra usuarios con sus perfiles activos.

```sql
CREATE OR REPLACE VIEW V_USUARIOS_PERFILES_ACTIVOS AS
SELECT 
    dp.ID_DATOS,
    dp.IDENTIFICADOR,
    dp.NOMBRE_COMPLETO,
    dp.EMAIL,
    ur.ID_USUARIO_REL,
    tr.CODIGO AS CODIGO_PERFIL,
    tr.NOMBRE AS NOMBRE_PERFIL,
    tr.NIVEL_JERARQUICO,
    mu.ID_MAESTRO,
    tm.NOMBRE AS TIPO_MAESTRO,
    dp_maestro.NOMBRE_COMPLETO AS NOMBRE_MAESTRO,
    ur.ESTADO,
    ur.FECHA_ALTA,
    ur.FECHA_APROBACION
FROM DATOS_PERSONALES dp
INNER JOIN USUARIOS_RELACIONADOS ur ON dp.ID_DATOS = ur.ID_DATOS
INNER JOIN TIPOS_RELACION tr ON ur.ID_TIPO_RELACION = tr.ID_TIPO_RELACION
LEFT JOIN MAESTROS_USUARIOS mu ON ur.ID_MAESTRO = mu.ID_MAESTRO
LEFT JOIN TIPOS_MAESTRO tm ON mu.ID_TIPO_MAESTRO = tm.ID_TIPO_MAESTRO
LEFT JOIN DATOS_PERSONALES dp_maestro ON mu.ID_DATOS = dp_maestro.ID_DATOS
WHERE dp.ACTIVO = 'Y'
  AND ur.ESTADO = 'ACTIVO'
  AND tr.ACTIVO = 'Y';

COMMENT ON VIEW V_USUARIOS_PERFILES_ACTIVOS IS 'Vista de usuarios con perfiles activos y sus maestros';
```

### **Vista: V_PERMISOS_EFECTIVOS**
Muestra permisos efectivos por usuario y versión.

```sql
CREATE OR REPLACE VIEW V_PERMISOS_EFECTIVOS AS
SELECT 
    ur.ID_USUARIO_REL,
    dp.IDENTIFICADOR,
    dp.NOMBRE_COMPLETO,
    tr.CODIGO AS CODIGO_PERFIL,
    va.CODIGO_VERSION,
    m.CODIGO AS CODIGO_MENU,
    m.NOMBRE AS NOMBRE_MENU,
    m.RUTA_ANGULAR,
    a.CODIGO AS CODIGO_ACCION,
    a.NOMBRE AS NOMBRE_ACCION,
    a.TIPO_ACCION,
    prv.TIPO_PERMISO,
    prv.CONDICIONES
FROM USUARIOS_RELACIONADOS ur
INNER JOIN DATOS_PERSONALES dp ON ur.ID_DATOS = dp.ID_DATOS
INNER JOIN TIPOS_RELACION tr ON ur.ID_TIPO_RELACION = tr.ID_TIPO_RELACION
INNER JOIN PERMISOS_RELACION_VERSION prv ON tr.ID_TIPO_RELACION = prv.ID_TIPO_RELACION
INNER JOIN VERSIONES_APLICACION va ON prv.ID_VERSION = va.ID_VERSION
INNER JOIN MENUS m ON prv.ID_MENU = m.ID_MENU
INNER JOIN ACCIONES a ON prv.ID_ACCION = a.ID_ACCION
WHERE ur.ESTADO = 'ACTIVO'
  AND dp.ACTIVO = 'Y'
  AND tr.ACTIVO = 'Y'
  AND prv.ACTIVO = 'Y'
  AND va.ACTIVA = 'Y'
  AND m.ACTIVO = 'Y'
  AND a.ACTIVO = 'Y'
  AND prv.TIPO_PERMISO = 'PERMITIDO';

COMMENT ON VIEW V_PERMISOS_EFECTIVOS IS 'Permisos efectivos de usuarios activos en versión activa';
```

---

## 🎯 CARACTERÍSTICAS CLAVE

### ✅ **1. Un Usuario, Múltiples Perfiles**
Juan López puede ser simultáneamente:
- **Titular** (perfil auto-asignado al autenticarse por primera vez)
- **Titular de su empresa** autónoma (vinculado al maestro de su empresa)
- **Técnico OCA** en OCA Norte (vinculado al maestro OCA)

### ✅ **2. Evita Duplicidad Total**
- **Datos personales** una sola vez en `DATOS_PERSONALES`
- **Maestros** (empresas/OCAs) una sola vez en `MAESTROS_USUARIOS`
- **Relaciones** N:M entre datos personales y maestros

### ✅ **3. Permisos por Versión**
- Versión 1.0: Técnico puede **firmar** y **remitir**
- Versión 2.0: Técnico puede **aprobar** además
- Los expedientes iniciados en v1.0 mantienen permisos v1.0

### ✅ **4. JSON para Flexibilidad**
```json
// DATOS_PERSONALES.DATOS_ADICIONALES
{
  "direccion": {
    "calle": "Calle Mayor 1",
    "cp": "50001",
    "localidad": "Zaragoza"
  },
  "datos_empresa": {
    "razon_social": "Mercadona S.A.",
    "actividad": "Comercio minorista"
  }
}

// MAESTROS_USUARIOS.METADATA
{
  "ambito": "provincial",
  "provincia": "ZARAGOZA",
  "actividades": ["Inspección", "Certificación"],
  "numero_acreditacion": "OCA-001"
}

// PERMISOS_RELACION_VERSION.CONDICIONES
{
  "solo_propios": true,
  "ambito_geografico": "provincial",
  "requiere_firma_multiple": false
}
```

### ✅ **5. Sincronización con MFE**
```java
// Flujo de autenticación
1. Usuario se autentica en MFE → Token JWT
2. Backend recibe token y valida
3. Extrae NIF del token
4. Busca/Crea en DATOS_PERSONALES
5. Si es nuevo: crea perfil TITULAR auto-asignado
6. Actualiza MFE_ULTIMA_SYNC y MFE_TOKEN_HASH
7. Devuelve lista de perfiles disponibles
8. Usuario selecciona perfil para trabajar
```

---

## 🚀 VENTAJAS DE ESTA PROPUESTA

| Aspecto | Solución |
|---------|----------|
| **Duplicidad datos** | ❌ Eliminada completamente |
| **Múltiples perfiles** | ✅ Un usuario puede tener N perfiles |
| **Escalabilidad** | ✅ Añadir perfiles/permisos sin modificar código |
| **Versionado** | ✅ Permisos por versión de aplicación |
| **Auditoría** | ✅ Completa y particionada |
| **Rendimiento** | ✅ Índices optimizados + JSON indexado |
| **Flexibilidad** | ✅ JSON para datos específicos |
| **Normalización** | ✅ 3NF + Virtual columns |
| **Mantenibilidad** | ✅ Catálogos independientes |
| **Integridad** | ✅ Foreign keys + constraints |

---

## 📌 CASOS DE USO RESUELTOS

### **Caso 1: Juan López (persona física)**
```sql
-- 1. Datos personales
INSERT INTO DATOS_PERSONALES (IDENTIFICADOR, TIPO_IDENTIFICADOR, NOMBRE, APELLIDO1, TIPO_PERSONA)
VALUES ('12345678Z', 'NIF', 'Juan', 'López', 'FISICA');

-- 2. Maestro como Titular
INSERT INTO MAESTROS_USUARIOS (ID_TIPO_MAESTRO, ID_DATOS, ESTADO)
VALUES (1, 1, 'ACTIVO'); -- Tipo TITULAR

-- 3. Perfil TITULAR (auto-asignado)
INSERT INTO USUARIOS_RELACIONADOS (ID_DATOS, ID_TIPO_RELACION, ID_MAESTRO, ESTADO)
VALUES (1, 1, 1, 'ACTIVO'); -- Relación TITULAR
```

### **Caso 2: Juan López trabaja en OCA Norte**
```sql
-- 1. Maestro OCA Norte ya existe
-- ID_MAESTRO = 10 (OCA Norte)

-- 2. Añadir perfil TECNICO_OCA
INSERT INTO USUARIOS_RELACIONADOS (ID_DATOS, ID_TIPO_RELACION, ID_MAESTRO, ESTADO)
VALUES (1, 5, 10, 'PENDIENTE'); -- Requiere aprobación

-- 3. Responsable OCA aprueba
UPDATE USUARIOS_RELACIONADOS
SET ESTADO = 'ACTIVO', FECHA_APROBACION = SYSTIMESTAMP, USUARIO_APROBACION = 'responsable_oca'
WHERE ID_USUARIO_REL = 2;
```

### **Caso 3: Juan López tiene su propia empresa**
```sql
-- 1. Crear datos empresa
INSERT INTO DATOS_PERSONALES (IDENTIFICADOR, TIPO_IDENTIFICADOR, NOMBRE, TIPO_PERSONA, DATOS_ADICIONALES)
VALUES ('B12345678', 'CIF', 'Consultores López SL', 'JURIDICA', 
    '{"razon_social":"Consultores López SL","actividad":"Consultoría IT"}');

-- 2. Crear maestro empresa
INSERT INTO MAESTROS_USUARIOS (ID_TIPO_MAESTRO, ID_DATOS, ESTADO)
VALUES (2, 2, 'ACTIVO'); -- Tipo EMPRESA

-- 3. Juan es titular de su empresa
INSERT INTO USUARIOS_RELACIONADOS (ID_DATOS, ID_TIPO_RELACION, ID_MAESTRO, ESTADO)
VALUES (1, 1, 2, 'ACTIVO'); -- Juan (ID_DATOS=1) es TITULAR de empresa (ID_MAESTRO=2)
```

**Resultado:** Juan López tiene **3 perfiles activos**:
1. Titular individual
2. Titular de Consultores López SL
3. Técnico en OCA Norte

---

## 🔧 PRÓXIMOS PASOS

1. ✅ **Ejecutar scripts DDL** en Oracle 19c
2. ✅ **Crear entidades JPA** en Spring Boot
3. ✅ **Implementar servicios**: UserSyncService, ProfileService, PermissionService
4. ✅ **Desarrollar API REST** para gestión de perfiles
5. ✅ **Crear componentes Angular** para selector de perfiles
6. ✅ **Implementar interceptor** para validación de permisos
7. ✅ **Configurar Spring Security** con MFE
8. ✅ **Tests unitarios** e integración

---

## 💡 CONCLUSIÓN

Esta propuesta combina lo mejor de las 4 propuestas analizadas:
- **Arquitectura robusta** de Alejandro
- **Flexibilidad JSON** de Alex y Oscar
- **Modelo relacional maestros** de Mizar
- **Normalización y desacoplamiento** de Oscar

Es la solución más **completa, escalable y mantenible** para RASMIA/INDAR, cumpliendo todos los requisitos funcionales identificados en la documentación.

---

## 📚 REFERENCIAS

- Propuesta de Alejandro: `propuesta-gestion-usuarios-bbdd.md`
- Propuesta de Alex: `Diseño_y_Analisis_JSON_Oracle19c.md`
- Propuesta de Mizar: `tablas ejemplo.md`
- Propuesta de Oscar: `Diseño_y_Analisis_JSON_Oracle19c.md`
- Documentación RASMIA: Space Copilot "RASMIA propuesta"

---

**Generado por:** GitHub Copilot  
**Fecha:** 21 de Noviembre de 2025  
**Versión:** 1.0 Final
