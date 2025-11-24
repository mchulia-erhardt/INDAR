# 🎯 CASOS PRÁCTICOS COMPLEJOS - GESTIÓN DE USUARIOS INDAR (v2.0)

**Fecha:** 24 de Noviembre de 2025  
**Versión:** 2.0  
**Relacionado con:** PropuestaFinal_GestionUsuarios_INDAR_v2.md, DiagramaUML_GestionUsuarios_INDAR_v2.md

---

## 📌 NOVEDADES EN VERSIÓN 2.0

Esta versión incorpora la **arquitectura de dos esquemas** (RUIAR_OWN + INDAR_OWN):

- **RUIAR_OWN**: Registro único compartido entre múltiples aplicaciones
  - `RUIAR_PERSONAS`: Datos personales consolidados
  - `RUIAR_ENTIDADES`: Maestro de entidades (Titulares, Empresas, OCAs)
  - `RUIAR_EXP_CONSOLIDADOS`: Estado final de expedientes cerrados
  
- **INDAR_OWN**: Datos específicos de la aplicación INDAR
  - `USUARIOS_RELACIONADOS`: Perfiles de usuario (referencias a RUIAR)
  - Permisos, perfiles, auditoría y configuración

Todas las consultas utilizan **cross-schema foreign keys** y **vistas de compatibilidad**.

---

## 📋 ÍNDICE DE CASOS PRÁCTICOS

1. [Caso 1: Usuario con Múltiples Perfiles Empresariales](#caso-1-juan-lópez---titular-con-3-empresas)
2. [Caso 2: Técnico de OCA con Cambio de Entidad](#caso-2-maría-garcía---técnica-oca-cambia-de-entidad)
3. [Caso 3: Gestor Multiempresa](#caso-3-carlos-martínez---gestor-de-3-empresas-simultáneamente)
4. [Caso 4: Usuario con Perfil Rechazado y Reactivación](#caso-4-ana-sánchez---solicitud-rechazada-y-posterior-aprobación)
5. [Caso 5: Escenario Complejo Multi-Perfil](#caso-5-roberto-díaz---titular-empresa-técnico-oca-y-responsable-servicio)
6. [Caso 6: Sincronización INDAR → RUIAR](#caso-6-sincronización-de-expediente-cerrado-a-ruiar)
7. [Caso 7: Auditoría Cross-Schema](#caso-7-auditoría-de-acciones-críticas-con-datos-ruiar)
8. [Caso 8: Consulta Multi-Aplicación](#caso-8-consulta-multi-aplicación-desde-ruiar)

---

## 🔍 CASO 1: Juan López - Titular con 3 Empresas

### 📝 Descripción del Escenario

Juan López es una persona física que:
- Actúa como **TITULAR individual** para sus propios expedientes
- Es **TITULAR** de 2 empresas (Consultores López SL y Obras López SA)
- Es **APODERADO** de una tercera empresa (Construcciones Norte SL)

### 💾 Datos en las Tablas

#### 1️⃣ RUIAR_OWN.RUIAR_PERSONAS

```sql
INSERT INTO RUIAR_OWN.RUIAR_PERSONAS (
    ID_RUIAR_PERSONA, IDENTIFICADOR, TIPO_IDENT, NOMBRE, APELLIDO1, APELLIDO2,
    EMAIL, TELEFONO, TIPO_PERSONA, ACTIVO, FECHA_REGISTRO, APP_ORIGEN
) VALUES (
    100, '12345678A', 'NIF', 'Juan', 'López', 'García',
    'juan.lopez@email.com', '600111222', 'FISICA', 'Y', SYSTIMESTAMP, 'INDAR'
);
```

**Resultado:**
| ID_RUIAR_PERSONA | IDENTIFICADOR | NOMBRE_COMPLETO | EMAIL | TIPO_PERSONA | ACTIVO |
|------------------|---------------|-----------------|-------|--------------|--------|
| 100 | 12345678A | Juan López García | juan.lopez@email.com | FISICA | Y |

---

#### 2️⃣ RUIAR_OWN.RUIAR_ENTIDADES (3 empresas)

```sql
-- Empresa 1: Consultores López SL
INSERT INTO RUIAR_OWN.RUIAR_ENTIDADES (
    ID_RUIAR_ENTIDAD, ID_TIPO_ENTIDAD, ID_RUIAR_PERSONA, CODIGO_ENTIDAD, 
    ID_PROVINCIA, ESTADO, FECHA_ALTA, APP_ORIGEN
) VALUES (
    200, 2, 100, 'EMP-001', 50, 'ACTIVO', SYSTIMESTAMP, 'INDAR'
    -- 2=EMPRESA, 50=Zaragoza
);

-- Empresa 2: Obras López SA
INSERT INTO RUIAR_OWN.RUIAR_ENTIDADES (
    ID_RUIAR_ENTIDAD, ID_TIPO_ENTIDAD, ID_RUIAR_PERSONA, CODIGO_ENTIDAD,
    ID_PROVINCIA, ESTADO, FECHA_ALTA, APP_ORIGEN
) VALUES (
    201, 2, 100, 'EMP-002', 50, 'ACTIVO', SYSTIMESTAMP, 'INDAR'
);

-- Empresa 3: Construcciones Norte SL (propiedad de otra persona)
INSERT INTO RUIAR_OWN.RUIAR_ENTIDADES (
    ID_RUIAR_ENTIDAD, ID_TIPO_ENTIDAD, ID_RUIAR_PERSONA, CODIGO_ENTIDAD,
    ID_PROVINCIA, ESTADO, FECHA_ALTA, APP_ORIGEN
) VALUES (
    202, 2, 999, 'EMP-003', 22, 'ACTIVO', SYSTIMESTAMP, 'INDAR'
    -- 999=Otro propietario, 22=Huesca
);
```

**Resultado:**
| ID_RUIAR_ENTIDAD | TIPO | CODIGO_ENTIDAD | PROPIETARIO (ID_RUIAR_PERSONA) | PROVINCIA | ESTADO |
|------------------|------|----------------|--------------------------------|-----------|--------|
| 200 | EMPRESA | EMP-001 | 100 (Juan) | 50 (Zaragoza) | ACTIVO |
| 201 | EMPRESA | EMP-002 | 100 (Juan) | 50 (Zaragoza) | ACTIVO |
| 202 | EMPRESA | EMP-003 | 999 (Otro) | 22 (Huesca) | ACTIVO |

---

#### 3️⃣ INDAR_OWN.USUARIOS_RELACIONADOS (4 perfiles)

```sql
-- Perfil 1: TITULAR individual (sin empresa)
INSERT INTO INDAR_OWN.USUARIOS_RELACIONADOS (
    ID_USUARIO_REL, ID_RUIAR_PERSONA, ID_TIPO_RELACION, ID_RUIAR_ENTIDAD, 
    ESTADO, FECHA_ALTA
) VALUES (
    300, 100, 1, NULL, 'ACTIVO', SYSTIMESTAMP -- 1=TITULAR, NULL=sin entidad
);

-- Perfil 2: TITULAR de Consultores López SL
INSERT INTO INDAR_OWN.USUARIOS_RELACIONADOS (
    ID_USUARIO_REL, ID_RUIAR_PERSONA, ID_TIPO_RELACION, ID_RUIAR_ENTIDAD,
    ESTADO, FECHA_ALTA
) VALUES (
    301, 100, 1, 200, 'ACTIVO', SYSTIMESTAMP
);

-- Perfil 3: TITULAR de Obras López SA
INSERT INTO INDAR_OWN.USUARIOS_RELACIONADOS (
    ID_USUARIO_REL, ID_RUIAR_PERSONA, ID_TIPO_RELACION, ID_RUIAR_ENTIDAD,
    ESTADO, FECHA_ALTA
) VALUES (
    302, 100, 1, 201, 'ACTIVO', SYSTIMESTAMP
);

-- Perfil 4: APODERADO de Construcciones Norte SL
INSERT INTO INDAR_OWN.USUARIOS_RELACIONADOS (
    ID_USUARIO_REL, ID_RUIAR_PERSONA, ID_TIPO_RELACION, ID_RUIAR_ENTIDAD,
    ESTADO, FECHA_ALTA, FECHA_APROBACION, USUARIO_APROBACION
) VALUES (
    303, 100, 4, 202, 'ACTIVO', SYSTIMESTAMP, SYSTIMESTAMP, 'admin_oca'
    -- 4=APODERADO
);
```

**Resultado:**
| ID_USUARIO_REL | PERSONA (RUIAR) | PERFIL | ENTIDAD (RUIAR) | ESTADO | APROBACIÓN |
|----------------|-----------------|--------|-----------------|--------|------------|
| 300 | Juan López (100) | TITULAR | - (individual) | ACTIVO | No requiere |
| 301 | Juan López (100) | TITULAR | Consultores López (200) | ACTIVO | No requiere |
| 302 | Juan López (100) | TITULAR | Obras López (201) | ACTIVO | No requiere |
| 303 | Juan López (100) | APODERADO | Construcciones Norte (202) | ACTIVO | ✅ admin_oca |

---

### 🔍 Consultas de Validación

#### Consulta 1: Ver todos los perfiles de Juan (CROSS-SCHEMA)

```sql
SELECT 
    rp.NOMBRE || ' ' || rp.APELLIDO1 || ' ' || rp.APELLIDO2 AS NOMBRE_COMPLETO,
    tr.NOMBRE AS PERFIL,
    COALESCE(re.NOMBRE, '(Individual)') AS ENTIDAD,
    ur.ESTADO,
    ur.FECHA_ALTA
FROM RUIAR_OWN.RUIAR_PERSONAS rp
JOIN INDAR_OWN.USUARIOS_RELACIONADOS ur ON rp.ID_RUIAR_PERSONA = ur.ID_RUIAR_PERSONA
JOIN INDAR_OWN.TIPOS_RELACION tr ON ur.ID_TIPO_RELACION = tr.ID_TIPO_RELACION
LEFT JOIN RUIAR_OWN.RUIAR_ENTIDADES re ON ur.ID_RUIAR_ENTIDAD = re.ID_RUIAR_ENTIDAD
WHERE rp.IDENTIFICADOR = '12345678A'
  AND ur.ESTADO = 'ACTIVO'
ORDER BY ur.FECHA_ALTA;
```

**Resultado Esperado:**
| NOMBRE_COMPLETO | PERFIL | ENTIDAD | ESTADO | FECHA_ALTA |
|-----------------|--------|---------|--------|------------|
| Juan López García | TITULAR | (Individual) | ACTIVO | 2025-01-15 |
| Juan López García | TITULAR | Consultores López SL | ACTIVO | 2025-01-15 |
| Juan López García | TITULAR | Obras López SA | ACTIVO | 2025-03-20 |
| Juan López García | APODERADO | Construcciones Norte SL | ACTIVO | 2025-06-10 |

✅ **Validación:** Juan puede elegir entre 4 perfiles al iniciar sesión.

---

#### Consulta 2: Permisos de Juan como TITULAR individual

```sql
SELECT 
    m.NOMBRE AS MENU,
    a.NOMBRE AS ACCION,
    prv.TIPO_PERMISO
FROM INDAR_OWN.USUARIOS_RELACIONADOS ur
JOIN INDAR_OWN.PERMISOS_RELACION_VERSION prv ON ur.ID_TIPO_RELACION = prv.ID_TIPO_RELACION
JOIN INDAR_OWN.VERSIONES_APLICACION va ON prv.ID_VERSION = va.ID_VERSION
JOIN INDAR_OWN.MENUS m ON prv.ID_MENU = m.ID_MENU
JOIN INDAR_OWN.ACCIONES a ON prv.ID_ACCION = a.ID_ACCION
WHERE ur.ID_USUARIO_REL = 300 -- TITULAR individual
  AND va.ACTIVA = 'Y'
  AND prv.ACTIVO = 'Y'
  AND prv.TIPO_PERMISO = 'PERMITIDO'
ORDER BY m.ORDEN, a.CODIGO;
```

**Resultado Esperado:**
| MENU | ACCION | TIPO_PERMISO |
|------|--------|--------------|
| Mis Expedientes | Crear Expediente | PERMITIDO |
| Mis Expedientes | Ver Expedientes | PERMITIDO |
| Mis Expedientes | Editar Expediente | PERMITIDO |
| Mis Expedientes | Firmar Expediente | PERMITIDO |
| Mis Documentos | Subir Documento | PERMITIDO |

✅ **Validación:** Como TITULAR, puede gestionar sus propios expedientes.

---

#### Consulta 3: Uso de Vista de Compatibilidad

```sql
-- La aplicación puede seguir usando la vista V_DATOS_PERSONALES
SELECT 
    ID_DATOS,
    IDENTIFICADOR,
    NOMBRE_COMPLETO,
    EMAIL,
    TIPO_PERSONA
FROM INDAR_OWN.V_DATOS_PERSONALES
WHERE IDENTIFICADOR = '12345678A';
```

**Resultado Esperado:**
| ID_DATOS | IDENTIFICADOR | NOMBRE_COMPLETO | EMAIL | TIPO_PERSONA |
|----------|---------------|-----------------|-------|--------------|
| 100 | 12345678A | Juan López García | juan.lopez@email.com | FISICA |

✅ **Validación:** El código antiguo sigue funcionando con las vistas de compatibilidad.

---

## 🔄 CASO 2: María García - Técnica OCA Cambia de Entidad

### 📝 Descripción del Escenario

María García:
- Es **TECNICO_OCA** en "OCA Norte" desde 2024-01-01
- Se traslada a "OCA Sur" el 2025-06-01
- Debe mantener histórico de acciones en ambas OCAs
- Su información personal en RUIAR permanece única

### 💾 Datos en las Tablas

#### 1️⃣ RUIAR_OWN.RUIAR_PERSONAS

```sql
INSERT INTO RUIAR_OWN.RUIAR_PERSONAS (
    ID_RUIAR_PERSONA, IDENTIFICADOR, TIPO_IDENT, NOMBRE, APELLIDO1,
    EMAIL, TIPO_PERSONA, ACTIVO, FECHA_REGISTRO, APP_ORIGEN
) VALUES (
    110, '87654321B', 'NIF', 'María', 'García',
    'maria.garcia@ocas.aragon.es', 'FISICA', 'Y', SYSTIMESTAMP, 'INDAR'
);
```

---

#### 2️⃣ RUIAR_OWN.RUIAR_ENTIDADES (2 OCAs)

```sql
-- OCA Norte
INSERT INTO RUIAR_OWN.RUIAR_ENTIDADES (
    ID_RUIAR_ENTIDAD, ID_TIPO_ENTIDAD, ID_RUIAR_PERSONA, CODIGO_ENTIDAD,
    ID_PROVINCIA, ESTADO, FECHA_ALTA, APP_ORIGEN
) VALUES (
    210, 3, 888, 'OCA-NORTE', 50, 'ACTIVO', SYSTIMESTAMP, 'INDAR'
    -- 3=OCA, 888=Gobierno de Aragón
);

-- OCA Sur
INSERT INTO RUIAR_OWN.RUIAR_ENTIDADES (
    ID_RUIAR_ENTIDAD, ID_TIPO_ENTIDAD, ID_RUIAR_PERSONA, CODIGO_ENTIDAD,
    ID_PROVINCIA, ESTADO, FECHA_ALTA, APP_ORIGEN
) VALUES (
    211, 3, 888, 'OCA-SUR', 44, 'ACTIVO', SYSTIMESTAMP, 'INDAR'
    -- 44=Teruel
);
```

---

#### 3️⃣ INDAR_OWN.USUARIOS_RELACIONADOS (2 perfiles: uno inactivo, otro activo)

```sql
-- Perfil antiguo en OCA Norte (dado de baja)
INSERT INTO INDAR_OWN.USUARIOS_RELACIONADOS (
    ID_USUARIO_REL, ID_RUIAR_PERSONA, ID_TIPO_RELACION, ID_RUIAR_ENTIDAD,
    ESTADO, FECHA_ALTA, FECHA_BAJA, MOTIVO_BAJA
) VALUES (
    310, 110, 3, 210, 'INACTIVO', 
    TO_TIMESTAMP('2024-01-01', 'YYYY-MM-DD'), 
    TO_TIMESTAMP('2025-05-31', 'YYYY-MM-DD'),
    'Traslado a OCA Sur' -- 3=TECNICO_OCA
);

-- Perfil nuevo en OCA Sur (activo)
INSERT INTO INDAR_OWN.USUARIOS_RELACIONADOS (
    ID_USUARIO_REL, ID_RUIAR_PERSONA, ID_TIPO_RELACION, ID_RUIAR_ENTIDAD,
    ESTADO, FECHA_ALTA, FECHA_APROBACION, USUARIO_APROBACION
) VALUES (
    311, 110, 3, 211, 'ACTIVO',
    TO_TIMESTAMP('2025-06-01', 'YYYY-MM-DD'),
    TO_TIMESTAMP('2025-06-01', 'YYYY-MM-DD'),
    'responsable_oca_sur'
);
```

**Resultado:**
| ID_USUARIO_REL | PERSONA (RUIAR) | PERFIL | OCA (RUIAR) | ESTADO | PERIODO |
|----------------|-----------------|--------|-------------|--------|---------|
| 310 | María García (110) | TECNICO_OCA | OCA Norte (210) | INACTIVO | 2024-01-01 → 2025-05-31 |
| 311 | María García (110) | TECNICO_OCA | OCA Sur (211) | ACTIVO | 2025-06-01 → actual |

---

### 🔍 Consultas de Validación

#### Consulta 1: Histórico completo de María en todas las OCAs (CROSS-SCHEMA)

```sql
SELECT 
    rp.NOMBRE || ' ' || rp.APELLIDO1 AS NOMBRE_COMPLETO,
    tr.NOMBRE AS PERFIL,
    re.NOMBRE AS OCA,
    ur.ESTADO,
    ur.FECHA_ALTA,
    ur.FECHA_BAJA,
    ur.MOTIVO_BAJA
FROM RUIAR_OWN.RUIAR_PERSONAS rp
JOIN INDAR_OWN.USUARIOS_RELACIONADOS ur ON rp.ID_RUIAR_PERSONA = ur.ID_RUIAR_PERSONA
JOIN INDAR_OWN.TIPOS_RELACION tr ON ur.ID_TIPO_RELACION = tr.ID_TIPO_RELACION
JOIN RUIAR_OWN.RUIAR_ENTIDADES re ON ur.ID_RUIAR_ENTIDAD = re.ID_RUIAR_ENTIDAD
WHERE rp.IDENTIFICADOR = '87654321B'
  AND tr.CODIGO = 'TECNICO_OCA'
ORDER BY ur.FECHA_ALTA;
```

**Resultado Esperado:**
| NOMBRE_COMPLETO | PERFIL | OCA | ESTADO | FECHA_ALTA | FECHA_BAJA | MOTIVO_BAJA |
|-----------------|--------|-----|--------|------------|------------|-------------|
| María García | TECNICO_OCA | OCA Norte | INACTIVO | 2024-01-01 | 2025-05-31 | Traslado a OCA Sur |
| María García | TECNICO_OCA | OCA Sur | ACTIVO | 2025-06-01 | NULL | NULL |

✅ **Validación:** Se mantiene el histórico completo de asignaciones con referencias RUIAR.

---

#### Consulta 2: Auditoría de expedientes aprobados por María en ambas OCAs

```sql
SELECT 
    aa.FECHA_LOGIN,
    re.NOMBRE AS OCA,
    ac.NOMBRE AS ACCION,
    aac.ENTIDAD_AFECTADA,
    aac.ID_REGISTRO AS EXPEDIENTE_ID,
    aac.RESULTADO
FROM INDAR_OWN.AUDITORIA_ACCESOS aa
JOIN INDAR_OWN.USUARIOS_RELACIONADOS ur ON aa.ID_USUARIO_REL = ur.ID_USUARIO_REL
JOIN RUIAR_OWN.RUIAR_ENTIDADES re ON ur.ID_RUIAR_ENTIDAD = re.ID_RUIAR_ENTIDAD
JOIN INDAR_OWN.AUDITORIA_ACCIONES aac ON aa.ID_AUDITORIA = aac.ID_AUDITORIA
JOIN INDAR_OWN.ACCIONES ac ON aac.ID_ACCION = ac.ID_ACCION
WHERE ur.ID_RUIAR_PERSONA = 110
  AND ac.CODIGO = 'APROBAR_EXPEDIENTE'
ORDER BY aa.FECHA_LOGIN;
```

**Resultado Esperado:**
| FECHA_LOGIN | OCA | ACCION | ENTIDAD | EXPEDIENTE_ID | RESULTADO |
|-------------|-----|--------|---------|---------------|-----------|
| 2025-03-15 | OCA Norte | Aprobar Expediente | EXPEDIENTE | 12345 | EXITO |
| 2025-07-20 | OCA Sur | Aprobar Expediente | EXPEDIENTE | 67890 | EXITO |

✅ **Validación:** Auditoría completa independientemente de cambios de OCA, con datos de RUIAR.

---

## 🏢 CASO 3: Carlos Martínez - Gestor de 3 Empresas Simultáneamente

### 📝 Descripción del Escenario

Carlos Martínez:
- Es **TITULAR** de su propia empresa (Gestión Martínez SL)
- Es **GESTOR** en 2 empresas más (Industrias ABC SA y Servicios XYZ SL)
- Debe poder cambiar de contexto entre empresas fácilmente
- Su persona existe una sola vez en RUIAR

### 💾 Datos en las Tablas

#### 1️⃣ RUIAR_OWN.RUIAR_PERSONAS

```sql
INSERT INTO RUIAR_OWN.RUIAR_PERSONAS (
    ID_RUIAR_PERSONA, IDENTIFICADOR, TIPO_IDENT, NOMBRE, APELLIDO1,
    EMAIL, TIPO_PERSONA, ACTIVO, FECHA_REGISTRO, APP_ORIGEN
) VALUES (
    120, '11223344C', 'NIF', 'Carlos', 'Martínez',
    'carlos.martinez@email.com', 'FISICA', 'Y', SYSTIMESTAMP, 'INDAR'
);
```

---

#### 2️⃣ RUIAR_OWN.RUIAR_ENTIDADES (3 empresas)

```sql
-- Empresa propia
INSERT INTO RUIAR_OWN.RUIAR_ENTIDADES (
    ID_RUIAR_ENTIDAD, ID_TIPO_ENTIDAD, ID_RUIAR_PERSONA, CODIGO_ENTIDAD,
    ESTADO, FECHA_ALTA, APP_ORIGEN
) VALUES (
    220, 2, 120, 'EMP-GESTION-MARTINEZ', 'ACTIVO', SYSTIMESTAMP, 'INDAR'
);

-- Empresa donde es gestor 1
INSERT INTO RUIAR_OWN.RUIAR_ENTIDADES (
    ID_RUIAR_ENTIDAD, ID_TIPO_ENTIDAD, ID_RUIAR_PERSONA, CODIGO_ENTIDAD,
    ESTADO, FECHA_ALTA, APP_ORIGEN
) VALUES (
    221, 2, 777, 'EMP-INDUSTRIAS-ABC', 'ACTIVO', SYSTIMESTAMP, 'INDAR'
);

-- Empresa donde es gestor 2
INSERT INTO RUIAR_OWN.RUIAR_ENTIDADES (
    ID_RUIAR_ENTIDAD, ID_TIPO_ENTIDAD, ID_RUIAR_PERSONA, CODIGO_ENTIDAD,
    ESTADO, FECHA_ALTA, APP_ORIGEN
) VALUES (
    222, 2, 666, 'EMP-SERVICIOS-XYZ', 'ACTIVO', SYSTIMESTAMP, 'INDAR'
);
```

---

#### 3️⃣ INDAR_OWN.USUARIOS_RELACIONADOS (3 perfiles)

```sql
-- Perfil como TITULAR de su empresa
INSERT INTO INDAR_OWN.USUARIOS_RELACIONADOS (
    ID_USUARIO_REL, ID_RUIAR_PERSONA, ID_TIPO_RELACION, ID_RUIAR_ENTIDAD,
    ESTADO, FECHA_ALTA
) VALUES (
    320, 120, 1, 220, 'ACTIVO', SYSTIMESTAMP -- 1=TITULAR
);

-- Perfil como GESTOR en Industrias ABC
INSERT INTO INDAR_OWN.USUARIOS_RELACIONADOS (
    ID_USUARIO_REL, ID_RUIAR_PERSONA, ID_TIPO_RELACION, ID_RUIAR_ENTIDAD,
    ESTADO, FECHA_ALTA, FECHA_APROBACION, USUARIO_APROBACION
) VALUES (
    321, 120, 5, 221, 'ACTIVO', 
    SYSTIMESTAMP, SYSTIMESTAMP, 'titular_abc' -- 5=GESTOR
);

-- Perfil como GESTOR en Servicios XYZ
INSERT INTO INDAR_OWN.USUARIOS_RELACIONADOS (
    ID_USUARIO_REL, ID_RUIAR_PERSONA, ID_TIPO_RELACION, ID_RUIAR_ENTIDAD,
    ESTADO, FECHA_ALTA, FECHA_APROBACION, USUARIO_APROBACION
) VALUES (
    322, 120, 5, 222, 'ACTIVO',
    SYSTIMESTAMP, SYSTIMESTAMP, 'titular_xyz'
);
```

**Resultado:**
| ID_USUARIO_REL | PERSONA (RUIAR) | PERFIL | EMPRESA (RUIAR) | ESTADO | APROBADO POR |
|----------------|-----------------|--------|-----------------|--------|--------------|
| 320 | Carlos Martínez (120) | TITULAR | Gestión Martínez (220) | ACTIVO | - |
| 321 | Carlos Martínez (120) | GESTOR | Industrias ABC (221) | ACTIVO | titular_abc |
| 322 | Carlos Martínez (120) | GESTOR | Servicios XYZ (222) | ACTIVO | titular_xyz |

---

### 🔍 Consultas de Validación

#### Consulta 1: Selector de perfiles en el login (CROSS-SCHEMA)

```sql
SELECT 
    ur.ID_USUARIO_REL AS PERFIL_ID,
    tr.NOMBRE AS TIPO_PERFIL,
    re.NOMBRE AS EMPRESA,
    re.CODIGO_ENTIDAD,
    CASE 
        WHEN tr.CODIGO = 'TITULAR' THEN 'Todos los permisos'
        WHEN tr.CODIGO = 'GESTOR' THEN 'Permisos de gestión'
        ELSE 'Permisos limitados'
    END AS DESCRIPCION_PERMISOS
FROM INDAR_OWN.USUARIOS_RELACIONADOS ur
JOIN INDAR_OWN.TIPOS_RELACION tr ON ur.ID_TIPO_RELACION = tr.ID_TIPO_RELACION
JOIN RUIAR_OWN.RUIAR_ENTIDADES re ON ur.ID_RUIAR_ENTIDAD = re.ID_RUIAR_ENTIDAD
WHERE ur.ID_RUIAR_PERSONA = 120
  AND ur.ESTADO = 'ACTIVO'
ORDER BY tr.NIVEL_JERARQUICO DESC, re.NOMBRE;
```

**Resultado Esperado (pantalla de selección de perfil):**
| PERFIL_ID | TIPO_PERFIL | EMPRESA | CODIGO_ENTIDAD | DESCRIPCION_PERMISOS |
|-----------|-------------|---------|----------------|----------------------|
| 320 | TITULAR | Gestión Martínez SL | EMP-GESTION-MARTINEZ | Todos los permisos |
| 321 | GESTOR | Industrias ABC SA | EMP-INDUSTRIAS-ABC | Permisos de gestión |
| 322 | GESTOR | Servicios XYZ SL | EMP-SERVICIOS-XYZ | Permisos de gestión |

✅ **Validación:** Carlos ve 3 perfiles para elegir al iniciar sesión.

---

## ❌ CASO 4: Ana Sánchez - Solicitud Rechazada y Posterior Aprobación

### 📝 Descripción del Escenario

Ana Sánchez:
- Solicita ser **APODERADA** de Transportes Rápidos SA
- Primera solicitud **RECHAZADA** por el titular
- Segunda solicitud (3 meses después) es **APROBADA**
- Se debe mantener histórico de ambas solicitudes

### 💾 Datos en las Tablas

#### 1️⃣ RUIAR_OWN.RUIAR_PERSONAS

```sql
INSERT INTO RUIAR_OWN.RUIAR_PERSONAS (
    ID_RUIAR_PERSONA, IDENTIFICADOR, TIPO_IDENT, NOMBRE, APELLIDO1,
    EMAIL, TIPO_PERSONA, ACTIVO, FECHA_REGISTRO, APP_ORIGEN
) VALUES (
    130, '55667788D', 'NIF', 'Ana', 'Sánchez',
    'ana.sanchez@email.com', 'FISICA', 'Y', SYSTIMESTAMP, 'INDAR'
);
```

---

#### 2️⃣ RUIAR_OWN.RUIAR_ENTIDADES

```sql
INSERT INTO RUIAR_OWN.RUIAR_ENTIDADES (
    ID_RUIAR_ENTIDAD, ID_TIPO_ENTIDAD, ID_RUIAR_PERSONA, CODIGO_ENTIDAD,
    ESTADO, FECHA_ALTA, APP_ORIGEN
) VALUES (
    230, 2, 555, 'EMP-TRANSPORTES-RAPIDOS', 'ACTIVO', SYSTIMESTAMP, 'INDAR'
);
```

---

#### 3️⃣ INDAR_OWN.USUARIOS_RELACIONADOS (2 registros: rechazado + aprobado)

```sql
-- Primera solicitud: RECHAZADA
INSERT INTO INDAR_OWN.USUARIOS_RELACIONADOS (
    ID_USUARIO_REL, ID_RUIAR_PERSONA, ID_TIPO_RELACION, ID_RUIAR_ENTIDAD,
    ESTADO, FECHA_ALTA, FECHA_RECHAZO, USUARIO_RECHAZO, MOTIVO_RECHAZO
) VALUES (
    330, 130, 4, 230, 'RECHAZADO', 
    TO_TIMESTAMP('2025-03-01', 'YYYY-MM-DD'),
    TO_TIMESTAMP('2025-03-05', 'YYYY-MM-DD'),
    'titular_transportes',
    'Documentación insuficiente - falta poder notarial'
);

-- Segunda solicitud: APROBADA
INSERT INTO INDAR_OWN.USUARIOS_RELACIONADOS (
    ID_USUARIO_REL, ID_RUIAR_PERSONA, ID_TIPO_RELACION, ID_RUIAR_ENTIDAD,
    ESTADO, FECHA_ALTA, FECHA_APROBACION, USUARIO_APROBACION, OBSERVACIONES
) VALUES (
    331, 130, 4, 230, 'ACTIVO',
    TO_TIMESTAMP('2025-06-15', 'YYYY-MM-DD'),
    TO_TIMESTAMP('2025-06-17', 'YYYY-MM-DD'),
    'titular_transportes',
    'Aprobado tras presentar poder notarial actualizado'
);
```

**Resultado:**
| ID_USUARIO_REL | PERSONA (RUIAR) | PERFIL | EMPRESA (RUIAR) | ESTADO | FECHA_DECISIÓN | USUARIO_DECISIÓN |
|----------------|-----------------|--------|-----------------|--------|----------------|------------------|
| 330 | Ana Sánchez (130) | APODERADO | Transportes Rápidos (230) | RECHAZADO | 2025-03-05 | titular_transportes |
| 331 | Ana Sánchez (130) | APODERADO | Transportes Rápidos (230) | ACTIVO | 2025-06-17 | titular_transportes |

---

### 🔍 Consultas de Validación

#### Consulta 1: Histórico completo de solicitudes de Ana (CROSS-SCHEMA)

```sql
SELECT 
    rp.NOMBRE || ' ' || rp.APELLIDO1 AS NOMBRE,
    re.NOMBRE AS EMPRESA,
    ur.ESTADO,
    ur.FECHA_ALTA,
    COALESCE(ur.FECHA_APROBACION, ur.FECHA_RECHAZO) AS FECHA_DECISION,
    COALESCE(ur.USUARIO_APROBACION, ur.USUARIO_RECHAZO) AS QUIEN_DECIDIO,
    COALESCE(ur.OBSERVACIONES, ur.MOTIVO_RECHAZO) AS COMENTARIOS
FROM RUIAR_OWN.RUIAR_PERSONAS rp
JOIN INDAR_OWN.USUARIOS_RELACIONADOS ur ON rp.ID_RUIAR_PERSONA = ur.ID_RUIAR_PERSONA
JOIN RUIAR_OWN.RUIAR_ENTIDADES re ON ur.ID_RUIAR_ENTIDAD = re.ID_RUIAR_ENTIDAD
WHERE rp.IDENTIFICADOR = '55667788D'
  AND re.CODIGO_ENTIDAD = 'EMP-TRANSPORTES-RAPIDOS'
ORDER BY ur.FECHA_ALTA;
```

**Resultado Esperado:**
| NOMBRE | EMPRESA | ESTADO | FECHA_ALTA | FECHA_DECISION | QUIEN_DECIDIO | COMENTARIOS |
|--------|---------|--------|------------|----------------|---------------|-------------|
| Ana Sánchez | Transportes Rápidos SA | RECHAZADO | 2025-03-01 | 2025-03-05 | titular_transportes | Documentación insuficiente - falta poder notarial |
| Ana Sánchez | Transportes Rápidos SA | ACTIVO | 2025-06-15 | 2025-06-17 | titular_transportes | Aprobado tras presentar poder notarial actualizado |

✅ **Validación:** Se mantiene histórico completo de solicitudes rechazadas y aprobadas.

---

## 👥 CASO 5: Roberto Díaz - Titular, Empresa, Técnico OCA y Responsable Servicio

### 📝 Descripción del Escenario

Roberto Díaz (caso extremadamente complejo):
- **TITULAR individual** para expedientes personales
- **TITULAR** de "Ingeniería Díaz SL"
- **TECNICO_OCA** en OCA Central (Zaragoza)
- **RESPONSABLE_SERVICIO** del Departamento de Industria

### 💾 Datos en las Tablas

#### 1️⃣ RUIAR_OWN.RUIAR_PERSONAS

```sql
INSERT INTO RUIAR_OWN.RUIAR_PERSONAS (
    ID_RUIAR_PERSONA, IDENTIFICADOR, TIPO_IDENT, NOMBRE, APELLIDO1,
    EMAIL, TIPO_PERSONA, ACTIVO, FECHA_REGISTRO, APP_ORIGEN
) VALUES (
    140, '99887766E', 'NIF', 'Roberto', 'Díaz',
    'roberto.diaz@aragon.es', 'FISICA', 'Y', SYSTIMESTAMP, 'INDAR'
);
```

---

#### 2️⃣ RUIAR_OWN.RUIAR_ENTIDADES (Empresa + OCA + Servicio)

```sql
-- Empresa de Roberto
INSERT INTO RUIAR_OWN.RUIAR_ENTIDADES (
    ID_RUIAR_ENTIDAD, ID_TIPO_ENTIDAD, ID_RUIAR_PERSONA, CODIGO_ENTIDAD,
    ESTADO, FECHA_ALTA, APP_ORIGEN
) VALUES (
    240, 2, 140, 'EMP-INGENIERIA-DIAZ', 'ACTIVO', SYSTIMESTAMP, 'INDAR'
);

-- OCA Central
INSERT INTO RUIAR_OWN.RUIAR_ENTIDADES (
    ID_RUIAR_ENTIDAD, ID_TIPO_ENTIDAD, ID_RUIAR_PERSONA, CODIGO_ENTIDAD,
    ID_PROVINCIA, ESTADO, FECHA_ALTA, APP_ORIGEN
) VALUES (
    241, 3, 888, 'OCA-CENTRAL', 50, 'ACTIVO', SYSTIMESTAMP, 'INDAR'
);

-- Departamento de Industria (servicio público)
INSERT INTO RUIAR_OWN.RUIAR_ENTIDADES (
    ID_RUIAR_ENTIDAD, ID_TIPO_ENTIDAD, ID_RUIAR_PERSONA, CODIGO_ENTIDAD,
    ESTADO, FECHA_ALTA, APP_ORIGEN
) VALUES (
    242, 4, 888, 'SERV-INDUSTRIA', 'ACTIVO', SYSTIMESTAMP, 'INDAR'
    -- 4=SERVICIO_PUBLICO
);
```

---

#### 3️⃣ INDAR_OWN.USUARIOS_RELACIONADOS (4 perfiles activos)

```sql
-- Perfil 1: TITULAR individual
INSERT INTO INDAR_OWN.USUARIOS_RELACIONADOS (
    ID_USUARIO_REL, ID_RUIAR_PERSONA, ID_TIPO_RELACION, ID_RUIAR_ENTIDAD,
    ESTADO, FECHA_ALTA
) VALUES (
    340, 140, 1, NULL, 'ACTIVO', SYSTIMESTAMP
);

-- Perfil 2: TITULAR de empresa
INSERT INTO INDAR_OWN.USUARIOS_RELACIONADOS (
    ID_USUARIO_REL, ID_RUIAR_PERSONA, ID_TIPO_RELACION, ID_RUIAR_ENTIDAD,
    ESTADO, FECHA_ALTA
) VALUES (
    341, 140, 1, 240, 'ACTIVO', SYSTIMESTAMP
);

-- Perfil 3: TECNICO_OCA
INSERT INTO INDAR_OWN.USUARIOS_RELACIONADOS (
    ID_USUARIO_REL, ID_RUIAR_PERSONA, ID_TIPO_RELACION, ID_RUIAR_ENTIDAD,
    ESTADO, FECHA_ALTA, FECHA_APROBACION, USUARIO_APROBACION
) VALUES (
    342, 140, 3, 241, 'ACTIVO', 
    SYSTIMESTAMP, SYSTIMESTAMP, 'admin_oca_central'
);

-- Perfil 4: RESPONSABLE_SERVICIO
INSERT INTO INDAR_OWN.USUARIOS_RELACIONADOS (
    ID_USUARIO_REL, ID_RUIAR_PERSONA, ID_TIPO_RELACION, ID_RUIAR_ENTIDAD,
    ESTADO, FECHA_ALTA, FECHA_APROBACION, USUARIO_APROBACION
) VALUES (
    343, 140, 6, 242, 'ACTIVO',
    SYSTIMESTAMP, SYSTIMESTAMP, 'director_general'
);
```

**Resultado:**
| ID_USUARIO_REL | PERSONA (RUIAR) | PERFIL | ENTIDAD (RUIAR) | ESTADO |
|----------------|-----------------|--------|-----------------|--------|
| 340 | Roberto Díaz (140) | TITULAR | - (individual) | ACTIVO |
| 341 | Roberto Díaz (140) | TITULAR | Ingeniería Díaz (240) | ACTIVO |
| 342 | Roberto Díaz (140) | TECNICO_OCA | OCA Central (241) | ACTIVO |
| 343 | Roberto Díaz (140) | RESPONSABLE_SERVICIO | Dpto. Industria (242) | ACTIVO |

---

### 🔍 Consultas de Validación

#### Consulta 1: Selector de perfiles con niveles de jerarquía (CROSS-SCHEMA)

```sql
SELECT 
    ur.ID_USUARIO_REL,
    tr.NOMBRE AS PERFIL,
    tr.NIVEL_JERARQUICO,
    COALESCE(re.NOMBRE, '(Individual)') AS ENTIDAD,
    CASE 
        WHEN tr.NIVEL_JERARQUICO >= 90 THEN '🔴 Máximo acceso administrativo'
        WHEN tr.NIVEL_JERARQUICO >= 70 THEN '🟠 Alto acceso OCA/Servicio'
        WHEN tr.NIVEL_JERARQUICO >= 50 THEN '🟡 Acceso empresarial completo'
        ELSE '🟢 Acceso básico'
    END AS NIVEL_ACCESO
FROM INDAR_OWN.USUARIOS_RELACIONADOS ur
JOIN INDAR_OWN.TIPOS_RELACION tr ON ur.ID_TIPO_RELACION = tr.ID_TIPO_RELACION
LEFT JOIN RUIAR_OWN.RUIAR_ENTIDADES re ON ur.ID_RUIAR_ENTIDAD = re.ID_RUIAR_ENTIDAD
WHERE ur.ID_RUIAR_PERSONA = 140
  AND ur.ESTADO = 'ACTIVO'
ORDER BY tr.NIVEL_JERARQUICO DESC;
```

**Resultado Esperado:**
| ID_USUARIO_REL | PERFIL | NIVEL_JERARQUICO | ENTIDAD | NIVEL_ACCESO |
|----------------|--------|------------------|---------|--------------|
| 343 | RESPONSABLE_SERVICIO | 90 | Dpto. Industria | 🔴 Máximo acceso administrativo |
| 342 | TECNICO_OCA | 70 | OCA Central | 🟠 Alto acceso OCA/Servicio |
| 341 | TITULAR | 50 | Ingeniería Díaz SL | 🟡 Acceso empresarial completo |
| 340 | TITULAR | 50 | (Individual) | 🟡 Acceso empresarial completo |

✅ **Validación:** Roberto puede cambiar entre 4 perfiles con diferentes niveles de acceso.

---

#### Consulta 2: Acciones permitidas según perfil activo

```sql
SELECT 
    tr.NOMBRE AS PERFIL,
    COUNT(DISTINCT m.ID_MENU) AS TOTAL_MENUS,
    COUNT(DISTINCT a.ID_ACCION) AS TOTAL_ACCIONES,
    STRING_AGG(DISTINCT m.NOMBRE, ', ') AS MENUS_DISPONIBLES
FROM INDAR_OWN.TIPOS_RELACION tr
JOIN INDAR_OWN.PERMISOS_RELACION_VERSION prv ON tr.ID_TIPO_RELACION = prv.ID_TIPO_RELACION
JOIN INDAR_OWN.VERSIONES_APLICACION va ON prv.ID_VERSION = va.ID_VERSION
JOIN INDAR_OWN.MENUS m ON prv.ID_MENU = m.ID_MENU
JOIN INDAR_OWN.ACCIONES a ON prv.ID_ACCION = a.ID_ACCION
WHERE tr.ID_TIPO_RELACION IN (
    SELECT ID_TIPO_RELACION 
    FROM INDAR_OWN.USUARIOS_RELACIONADOS 
    WHERE ID_RUIAR_PERSONA = 140 AND ESTADO = 'ACTIVO'
)
  AND va.ACTIVA = 'Y'
  AND prv.TIPO_PERMISO = 'PERMITIDO'
GROUP BY tr.NOMBRE, tr.NIVEL_JERARQUICO
ORDER BY tr.NIVEL_JERARQUICO DESC;
```

**Resultado Esperado:**
| PERFIL | TOTAL_MENUS | TOTAL_ACCIONES | MENUS_DISPONIBLES |
|--------|-------------|----------------|-------------------|
| RESPONSABLE_SERVICIO | 8 | 45 | Panel Admin, Gestión Usuarios, Expedientes, Informes, Configuración... |
| TECNICO_OCA | 5 | 28 | Expedientes OCA, Validación, Informes, Documentos... |
| TITULAR | 4 | 18 | Mis Expedientes, Documentos, Perfil, Comunicaciones |

✅ **Validación:** Cada perfil tiene permisos diferenciados.

---

## 🔄 CASO 6: Sincronización de Expediente Cerrado a RUIAR

### 📝 Descripción del Escenario

Cuando un expediente se cierra en INDAR:
- Se ejecuta el procedimiento `SYNC_EXPEDIENTE_A_RUIAR`
- Los datos finales se guardan en `RUIAR_OWN.RUIAR_EXP_CONSOLIDADOS`
- Se registra la sincronización en `RUIAR_OWN.RUIAR_SYNC_CONTROL`
- Otras aplicaciones pueden consultar el expediente consolidado

### 💾 Procedimiento de Sincronización

```sql
-- Ejecutar sincronización al cerrar expediente
BEGIN
    INDAR_OWN.SYNC_EXPEDIENTE_A_RUIAR(
        p_expediente_id => 98765,
        p_usuario_cierre => 'tecnico_oca_01'
    );
END;
/
```

---

### 🔍 Consultas de Validación

#### Consulta 1: Ver expediente consolidado en RUIAR (disponible para todas las apps)

```sql
SELECT 
    rec.ID_EXPEDIENTE_CONSOLIDADO,
    rec.CODIGO_EXPEDIENTE,
    rec.ID_APLICACION_ORIGEN,
    rec.ID_RUIAR_TITULAR,
    rp.IDENTIFICADOR AS NIF_TITULAR,
    rp.NOMBRE || ' ' || rp.APELLIDO1 AS NOMBRE_TITULAR,
    rec.ESTADO_FINAL,
    rec.FECHA_CIERRE,
    rec.RESOLUCION_FINAL,
    rec.OBSERVACIONES
FROM RUIAR_OWN.RUIAR_EXP_CONSOLIDADOS rec
JOIN RUIAR_OWN.RUIAR_PERSONAS rp ON rec.ID_RUIAR_TITULAR = rp.ID_RUIAR_PERSONA
WHERE rec.CODIGO_EXPEDIENTE = 'EXP-2025-98765';
```

**Resultado Esperado:**
| ID_EXP_CONS | CODIGO_EXPEDIENTE | APP_ORIGEN | NIF_TITULAR | NOMBRE_TITULAR | ESTADO_FINAL | FECHA_CIERRE | RESOLUCION_FINAL |
|-------------|-------------------|------------|-------------|----------------|--------------|--------------|------------------|
| 5001 | EXP-2025-98765 | INDAR | 12345678A | Juan López García | APROBADO | 2025-11-20 | FAVORABLE CON CONDICIONES |

✅ **Validación:** El expediente está disponible en RUIAR para consulta desde cualquier aplicación.

---

#### Consulta 2: Auditoría de sincronización

```sql
SELECT 
    rsc.ID_SYNC,
    rsc.APP_ORIGEN,
    rsc.ENTIDAD_SINCRONIZADA,
    rsc.ID_REGISTRO_ORIGEN,
    rsc.OPERACION,
    rsc.FECHA_SYNC,
    rsc.USUARIO_SYNC,
    rsc.RESULTADO,
    rsc.ERRORES
FROM RUIAR_OWN.RUIAR_SYNC_CONTROL rsc
WHERE rsc.APP_ORIGEN = 'INDAR'
  AND rsc.ENTIDAD_SINCRONIZADA = 'EXPEDIENTE'
  AND rsc.ID_REGISTRO_ORIGEN = 98765
ORDER BY rsc.FECHA_SYNC DESC;
```

**Resultado Esperado:**
| ID_SYNC | APP_ORIGEN | ENTIDAD | ID_ORIGEN | OPERACION | FECHA_SYNC | USUARIO_SYNC | RESULTADO | ERRORES |
|---------|------------|---------|-----------|-----------|------------|--------------|-----------|---------|
| 7501 | INDAR | EXPEDIENTE | 98765 | INSERT | 2025-11-20 14:30:00 | tecnico_oca_01 | EXITO | NULL |

✅ **Validación:** La sincronización fue exitosa y está auditada.

---

## 📊 CASO 7: Auditoría de Acciones Críticas con Datos RUIAR

### 📝 Descripción del Escenario

Buscar todas las aprobaciones de expedientes realizadas por técnicos OCA en el último mes, mostrando información completa de personas y entidades desde RUIAR.

### 🔍 Consulta Cross-Schema Compleja

```sql
SELECT 
    aa.FECHA_LOGIN,
    rp.IDENTIFICADOR AS NIF_TECNICO,
    rp.NOMBRE || ' ' || rp.APELLIDO1 AS NOMBRE_TECNICO,
    rp.EMAIL AS EMAIL_TECNICO,
    re.NOMBRE AS OCA,
    re.CODIGO_ENTIDAD AS CODIGO_OCA,
    ac.NOMBRE AS ACCION_REALIZADA,
    aac.ENTIDAD_AFECTADA,
    aac.ID_REGISTRO AS EXPEDIENTE_ID,
    aac.RESULTADO,
    aac.DETALLE_ERRORES
FROM INDAR_OWN.AUDITORIA_ACCESOS aa
JOIN INDAR_OWN.USUARIOS_RELACIONADOS ur ON aa.ID_USUARIO_REL = ur.ID_USUARIO_REL
JOIN RUIAR_OWN.RUIAR_PERSONAS rp ON ur.ID_RUIAR_PERSONA = rp.ID_RUIAR_PERSONA
JOIN RUIAR_OWN.RUIAR_ENTIDADES re ON ur.ID_RUIAR_ENTIDAD = re.ID_RUIAR_ENTIDAD
JOIN INDAR_OWN.AUDITORIA_ACCIONES aac ON aa.ID_AUDITORIA = aac.ID_AUDITORIA
JOIN INDAR_OWN.ACCIONES ac ON aac.ID_ACCION = ac.ID_ACCION
WHERE ac.CODIGO = 'APROBAR_EXPEDIENTE'
  AND aa.FECHA_LOGIN >= SYSTIMESTAMP - INTERVAL '30' DAY
  AND aac.RESULTADO = 'EXITO'
ORDER BY aa.FECHA_LOGIN DESC;
```

**Resultado Esperado:**
| FECHA_LOGIN | NIF_TECNICO | NOMBRE_TECNICO | EMAIL_TECNICO | OCA | CODIGO_OCA | ACCION | EXPEDIENTE_ID | RESULTADO |
|-------------|-------------|----------------|---------------|-----|------------|--------|---------------|-----------|
| 2025-11-23 | 87654321B | María García | maria.garcia@ocas.aragon.es | OCA Sur | OCA-SUR | Aprobar Expediente | 67890 | EXITO |
| 2025-11-20 | 33445566F | Pedro Ruiz | pedro.ruiz@ocas.aragon.es | OCA Norte | OCA-NORTE | Aprobar Expediente | 67800 | EXITO |

✅ **Validación:** Auditoría completa con información enriquecida desde RUIAR_OWN.

---

## 🌐 CASO 8: Consulta Multi-Aplicación desde RUIAR

### 📝 Descripción del Escenario

Otra aplicación (por ejemplo, "RASMIA") necesita consultar qué expedientes INDAR tiene una persona y qué empresas gestiona, usando únicamente RUIAR como punto de partida.

### 🔍 Consulta desde Aplicación Externa

```sql
-- Consulta ejecutada desde aplicación RASMIA o cualquier otra
SELECT 
    rp.IDENTIFICADOR AS NIF,
    rp.NOMBRE || ' ' || rp.APELLIDO1 || ' ' || rp.APELLIDO2 AS NOMBRE_COMPLETO,
    rp.EMAIL,
    re.NOMBRE AS ENTIDAD,
    re.CODIGO_ENTIDAD,
    rt.NOMBRE AS TIPO_ENTIDAD,
    re.ESTADO AS ESTADO_ENTIDAD,
    rec.CODIGO_EXPEDIENTE,
    rec.ESTADO_FINAL AS ESTADO_EXPEDIENTE,
    rec.FECHA_CIERRE,
    rec.ID_APLICACION_ORIGEN AS APLICACION
FROM RUIAR_OWN.RUIAR_PERSONAS rp
LEFT JOIN RUIAR_OWN.RUIAR_ENTIDADES re ON rp.ID_RUIAR_PERSONA = re.ID_RUIAR_PERSONA
LEFT JOIN RUIAR_OWN.RUIAR_TIPOS_ENTIDAD rt ON re.ID_TIPO_ENTIDAD = rt.ID_TIPO_ENTIDAD
LEFT JOIN RUIAR_OWN.RUIAR_EXP_CONSOLIDADOS rec ON rp.ID_RUIAR_PERSONA = rec.ID_RUIAR_TITULAR
WHERE rp.IDENTIFICADOR = '12345678A'
ORDER BY rec.FECHA_CIERRE DESC, re.NOMBRE;
```

**Resultado Esperado:**
| NIF | NOMBRE_COMPLETO | EMAIL | ENTIDAD | TIPO_ENTIDAD | CODIGO_EXPEDIENTE | ESTADO_EXPEDIENTE | FECHA_CIERRE | APLICACION |
|-----|-----------------|-------|---------|--------------|-------------------|-------------------|--------------|------------|
| 12345678A | Juan López García | juan.lopez@email.com | Consultores López SL | EMPRESA | EXP-2025-98765 | APROBADO | 2025-11-20 | INDAR |
| 12345678A | Juan López García | juan.lopez@email.com | Consultores López SL | EMPRESA | EXP-2025-87654 | APROBADO | 2025-10-15 | INDAR |
| 12345678A | Juan López García | juan.lopez@email.com | Obras López SA | EMPRESA | - | - | - | - |

✅ **Validación:** RASMIA puede consultar datos consolidados de INDAR sin acceder al esquema INDAR_OWN.

---

## 📈 RESUMEN DE BENEFICIOS v2.0

### ✅ Ventajas de la Arquitectura Dual-Schema

1. **Separación de Responsabilidades**:
   - RUIAR_OWN: Datos maestros compartidos
   - INDAR_OWN: Lógica específica de aplicación

2. **Reutilización de Datos**:
   - Una persona en RUIAR puede tener perfiles en múltiples aplicaciones
   - No hay duplicación de datos personales ni de entidades

3. **Integridad Referencial**:
   - Cross-schema FKs garantizan consistencia
   - No se pueden crear perfiles INDAR sin persona/entidad RUIAR válida

4. **Auditoría Completa**:
   - INDAR audita acciones específicas de su aplicación
   - RUIAR registra sincronizaciones multi-aplicación

5. **Consultas Multi-Aplicación**:
   - Otras apps pueden consultar RUIAR sin acceder a INDAR
   - Información consolidada disponible centralmente

6. **Escalabilidad**:
   - Fácil agregar nuevas aplicaciones que usen RUIAR
   - INDAR no se ve afectado por cambios en otras aplicaciones

---

## 🔗 Documentos Relacionados

- **PropuestaFinal_GestionUsuarios_INDAR_v2.md**: Especificación completa de tablas
- **DiagramaUML_GestionUsuarios_INDAR_v2.md**: Diagramas Mermaid ERD
- **TAREAS_INDAR_Estimaciones.csv**: Planificación de tareas

---

**Fecha de última actualización:** 24 de Noviembre de 2025  
**Versión:** 2.0  
**Autor:** GitHub Copilot (Claude Sonnet 4.5)