# 🎯 CASOS PRÁCTICOS COMPLEJOS - GESTIÓN DE USUARIOS RASMIA/INDAR

**Fecha:** 21 de Noviembre de 2025  
**Versión:** 1.0  
**Relacionado con:** PropuestaFinal_GestionUsuarios_RASMIA.md

---

## 📋 ÍNDICE DE CASOS PRÁCTICOS

1. [Caso 1: Usuario con Múltiples Perfiles Empresariales](#caso-1-juan-lópez---titular-con-3-empresas)
2. [Caso 2: Técnico de OCA con Cambio de Entidad](#caso-2-maría-garcía---técnica-oca-cambia-de-entidad)
3. [Caso 3: Gestor Multiempresa](#caso-3-carlos-martínez---gestor-de-3-empresas-simultáneamente)
4. [Caso 4: Usuario con Perfil Rechazado y Reactivación](#caso-4-ana-sánchez---solicitud-rechazada-y-posterior-aprobación)
5. [Caso 5: Escenario Complejo Multi-Perfil](#caso-5-roberto-díaz---titular-empresa-técnico-oca-y-responsable-servicio)
6. [Caso 6: Evolución de Permisos entre Versiones](#caso-6-evolución-de-permisos-entre-v10-y-v20)
7. [Caso 7: Auditoría de Acciones Críticas](#caso-7-auditoría-de-acciones-críticas-de-un-técnico-oca)

---

## 🔍 CASO 1: Juan López - Titular con 3 Empresas

### 📝 Descripción del Escenario

Juan López es una persona física que:
- Actúa como **TITULAR individual** para sus propios expedientes
- Es **TITULAR** de 2 empresas (Consultores López SL y Obras López SA)
- Es **APODERADO** de una tercera empresa (Construcciones Norte SL)

### 💾 Datos en las Tablas

#### 1️⃣ DATOS_PERSONALES

```sql
INSERT INTO DATOS_PERSONALES (
    ID_DATOS, IDENTIFICADOR, TIPO_IDENTIFICADOR, NOMBRE, APELLIDO1, APELLIDO2,
    EMAIL, TELEFONO, TIPO_PERSONA, ACTIVO
) VALUES (
    100, '12345678A', 'NIF', 'Juan', 'López', 'García',
    'juan.lopez@email.com', '600111222', 'FISICA', 'Y'
);
```

**Resultado:**
| ID_DATOS | IDENTIFICADOR | NOMBRE_COMPLETO | EMAIL | TIPO_PERSONA | ACTIVO |
|----------|---------------|-----------------|-------|--------------|--------|
| 100 | 12345678A | Juan López García | juan.lopez@email.com | FISICA | Y |

---

#### 2️⃣ MAESTROS_USUARIOS (3 empresas)

```sql
-- Empresa 1: Consultores López SL
INSERT INTO MAESTROS_USUARIOS (
    ID_MAESTRO, ID_TIPO_MAESTRO, ID_DATOS, CODIGO_MAESTRO, ID_PROVINCIA, ESTADO
) VALUES (
    200, 2, 100, 'EMP-001', 50, 'ACTIVO' -- 2=EMPRESA, 50=Zaragoza
);

-- Empresa 2: Obras López SA
INSERT INTO MAESTROS_USUARIOS (
    ID_MAESTRO, ID_TIPO_MAESTRO, ID_DATOS, CODIGO_MAESTRO, ID_PROVINCIA, ESTADO
) VALUES (
    201, 2, 100, 'EMP-002', 50, 'ACTIVO'
);

-- Empresa 3: Construcciones Norte SL (donde es apoderado)
INSERT INTO MAESTROS_USUARIOS (
    ID_MAESTRO, ID_TIPO_MAESTRO, ID_DATOS, CODIGO_MAESTRO, ID_PROVINCIA, ESTADO
) VALUES (
    202, 2, 999, 'EMP-003', 22, 'ACTIVO' -- 999=Otro propietario, 22=Huesca
);
```

**Resultado:**
| ID_MAESTRO | TIPO | CODIGO_MAESTRO | PROPIETARIO (ID_DATOS) | PROVINCIA | ESTADO |
|------------|------|----------------|------------------------|-----------|--------|
| 200 | EMPRESA | EMP-001 | 100 (Juan) | 50 (Zaragoza) | ACTIVO |
| 201 | EMPRESA | EMP-002 | 100 (Juan) | 50 (Zaragoza) | ACTIVO |
| 202 | EMPRESA | EMP-003 | 999 (Otro) | 22 (Huesca) | ACTIVO |

---

#### 3️⃣ USUARIOS_RELACIONADOS (4 perfiles)

```sql
-- Perfil 1: TITULAR individual (sin empresa)
INSERT INTO USUARIOS_RELACIONADOS (
    ID_USUARIO_REL, ID_DATOS, ID_TIPO_RELACION, ID_MAESTRO, ESTADO, FECHA_ALTA
) VALUES (
    300, 100, 1, NULL, 'ACTIVO', SYSTIMESTAMP -- 1=TITULAR, NULL=sin maestro
);

-- Perfil 2: TITULAR de Consultores López SL
INSERT INTO USUARIOS_RELACIONADOS (
    ID_USUARIO_REL, ID_DATOS, ID_TIPO_RELACION, ID_MAESTRO, ESTADO, FECHA_ALTA
) VALUES (
    301, 100, 1, 200, 'ACTIVO', SYSTIMESTAMP
);

-- Perfil 3: TITULAR de Obras López SA
INSERT INTO USUARIOS_RELACIONADOS (
    ID_USUARIO_REL, ID_DATOS, ID_TIPO_RELACION, ID_MAESTRO, ESTADO, FECHA_ALTA
) VALUES (
    302, 100, 1, 201, 'ACTIVO', SYSTIMESTAMP
);

-- Perfil 4: APODERADO de Construcciones Norte SL
INSERT INTO USUARIOS_RELACIONADOS (
    ID_USUARIO_REL, ID_DATOS, ID_TIPO_RELACION, ID_MAESTRO, ESTADO, FECHA_ALTA, FECHA_APROBACION, USUARIO_APROBACION
) VALUES (
    303, 100, 4, 202, 'ACTIVO', SYSTIMESTAMP, SYSTIMESTAMP, 'admin_oca' -- 4=APODERADO
);
```

**Resultado:**
| ID_USUARIO_REL | PERSONA | PERFIL | EMPRESA | ESTADO | APROBACIÓN |
|----------------|---------|--------|---------|--------|------------|
| 300 | Juan López (100) | TITULAR | - (individual) | ACTIVO | No requiere |
| 301 | Juan López (100) | TITULAR | Consultores López (200) | ACTIVO | No requiere |
| 302 | Juan López (100) | TITULAR | Obras López (201) | ACTIVO | No requiere |
| 303 | Juan López (100) | APODERADO | Construcciones Norte (202) | ACTIVO | ✅ admin_oca |

---

### 🔍 Consultas de Validación

#### Consulta 1: Ver todos los perfiles de Juan

```sql
SELECT 
    dp.NOMBRE_COMPLETO,
    tr.NOMBRE AS PERFIL,
    COALESCE(m.NOMBRE, '(Individual)') AS ENTIDAD,
    ur.ESTADO,
    ur.FECHA_ALTA
FROM DATOS_PERSONALES dp
JOIN USUARIOS_RELACIONADOS ur ON dp.ID_DATOS = ur.ID_DATOS
JOIN TIPOS_RELACION tr ON ur.ID_TIPO_RELACION = tr.ID_TIPO_RELACION
LEFT JOIN MAESTROS_USUARIOS mu ON ur.ID_MAESTRO = mu.ID_MAESTRO
LEFT JOIN DATOS_PERSONALES m ON mu.ID_DATOS = m.ID_DATOS
WHERE dp.IDENTIFICADOR = '12345678A'
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
FROM USUARIOS_RELACIONADOS ur
JOIN PERMISOS_RELACION_VERSION prv ON ur.ID_TIPO_RELACION = prv.ID_TIPO_RELACION
JOIN VERSIONES_APLICACION va ON prv.ID_VERSION = va.ID_VERSION
JOIN MENUS m ON prv.ID_MENU = m.ID_MENU
JOIN ACCIONES a ON prv.ID_ACCION = a.ID_ACCION
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

## 🔄 CASO 2: María García - Técnica OCA Cambia de Entidad

### 📝 Descripción del Escenario

María García:
- Es **TECNICO_OCA** en "OCA Norte" desde 2024-01-01
- Se traslada a "OCA Sur" el 2025-06-01
- Debe mantener histórico de acciones en ambas OCAs

### 💾 Datos en las Tablas

#### 1️⃣ DATOS_PERSONALES

```sql
INSERT INTO DATOS_PERSONALES (
    ID_DATOS, IDENTIFICADOR, TIPO_IDENTIFICADOR, NOMBRE, APELLIDO1,
    EMAIL, TIPO_PERSONA, ACTIVO
) VALUES (
    110, '87654321B', 'NIF', 'María', 'García',
    'maria.garcia@ocas.aragon.es', 'FISICA', 'Y'
);
```

---

#### 2️⃣ MAESTROS_USUARIOS (2 OCAs)

```sql
-- OCA Norte
INSERT INTO MAESTROS_USUARIOS (
    ID_MAESTRO, ID_TIPO_MAESTRO, ID_DATOS, CODIGO_MAESTRO, ID_PROVINCIA, ESTADO
) VALUES (
    210, 3, 888, 'OCA-NORTE', 50, 'ACTIVO' -- 3=OCA, 888=Gobierno de Aragón
);

-- OCA Sur
INSERT INTO MAESTROS_USUARIOS (
    ID_MAESTRO, ID_TIPO_MAESTRO, ID_DATOS, CODIGO_MAESTRO, ID_PROVINCIA, ESTADO
) VALUES (
    211, 3, 888, 'OCA-SUR', 44, 'ACTIVO' -- 44=Teruel
);
```

---

#### 3️⃣ USUARIOS_RELACIONADOS (2 perfiles: uno inactivo, otro activo)

```sql
-- Perfil antiguo en OCA Norte (dado de baja)
INSERT INTO USUARIOS_RELACIONADOS (
    ID_USUARIO_REL, ID_DATOS, ID_TIPO_RELACION, ID_MAESTRO, ESTADO, 
    FECHA_ALTA, FECHA_BAJA, MOTIVO_BAJA
) VALUES (
    310, 110, 3, 210, 'INACTIVO', 
    TO_TIMESTAMP('2024-01-01', 'YYYY-MM-DD'), 
    TO_TIMESTAMP('2025-05-31', 'YYYY-MM-DD'),
    'Traslado a OCA Sur' -- 3=TECNICO_OCA
);

-- Perfil nuevo en OCA Sur (activo)
INSERT INTO USUARIOS_RELACIONADOS (
    ID_USUARIO_REL, ID_DATOS, ID_TIPO_RELACION, ID_MAESTRO, ESTADO,
    FECHA_ALTA, FECHA_APROBACION, USUARIO_APROBACION
) VALUES (
    311, 110, 3, 211, 'ACTIVO',
    TO_TIMESTAMP('2025-06-01', 'YYYY-MM-DD'),
    TO_TIMESTAMP('2025-06-01', 'YYYY-MM-DD'),
    'responsable_oca_sur'
);
```

**Resultado:**
| ID_USUARIO_REL | PERSONA | PERFIL | OCA | ESTADO | PERIODO |
|----------------|---------|--------|-----|--------|---------|
| 310 | María García (110) | TECNICO_OCA | OCA Norte (210) | INACTIVO | 2024-01-01 → 2025-05-31 |
| 311 | María García (110) | TECNICO_OCA | OCA Sur (211) | ACTIVO | 2025-06-01 → actual |

---

#### 4️⃣ AUDITORIA_ACCIONES (histórico en ambas OCAs)

```sql
-- Acciones en OCA Norte (antes del traslado)
INSERT INTO AUDITORIA_ACCIONES (
    ID_AUD_ACCION, ID_AUDITORIA, ID_ACCION, ENTIDAD_AFECTADA, ID_REGISTRO, RESULTADO, FECHA_ACCION
) VALUES (
    400, 500, 5, 'EXPEDIENTE', 12345, 'EXITO', TO_TIMESTAMP('2025-03-15', 'YYYY-MM-DD')
);

-- Acciones en OCA Sur (después del traslado)
INSERT INTO AUDITORIA_ACCIONES (
    ID_AUD_ACCION, ID_AUDITORIA, ID_ACCION, ENTIDAD_AFECTADA, ID_REGISTRO, RESULTADO, FECHA_ACCION
) VALUES (
    401, 501, 5, 'EXPEDIENTE', 67890, 'EXITO', TO_TIMESTAMP('2025-07-20', 'YYYY-MM-DD')
);
```

---

### 🔍 Consultas de Validación

#### Consulta 1: Histórico completo de María en todas las OCAs

```sql
SELECT 
    dp.NOMBRE_COMPLETO,
    tr.NOMBRE AS PERFIL,
    m.NOMBRE AS OCA,
    ur.ESTADO,
    ur.FECHA_ALTA,
    ur.FECHA_BAJA,
    ur.MOTIVO_BAJA
FROM DATOS_PERSONALES dp
JOIN USUARIOS_RELACIONADOS ur ON dp.ID_DATOS = ur.ID_DATOS
JOIN TIPOS_RELACION tr ON ur.ID_TIPO_RELACION = tr.ID_TIPO_RELACION
JOIN MAESTROS_USUARIOS mu ON ur.ID_MAESTRO = mu.ID_MAESTRO
LEFT JOIN DATOS_PERSONALES m ON mu.ID_DATOS = m.ID_DATOS
WHERE dp.IDENTIFICADOR = '87654321B'
  AND tr.CODIGO = 'TECNICO_OCA'
ORDER BY ur.FECHA_ALTA;
```

**Resultado Esperado:**
| NOMBRE_COMPLETO | PERFIL | OCA | ESTADO | FECHA_ALTA | FECHA_BAJA | MOTIVO_BAJA |
|-----------------|--------|-----|--------|------------|------------|-------------|
| María García | TECNICO_OCA | OCA Norte | INACTIVO | 2024-01-01 | 2025-05-31 | Traslado a OCA Sur |
| María García | TECNICO_OCA | OCA Sur | ACTIVO | 2025-06-01 | NULL | NULL |

✅ **Validación:** Se mantiene el histórico completo de asignaciones.

---

#### Consulta 2: Auditoría de expedientes aprobados por María en ambas OCAs

```sql
SELECT 
    aa.FECHA_LOGIN,
    m.NOMBRE AS OCA,
    ac.NOMBRE AS ACCION,
    aac.ENTIDAD_AFECTADA,
    aac.ID_REGISTRO AS EXPEDIENTE_ID,
    aac.RESULTADO
FROM AUDITORIA_ACCESOS aa
JOIN USUARIOS_RELACIONADOS ur ON aa.ID_USUARIO_REL = ur.ID_USUARIO_REL
JOIN MAESTROS_USUARIOS mu ON ur.ID_MAESTRO = mu.ID_MAESTRO
LEFT JOIN DATOS_PERSONALES m ON mu.ID_DATOS = m.ID_DATOS
JOIN AUDITORIA_ACCIONES aac ON aa.ID_AUDITORIA = aac.ID_AUDITORIA
JOIN ACCIONES ac ON aac.ID_ACCION = ac.ID_ACCION
WHERE ur.ID_DATOS = 110
  AND ac.CODIGO = 'APROBAR_EXPEDIENTE'
ORDER BY aa.FECHA_LOGIN;
```

**Resultado Esperado:**
| FECHA_LOGIN | OCA | ACCION | ENTIDAD | EXPEDIENTE_ID | RESULTADO |
|-------------|-----|--------|---------|---------------|-----------|
| 2025-03-15 | OCA Norte | Aprobar Expediente | EXPEDIENTE | 12345 | EXITO |
| 2025-07-20 | OCA Sur | Aprobar Expediente | EXPEDIENTE | 67890 | EXITO |

✅ **Validación:** Auditoría completa independientemente de cambios de OCA.

---

## 🏢 CASO 3: Carlos Martínez - Gestor de 3 Empresas Simultáneamente

### 📝 Descripción del Escenario

Carlos Martínez:
- Es **TITULAR** de su propia empresa (Gestión Martínez SL)
- Es **GESTOR** en 2 empresas más (Industrias ABC SA y Servicios XYZ SL)
- Debe poder cambiar de contexto entre empresas fácilmente

### 💾 Datos en las Tablas

#### 1️⃣ DATOS_PERSONALES

```sql
INSERT INTO DATOS_PERSONALES (
    ID_DATOS, IDENTIFICADOR, TIPO_IDENTIFICADOR, NOMBRE, APELLIDO1,
    EMAIL, TIPO_PERSONA, ACTIVO
) VALUES (
    120, '11223344C', 'NIF', 'Carlos', 'Martínez',
    'carlos.martinez@email.com', 'FISICA', 'Y'
);
```

---

#### 2️⃣ MAESTROS_USUARIOS (3 empresas)

```sql
-- Empresa propia
INSERT INTO MAESTROS_USUARIOS (
    ID_MAESTRO, ID_TIPO_MAESTRO, ID_DATOS, CODIGO_MAESTRO, ESTADO
) VALUES (
    220, 2, 120, 'EMP-GESTION-MARTINEZ', 'ACTIVO'
);

-- Empresa donde es gestor 1
INSERT INTO MAESTROS_USUARIOS (
    ID_MAESTRO, ID_TIPO_MAESTRO, ID_DATOS, CODIGO_MAESTRO, ESTADO
) VALUES (
    221, 2, 777, 'EMP-INDUSTRIAS-ABC', 'ACTIVO'
);

-- Empresa donde es gestor 2
INSERT INTO MAESTROS_USUARIOS (
    ID_MAESTRO, ID_TIPO_MAESTRO, ID_DATOS, CODIGO_MAESTRO, ESTADO
) VALUES (
    222, 2, 666, 'EMP-SERVICIOS-XYZ', 'ACTIVO'
);
```

---

#### 3️⃣ USUARIOS_RELACIONADOS (3 perfiles)

```sql
-- Perfil como TITULAR de su empresa
INSERT INTO USUARIOS_RELACIONADOS (
    ID_USUARIO_REL, ID_DATOS, ID_TIPO_RELACION, ID_MAESTRO, ESTADO, FECHA_ALTA
) VALUES (
    320, 120, 1, 220, 'ACTIVO', SYSTIMESTAMP -- 1=TITULAR
);

-- Perfil como GESTOR en Industrias ABC
INSERT INTO USUARIOS_RELACIONADOS (
    ID_USUARIO_REL, ID_DATOS, ID_TIPO_RELACION, ID_MAESTRO, ESTADO, 
    FECHA_ALTA, FECHA_APROBACION, USUARIO_APROBACION
) VALUES (
    321, 120, 5, 221, 'ACTIVO', 
    SYSTIMESTAMP, SYSTIMESTAMP, 'titular_abc' -- 5=GESTOR
);

-- Perfil como GESTOR en Servicios XYZ
INSERT INTO USUARIOS_RELACIONADOS (
    ID_USUARIO_REL, ID_DATOS, ID_TIPO_RELACION, ID_MAESTRO, ESTADO,
    FECHA_ALTA, FECHA_APROBACION, USUARIO_APROBACION
) VALUES (
    322, 120, 5, 222, 'ACTIVO',
    SYSTIMESTAMP, SYSTIMESTAMP, 'titular_xyz'
);
```

**Resultado:**
| ID_USUARIO_REL | PERSONA | PERFIL | EMPRESA | ESTADO | APROBADO POR |
|----------------|---------|--------|---------|--------|--------------|
| 320 | Carlos Martínez (120) | TITULAR | Gestión Martínez (220) | ACTIVO | - |
| 321 | Carlos Martínez (120) | GESTOR | Industrias ABC (221) | ACTIVO | titular_abc |
| 322 | Carlos Martínez (120) | GESTOR | Servicios XYZ (222) | ACTIVO | titular_xyz |

---

### 🔍 Consultas de Validación

#### Consulta 1: Selector de perfiles en el login

```sql
SELECT 
    ur.ID_USUARIO_REL AS PERFIL_ID,
    tr.NOMBRE AS TIPO_PERFIL,
    m.NOMBRE AS EMPRESA,
    mu.CODIGO_MAESTRO,
    CASE 
        WHEN tr.CODIGO = 'TITULAR' THEN 'Todos los permisos'
        WHEN tr.CODIGO = 'GESTOR' THEN 'Permisos de gestión'
        ELSE 'Permisos limitados'
    END AS DESCRIPCION_PERMISOS
FROM USUARIOS_RELACIONADOS ur
JOIN TIPOS_RELACION tr ON ur.ID_TIPO_RELACION = tr.ID_TIPO_RELACION
JOIN MAESTROS_USUARIOS mu ON ur.ID_MAESTRO = mu.ID_MAESTRO
LEFT JOIN DATOS_PERSONALES m ON mu.ID_DATOS = m.ID_DATOS
WHERE ur.ID_DATOS = 120
  AND ur.ESTADO = 'ACTIVO'
ORDER BY tr.NIVEL_JERARQUICO DESC, m.NOMBRE;
```

**Resultado Esperado (pantalla de selección de perfil):**
| PERFIL_ID | TIPO_PERFIL | EMPRESA | CODIGO | DESCRIPCION_PERMISOS |
|-----------|-------------|---------|--------|----------------------|
| 320 | TITULAR | Gestión Martínez SL | EMP-GESTION-MARTINEZ | Todos los permisos |
| 321 | GESTOR | Industrias ABC SA | EMP-INDUSTRIAS-ABC | Permisos de gestión |
| 322 | GESTOR | Servicios XYZ SL | EMP-SERVICIOS-XYZ | Permisos de gestión |

✅ **Validación:** Carlos ve 3 perfiles para elegir al iniciar sesión.

---

#### Consulta 2: Diferencias de permisos entre TITULAR y GESTOR

```sql
-- Permisos como TITULAR (perfil 320)
SELECT 'TITULAR' AS PERFIL, m.NOMBRE AS MENU, a.NOMBRE AS ACCION
FROM PERMISOS_RELACION_VERSION prv
JOIN VERSIONES_APLICACION va ON prv.ID_VERSION = va.ID_VERSION
JOIN MENUS m ON prv.ID_MENU = m.ID_MENU
JOIN ACCIONES a ON prv.ID_ACCION = a.ID_ACCION
WHERE prv.ID_TIPO_RELACION = 1 -- TITULAR
  AND va.ACTIVA = 'Y'
  AND prv.TIPO_PERMISO = 'PERMITIDO'

MINUS

-- Permisos como GESTOR (perfil 321)
SELECT 'GESTOR' AS PERFIL, m.NOMBRE AS MENU, a.NOMBRE AS ACCION
FROM PERMISOS_RELACION_VERSION prv
JOIN VERSIONES_APLICACION va ON prv.ID_VERSION = va.ID_VERSION
JOIN MENUS m ON prv.ID_MENU = m.ID_MENU
JOIN ACCIONES a ON prv.ID_ACCION = a.ID_ACCION
WHERE prv.ID_TIPO_RELACION = 5 -- GESTOR
  AND va.ACTIVA = 'Y'
  AND prv.TIPO_PERMISO = 'PERMITIDO';
```

**Resultado Esperado (acciones que SOLO tiene TITULAR):**
| PERFIL | MENU | ACCION |
|--------|------|--------|
| TITULAR | Gestión Empresa | Modificar Datos Empresa |
| TITULAR | Gestión Usuarios | Dar de Baja Gestor |
| TITULAR | Gestión Usuarios | Aprobar Apoderado |

✅ **Validación:** GESTOR tiene permisos limitados respecto a TITULAR.

---

## ❌ CASO 4: Ana Sánchez - Solicitud Rechazada y Posterior Aprobación

### 📝 Descripción del Escenario

Ana Sánchez:
- Solicita ser **TECNICO_OCA** en "OCA Centro" → **RECHAZADA** (no cumple requisitos)
- Posteriormente cumple requisitos y solicita de nuevo → **APROBADA**

### 💾 Datos en las Tablas

#### 1️⃣ DATOS_PERSONALES

```sql
INSERT INTO DATOS_PERSONALES (
    ID_DATOS, IDENTIFICADOR, TIPO_IDENTIFICADOR, NOMBRE, APELLIDO1,
    EMAIL, TIPO_PERSONA, ACTIVO
) VALUES (
    130, '99887766D', 'NIF', 'Ana', 'Sánchez',
    'ana.sanchez@email.com', 'FISICA', 'Y'
);
```

---

#### 2️⃣ MAESTROS_USUARIOS (OCA Centro)

```sql
INSERT INTO MAESTROS_USUARIOS (
    ID_MAESTRO, ID_TIPO_MAESTRO, ID_DATOS, CODIGO_MAESTRO, ESTADO
) VALUES (
    230, 3, 888, 'OCA-CENTRO', 50, 'ACTIVO' -- 3=OCA
);
```

---

#### 3️⃣ USUARIOS_RELACIONADOS (2 intentos: rechazado + aprobado)

```sql
-- Primera solicitud (RECHAZADA)
INSERT INTO USUARIOS_RELACIONADOS (
    ID_USUARIO_REL, ID_DATOS, ID_TIPO_RELACION, ID_MAESTRO, ESTADO,
    FECHA_ALTA, FECHA_BAJA, MOTIVO_BAJA
) VALUES (
    330, 130, 3, 230, 'RECHAZADO',
    TO_TIMESTAMP('2025-03-01', 'YYYY-MM-DD'),
    TO_TIMESTAMP('2025-03-05', 'YYYY-MM-DD'),
    'No acredita titulación requerida'
);

-- Segunda solicitud (APROBADA)
INSERT INTO USUARIOS_RELACIONADOS (
    ID_USUARIO_REL, ID_DATOS, ID_TIPO_RELACION, ID_MAESTRO, ESTADO,
    FECHA_ALTA, FECHA_APROBACION, USUARIO_APROBACION
) VALUES (
    331, 130, 3, 230, 'ACTIVO',
    TO_TIMESTAMP('2025-05-15', 'YYYY-MM-DD'),
    TO_TIMESTAMP('2025-05-18', 'YYYY-MM-DD'),
    'responsable_oca_centro'
);
```

**Resultado:**
| ID_USUARIO_REL | PERSONA | PERFIL | OCA | ESTADO | FECHA_SOLICITUD | FECHA_RESOLUCIÓN | MOTIVO |
|----------------|---------|--------|-----|--------|-----------------|------------------|--------|
| 330 | Ana Sánchez (130) | TECNICO_OCA | OCA Centro | RECHAZADO | 2025-03-01 | 2025-03-05 | No acredita titulación |
| 331 | Ana Sánchez (130) | TECNICO_OCA | OCA Centro | ACTIVO | 2025-05-15 | 2025-05-18 | - |

---

### 🔍 Consultas de Validación

#### Consulta 1: Histórico de solicitudes de Ana

```sql
SELECT 
    dp.NOMBRE_COMPLETO,
    tr.NOMBRE AS PERFIL_SOLICITADO,
    m.NOMBRE AS OCA,
    ur.ESTADO,
    ur.FECHA_ALTA AS FECHA_SOLICITUD,
    COALESCE(ur.FECHA_APROBACION, ur.FECHA_BAJA) AS FECHA_RESOLUCION,
    CASE 
        WHEN ur.ESTADO = 'RECHAZADO' THEN ur.MOTIVO_BAJA
        WHEN ur.ESTADO = 'ACTIVO' THEN 'Aprobado por ' || ur.USUARIO_APROBACION
        ELSE 'Pendiente'
    END AS RESULTADO
FROM DATOS_PERSONALES dp
JOIN USUARIOS_RELACIONADOS ur ON dp.ID_DATOS = ur.ID_DATOS
JOIN TIPOS_RELACION tr ON ur.ID_TIPO_RELACION = tr.ID_TIPO_RELACION
JOIN MAESTROS_USUARIOS mu ON ur.ID_MAESTRO = mu.ID_MAESTRO
LEFT JOIN DATOS_PERSONALES m ON mu.ID_DATOS = m.ID_DATOS
WHERE dp.IDENTIFICADOR = '99887766D'
ORDER BY ur.FECHA_ALTA;
```

**Resultado Esperado:**
| NOMBRE_COMPLETO | PERFIL_SOLICITADO | OCA | ESTADO | FECHA_SOLICITUD | FECHA_RESOLUCION | RESULTADO |
|-----------------|-------------------|-----|--------|-----------------|------------------|-----------|
| Ana Sánchez | TECNICO_OCA | OCA Centro | RECHAZADO | 2025-03-01 | 2025-03-05 | No acredita titulación requerida |
| Ana Sánchez | TECNICO_OCA | OCA Centro | ACTIVO | 2025-05-15 | 2025-05-18 | Aprobado por responsable_oca_centro |

✅ **Validación:** Histórico completo de solicitudes con trazabilidad de rechazos.

---

#### Consulta 2: Solicitudes pendientes de aprobación (para responsables)

```sql
SELECT 
    dp.NOMBRE_COMPLETO,
    dp.EMAIL,
    tr.NOMBRE AS PERFIL_SOLICITADO,
    m.NOMBRE AS ENTIDAD,
    ur.FECHA_ALTA AS FECHA_SOLICITUD,
    TRUNC(SYSDATE) - TRUNC(ur.FECHA_ALTA) AS DIAS_PENDIENTE
FROM USUARIOS_RELACIONADOS ur
JOIN DATOS_PERSONALES dp ON ur.ID_DATOS = dp.ID_DATOS
JOIN TIPOS_RELACION tr ON ur.ID_TIPO_RELACION = tr.ID_TIPO_RELACION
JOIN MAESTROS_USUARIOS mu ON ur.ID_MAESTRO = mu.ID_MAESTRO
LEFT JOIN DATOS_PERSONALES m ON mu.ID_DATOS = m.ID_DATOS
WHERE ur.ESTADO = 'PENDIENTE'
  AND tr.REQUIERE_APROBACION = 'Y'
ORDER BY ur.FECHA_ALTA;
```

**Resultado Esperado:**
| NOMBRE_COMPLETO | EMAIL | PERFIL_SOLICITADO | ENTIDAD | FECHA_SOLICITUD | DIAS_PENDIENTE |
|-----------------|-------|-------------------|---------|-----------------|----------------|
| Pedro Ruiz | pedro@email.com | TECNICO_OCA | OCA Norte | 2025-10-15 | 37 |
| Laura Moreno | laura@email.com | APODERADO | Construcciones SA | 2025-11-05 | 16 |

✅ **Validación:** Los responsables ven solicitudes pendientes de aprobación.

---

## 🎭 CASO 5: Roberto Díaz - Titular, Empresa, Técnico OCA y Responsable Servicio

### 📝 Descripción del Escenario (Máxima Complejidad)

Roberto Díaz tiene **4 perfiles simultáneos**:
1. **TITULAR individual** (expedientes personales)
2. **TITULAR de empresa** (Ingeniería Díaz SL)
3. **TECNICO_OCA** en OCA Este
4. **RESPONSABLE_SERVICIO** en Servicio de Urbanismo

### 💾 Datos en las Tablas

#### 1️⃣ DATOS_PERSONALES

```sql
INSERT INTO DATOS_PERSONALES (
    ID_DATOS, IDENTIFICADOR, TIPO_IDENTIFICADOR, NOMBRE, APELLIDO1,
    EMAIL, TIPO_PERSONA, ACTIVO
) VALUES (
    140, '55667788E', 'NIF', 'Roberto', 'Díaz',
    'roberto.diaz@aragon.es', 'FISICA', 'Y'
);
```

---

#### 2️⃣ MAESTROS_USUARIOS

```sql
-- Empresa de Roberto
INSERT INTO MAESTROS_USUARIOS VALUES (
    240, 2, 140, 'EMP-INGENIERIA-DIAZ', 50, 'ACTIVO'
);

-- OCA Este
INSERT INTO MAESTROS_USUARIOS VALUES (
    241, 3, 888, 'OCA-ESTE', 44, 'ACTIVO'
);

-- Servicio de Urbanismo
INSERT INTO MAESTROS_USUARIOS VALUES (
    242, 4, 888, 'SERV-URBANISMO', 50, 'ACTIVO' -- 4=SERVICIO
);
```

---

#### 3️⃣ USUARIOS_RELACIONADOS (4 perfiles)

```sql
-- Perfil 1: TITULAR individual
INSERT INTO USUARIOS_RELACIONADOS VALUES (
    340, 140, 1, NULL, 'ACTIVO', SYSTIMESTAMP, NULL, NULL, NULL, NULL, NULL
);

-- Perfil 2: TITULAR de empresa
INSERT INTO USUARIOS_RELACIONADOS VALUES (
    341, 140, 1, 240, 'ACTIVO', SYSTIMESTAMP, NULL, NULL, NULL, NULL, NULL
);

-- Perfil 3: TECNICO_OCA
INSERT INTO USUARIOS_RELACIONADOS VALUES (
    342, 140, 3, 241, 'ACTIVO', SYSTIMESTAMP, NULL, SYSTIMESTAMP, 'jefe_oca_este', NULL, NULL
);

-- Perfil 4: RESPONSABLE_SERVICIO
INSERT INTO USUARIOS_RELACIONADOS VALUES (
    343, 140, 6, 242, 'ACTIVO', SYSTIMESTAMP, NULL, SYSTIMESTAMP, 'director_general', NULL, NULL
);
```

**Resultado:**
| ID_USUARIO_REL | PERFIL | ENTIDAD | NIVEL_JERARQUICO | ESTADO |
|----------------|--------|---------|------------------|--------|
| 340 | TITULAR | - (individual) | 1 | ACTIVO |
| 341 | TITULAR | Ingeniería Díaz | 1 | ACTIVO |
| 342 | TECNICO_OCA | OCA Este | 3 | ACTIVO |
| 343 | RESPONSABLE_SERVICIO | Servicio Urbanismo | 5 | ACTIVO |

---

### 🔍 Consultas de Validación

#### Consulta 1: Matriz de permisos por perfil

```sql
SELECT 
    tr.NOMBRE AS PERFIL,
    COUNT(DISTINCT prv.ID_MENU) AS MENUS_ACCESIBLES,
    COUNT(DISTINCT prv.ID_ACCION) AS ACCIONES_PERMITIDAS,
    LISTAGG(DISTINCT a.NOMBRE, ', ') WITHIN GROUP (ORDER BY a.NOMBRE) AS ACCIONES_CRITICAS
FROM USUARIOS_RELACIONADOS ur
JOIN TIPOS_RELACION tr ON ur.ID_TIPO_RELACION = tr.ID_TIPO_RELACION
JOIN PERMISOS_RELACION_VERSION prv ON tr.ID_TIPO_RELACION = prv.ID_TIPO_RELACION
JOIN VERSIONES_APLICACION va ON prv.ID_VERSION = va.ID_VERSION
JOIN ACCIONES a ON prv.ID_ACCION = a.ID_ACCION
WHERE ur.ID_DATOS = 140
  AND ur.ESTADO = 'ACTIVO'
  AND va.ACTIVA = 'Y'
  AND prv.TIPO_PERMISO = 'PERMITIDO'
  AND a.TIPO_ACCION IN ('APROBAR', 'FIRMAR', 'RECHAZAR')
GROUP BY tr.NOMBRE, tr.NIVEL_JERARQUICO
ORDER BY tr.NIVEL_JERARQUICO DESC;
```

**Resultado Esperado:**
| PERFIL | MENUS_ACCESIBLES | ACCIONES_PERMITIDAS | ACCIONES_CRITICAS |
|--------|------------------|---------------------|-------------------|
| RESPONSABLE_SERVICIO | 15 | 45 | Aprobar Expediente, Firmar Resolución, Rechazar Solicitud |
| TECNICO_OCA | 8 | 20 | Aprobar Expediente, Firmar Informe |
| TITULAR | 5 | 12 | Firmar Expediente |

✅ **Validación:** Cada perfil tiene permisos diferenciados según nivel jerárquico.

---

#### Consulta 2: Auditoría de acciones con cambio de perfil

```sql
SELECT 
    TO_CHAR(aa.FECHA_LOGIN, 'YYYY-MM-DD HH24:MI') AS FECHA_HORA,
    tr.NOMBRE AS PERFIL_USADO,
    m.NOMBRE AS ENTIDAD,
    ac.NOMBRE AS ACCION_REALIZADA,
    aac.ENTIDAD_AFECTADA,
    aac.ID_REGISTRO
FROM AUDITORIA_ACCESOS aa
JOIN USUARIOS_RELACIONADOS ur ON aa.ID_USUARIO_REL = ur.ID_USUARIO_REL
JOIN TIPOS_RELACION tr ON ur.ID_TIPO_RELACION = tr.ID_TIPO_RELACION
LEFT JOIN MAESTROS_USUARIOS mu ON ur.ID_MAESTRO = mu.ID_MAESTRO
LEFT JOIN DATOS_PERSONALES m ON mu.ID_DATOS = m.ID_DATOS
JOIN AUDITORIA_ACCIONES aac ON aa.ID_AUDITORIA = aac.ID_AUDITORIA
JOIN ACCIONES ac ON aac.ID_ACCION = ac.ID_ACCION
WHERE ur.ID_DATOS = 140
  AND aa.FECHA_LOGIN >= TRUNC(SYSDATE)
ORDER BY aa.FECHA_LOGIN, aac.FECHA_ACCION;
```

**Resultado Esperado (día completo con cambios de perfil):**
| FECHA_HORA | PERFIL_USADO | ENTIDAD | ACCION_REALIZADA | ENTIDAD_AFECTADA | ID_REGISTRO |
|------------|--------------|---------|------------------|------------------|-------------|
| 2025-11-21 09:00 | TITULAR | Ingeniería Díaz | Crear Expediente | EXPEDIENTE | 11111 |
| 2025-11-21 10:30 | TECNICO_OCA | OCA Este | Aprobar Expediente | EXPEDIENTE | 22222 |
| 2025-11-21 14:15 | RESPONSABLE_SERVICIO | Servicio Urbanismo | Firmar Resolución | RESOLUCION | 33333 |
| 2025-11-21 16:45 | TITULAR | (Individual) | Firmar Expediente | EXPEDIENTE | 44444 |

✅ **Validación:** Auditoría diferencia claramente con qué perfil actuó en cada momento.

---

## 🔄 CASO 6: Evolución de Permisos entre v1.0 y v2.0

### 📝 Descripción del Escenario

La aplicación evoluciona de **v1.0** a **v2.0**:
- **v1.0:** TITULAR puede firmar expedientes propios únicamente
- **v2.0:** TITULAR puede delegar firma en APODERADO

### 💾 Datos en las Tablas

#### 1️⃣ VERSIONES_APLICACION

```sql
INSERT INTO VERSIONES_APLICACION VALUES (
    1, 'v1.0', 'Versión inicial', 'Primera versión en producción', TO_DATE('2024-01-01', 'YYYY-MM-DD'), 'N'
);

INSERT INTO VERSIONES_APLICACION VALUES (
    2, 'v2.0', 'Delegación de firma', 'Permite delegar firma en apoderados', TO_DATE('2025-06-01', 'YYYY-MM-DD'), 'Y'
);
```

---

#### 2️⃣ MENUS

```sql
INSERT INTO MENUS VALUES (
    10, 'MENU_MIS_EXPEDIENTES', 'Mis Expedientes', NULL, '/expedientes', 1, 'Y'
);

INSERT INTO MENUS VALUES (
    11, 'MENU_DELEGACION_FIRMA', 'Delegación de Firma', NULL, '/delegacion', 8, 'Y' -- Solo en v2.0
);
```

---

#### 3️⃣ ACCIONES

```sql
INSERT INTO ACCIONES VALUES (
    20, 'FIRMAR_EXPEDIENTE', 'Firmar Expediente', 'Firma digital', 'FIRMAR', 'Y'
);

INSERT INTO ACCIONES VALUES (
    21, 'DELEGAR_FIRMA', 'Delegar Firma', 'Autorizar apoderado para firmar', 'APROBAR', 'Y'
);
```

---

#### 4️⃣ PERMISOS_RELACION_VERSION (evolución)

```sql
-- v1.0: TITULAR puede firmar
INSERT INTO PERMISOS_RELACION_VERSION VALUES (
    100, 1, 1, 10, 20, 'PERMITIDO', NULL, 'Y', SYSTIMESTAMP, 'admin'
);

-- v2.0: TITULAR puede firmar (heredado)
INSERT INTO PERMISOS_RELACION_VERSION VALUES (
    101, 1, 2, 10, 20, 'PERMITIDO', NULL, 'Y', SYSTIMESTAMP, 'admin'
);

-- v2.0: TITULAR puede delegar firma (NUEVO)
INSERT INTO PERMISOS_RELACION_VERSION VALUES (
    102, 1, 2, 11, 21, 'PERMITIDO', JSON_OBJECT('requiere_certificado' VALUE 'Y'), 'Y', SYSTIMESTAMP, 'admin'
);
```

**Resultado:**
| ID_PERMISO | PERFIL | VERSION | MENU | ACCION | NUEVO_EN_V2 |
|------------|--------|---------|------|--------|-------------|
| 100 | TITULAR | v1.0 | Mis Expedientes | Firmar Expediente | No |
| 101 | TITULAR | v2.0 | Mis Expedientes | Firmar Expediente | No |
| 102 | TITULAR | v2.0 | Delegación Firma | Delegar Firma | **SÍ** |

---

### 🔍 Consultas de Validación

#### Consulta 1: Comparativa de permisos entre versiones

```sql
SELECT 
    va.CODIGO_VERSION,
    m.NOMBRE AS MENU,
    a.NOMBRE AS ACCION,
    prv.TIPO_PERMISO,
    CASE WHEN va.ACTIVA = 'Y' THEN '✅ ACTIVA' ELSE '❌ INACTIVA' END AS ESTADO_VERSION
FROM PERMISOS_RELACION_VERSION prv
JOIN VERSIONES_APLICACION va ON prv.ID_VERSION = va.ID_VERSION
JOIN MENUS m ON prv.ID_MENU = m.ID_MENU
JOIN ACCIONES a ON prv.ID_ACCION = a.ID_ACCION
WHERE prv.ID_TIPO_RELACION = 1 -- TITULAR
  AND prv.TIPO_PERMISO = 'PERMITIDO'
ORDER BY va.FECHA_PUBLICACION, m.ORDEN;
```

**Resultado Esperado:**
| CODIGO_VERSION | MENU | ACCION | TIPO_PERMISO | ESTADO_VERSION |
|----------------|------|--------|--------------|----------------|
| v1.0 | Mis Expedientes | Firmar Expediente | PERMITIDO | ❌ INACTIVA |
| v2.0 | Mis Expedientes | Firmar Expediente | PERMITIDO | ✅ ACTIVA |
| v2.0 | Delegación Firma | Delegar Firma | PERMITIDO | ✅ ACTIVA |

✅ **Validación:** Los usuarios solo ven permisos de la versión activa (v2.0).

---

#### Consulta 2: Nuevos permisos disponibles en v2.0

```sql
SELECT 
    tr.NOMBRE AS PERFIL,
    m.NOMBRE AS MENU_NUEVO,
    a.NOMBRE AS ACCION_NUEVA,
    prv.CONDICIONES
FROM PERMISOS_RELACION_VERSION prv
JOIN TIPOS_RELACION tr ON prv.ID_TIPO_RELACION = tr.ID_TIPO_RELACION
JOIN MENUS m ON prv.ID_MENU = m.ID_MENU
JOIN ACCIONES a ON prv.ID_ACCION = a.ID_ACCION
WHERE prv.ID_VERSION = 2 -- v2.0
  AND NOT EXISTS (
      SELECT 1 FROM PERMISOS_RELACION_VERSION prv2
      WHERE prv2.ID_TIPO_RELACION = prv.ID_TIPO_RELACION
        AND prv2.ID_MENU = prv.ID_MENU
        AND prv2.ID_ACCION = prv.ID_ACCION
        AND prv2.ID_VERSION = 1 -- No existía en v1.0
  )
  AND prv.TIPO_PERMISO = 'PERMITIDO'
ORDER BY tr.NIVEL_JERARQUICO DESC;
```

**Resultado Esperado:**
| PERFIL | MENU_NUEVO | ACCION_NUEVA | CONDICIONES |
|--------|------------|--------------|-------------|
| TITULAR | Delegación Firma | Delegar Firma | {"requiere_certificado":"Y"} |
| APODERADO | Mis Expedientes | Firmar Expediente Delegado | {"solo_delegados":"Y"} |

✅ **Validación:** Se identifican funcionalidades nuevas entre versiones.

---

## 🔍 CASO 7: Auditoría de Acciones Críticas de un Técnico OCA

### 📝 Descripción del Escenario

Investigar todas las acciones críticas de Elena Ruiz (TECNICO_OCA) en los últimos 3 meses:
- Aprobaciones de expedientes
- Rechazos con justificación
- Modificaciones de datos

### 💾 Datos en las Tablas

#### 1️⃣ DATOS_PERSONALES

```sql
INSERT INTO DATOS_PERSONALES VALUES (
    150, '33445566F', 'NIF', 'Elena', 'Ruiz', NULL,
    'elena.ruiz@oca.aragon.es', NULL, 'FISICA', NULL, SYSTIMESTAMP, NULL, 'Y'
);
```

---

#### 2️⃣ USUARIOS_RELACIONADOS

```sql
INSERT INTO USUARIOS_RELACIONADOS VALUES (
    350, 150, 3, 210, 'ACTIVO', 
    TO_TIMESTAMP('2024-06-01', 'YYYY-MM-DD'), 
    NULL, TO_TIMESTAMP('2024-06-05', 'YYYY-MM-DD'), 'responsable_oca', NULL, NULL
);
```

---

#### 3️⃣ AUDITORIA_ACCESOS

```sql
INSERT INTO AUDITORIA_ACCESOS VALUES (
    600, 350, 'SES-2025-001', 'CERTIFICADO_DIGITAL', '192.168.1.50', 'Firefox', 'Desktop',
    TO_TIMESTAMP('2025-11-15 09:00', 'YYYY-MM-DD HH24:MI'), 
    TO_TIMESTAMP('2025-11-15 14:30', 'YYYY-MM-DD HH24:MI'),
    19800 -- 5.5 horas
);

INSERT INTO AUDITORIA_ACCESOS VALUES (
    601, 350, 'SES-2025-002', 'CERTIFICADO_DIGITAL', '192.168.1.50', 'Firefox', 'Desktop',
    TO_TIMESTAMP('2025-11-18 10:00', 'YYYY-MM-DD HH24:MI'),
    TO_TIMESTAMP('2025-11-18 17:00', 'YYYY-MM-DD HH24:MI'),
    25200 -- 7 horas
);
```

---

#### 4️⃣ AUDITORIA_ACCIONES (acciones críticas)

```sql
-- Aprobación de expediente
INSERT INTO AUDITORIA_ACCIONES VALUES (
    700, 600, 5, 'EXPEDIENTE', 55555,
    JSON_OBJECT('estado' VALUE 'PENDIENTE'),
    JSON_OBJECT('estado' VALUE 'APROBADO', 'fecha_aprobacion' VALUE '2025-11-15'),
    'EXITO', NULL, TO_TIMESTAMP('2025-11-15 10:30', 'YYYY-MM-DD HH24:MI')
);

-- Rechazo de expediente
INSERT INTO AUDITORIA_ACCIONES VALUES (
    701, 600, 6, 'EXPEDIENTE', 66666,
    JSON_OBJECT('estado' VALUE 'PENDIENTE'),
    JSON_OBJECT('estado' VALUE 'RECHAZADO', 'motivo' VALUE 'Documentación incompleta'),
    'EXITO', NULL, TO_TIMESTAMP('2025-11-15 12:00', 'YYYY-MM-DD HH24:MI')
);

-- Modificación de expediente
INSERT INTO AUDITORIA_ACCIONES VALUES (
    702, 601, 3, 'EXPEDIENTE', 77777,
    JSON_OBJECT('importe' VALUE 10000),
    JSON_OBJECT('importe' VALUE 12000, 'observaciones' VALUE 'Revisión presupuesto'),
    'EXITO', NULL, TO_TIMESTAMP('2025-11-18 11:45', 'YYYY-MM-DD HH24:MI')
);

-- Intento de eliminación (ERROR)
INSERT INTO AUDITORIA_ACCIONES VALUES (
    703, 601, 4, 'EXPEDIENTE', 88888,
    JSON_OBJECT('estado' VALUE 'BORRADOR'),
    NULL,
    'ERROR', 'Expediente tiene documentos adjuntos', 
    TO_TIMESTAMP('2025-11-18 15:20', 'YYYY-MM-DD HH24:MI')
);
```

---

### 🔍 Consultas de Validación

#### Consulta 1: Informe completo de acciones críticas

```sql
SELECT 
    TO_CHAR(aac.FECHA_ACCION, 'YYYY-MM-DD HH24:MI') AS FECHA_HORA,
    ac.NOMBRE AS ACCION,
    aac.ENTIDAD_AFECTADA AS TIPO_ENTIDAD,
    aac.ID_REGISTRO AS REGISTRO_ID,
    aac.DATOS_ANTERIORES,
    aac.DATOS_NUEVOS,
    aac.RESULTADO,
    aac.MENSAJE_ERROR,
    aa.TIPO_AUTENTICACION,
    aa.IP_ORIGEN
FROM AUDITORIA_ACCESOS aa
JOIN USUARIOS_RELACIONADOS ur ON aa.ID_USUARIO_REL = ur.ID_USUARIO_REL
JOIN AUDITORIA_ACCIONES aac ON aa.ID_AUDITORIA = aac.ID_AUDITORIA
JOIN ACCIONES ac ON aac.ID_ACCION = ac.ID_ACCION
WHERE ur.ID_DATOS = 150
  AND aac.FECHA_ACCION >= ADD_MONTHS(TRUNC(SYSDATE), -3)
  AND ac.TIPO_ACCION IN ('APROBAR', 'RECHAZAR', 'ELIMINAR')
ORDER BY aac.FECHA_ACCION DESC;
```

**Resultado Esperado:**
| FECHA_HORA | ACCION | TIPO_ENTIDAD | REGISTRO_ID | DATOS_ANTERIORES | DATOS_NUEVOS | RESULTADO | MENSAJE_ERROR | AUTENTICACION | IP |
|------------|--------|--------------|-------------|------------------|--------------|-----------|---------------|---------------|-----|
| 2025-11-18 15:20 | Eliminar | EXPEDIENTE | 88888 | {"estado":"BORRADOR"} | NULL | ERROR | Expediente tiene documentos | CERTIFICADO | 192.168.1.50 |
| 2025-11-15 12:00 | Rechazar | EXPEDIENTE | 66666 | {"estado":"PENDIENTE"} | {"estado":"RECHAZADO","motivo":"Documentación incompleta"} | EXITO | NULL | CERTIFICADO | 192.168.1.50 |
| 2025-11-15 10:30 | Aprobar | EXPEDIENTE | 55555 | {"estado":"PENDIENTE"} | {"estado":"APROBADO","fecha_aprobacion":"2025-11-15"} | EXITO | NULL | CERTIFICADO | 192.168.1.50 |

✅ **Validación:** Auditoría completa con datos antes/después y trazabilidad de errores.

---

#### Consulta 2: Estadísticas de acciones del técnico

```sql
SELECT 
    ac.TIPO_ACCION,
    aac.RESULTADO,
    COUNT(*) AS TOTAL_ACCIONES,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS PORCENTAJE
FROM AUDITORIA_ACCESOS aa
JOIN USUARIOS_RELACIONADOS ur ON aa.ID_USUARIO_REL = ur.ID_USUARIO_REL
JOIN AUDITORIA_ACCIONES aac ON aa.ID_AUDITORIA = aac.ID_AUDITORIA
JOIN ACCIONES ac ON aac.ID_ACCION = ac.ID_ACCION
WHERE ur.ID_DATOS = 150
  AND aac.FECHA_ACCION >= ADD_MONTHS(TRUNC(SYSDATE), -3)
GROUP BY ac.TIPO_ACCION, aac.RESULTADO
ORDER BY TOTAL_ACCIONES DESC;
```

**Resultado Esperado:**
| TIPO_ACCION | RESULTADO | TOTAL_ACCIONES | PORCENTAJE |
|-------------|-----------|----------------|------------|
| APROBAR | EXITO | 45 | 62.50% |
| EDITAR | EXITO | 18 | 25.00% |
| RECHAZAR | EXITO | 7 | 9.72% |
| ELIMINAR | ERROR | 2 | 2.78% |

✅ **Validación:** Métricas de productividad y tasa de error.

---

## 📊 RESUMEN DE VALIDACIONES

### ✅ Objetivos Cumplidos

| Requisito | Validado en Caso | Resultado |
|-----------|------------------|-----------|
| **Múltiples perfiles por usuario** | Caso 1, 3, 5 | ✅ Soportado completamente |
| **Perfil individual + empresas** | Caso 1 | ✅ TITULAR individual + 3 empresas |
| **Cambio de entidad (histórico)** | Caso 2 | ✅ Histórico completo con fechas |
| **Aprobación de solicitudes** | Caso 4 | ✅ Flujo PENDIENTE → RECHAZADO/ACTIVO |
| **Múltiples perfiles simultáneos** | Caso 5 | ✅ 4 perfiles activos simultáneos |
| **Versionado de permisos** | Caso 6 | ✅ Evolución v1.0 → v2.0 sin duplicar datos |
| **Auditoría completa** | Caso 7 | ✅ Trazabilidad completa con datos antes/después |
| **Cambio de contexto** | Caso 3 | ✅ Selector de perfiles en login |
| **Permisos diferenciados** | Caso 3, 5 | ✅ TITULAR ≠ GESTOR ≠ TECNICO_OCA |
| **Trazabilidad de rechazos** | Caso 4 | ✅ Histórico de solicitudes rechazadas |

---

## 🎯 CONCLUSIONES

### ✅ Fortalezas del Modelo

1. **Flexibilidad total**: Soporta desde usuarios simples hasta escenarios complejos multi-perfil
2. **Histórico completo**: No se pierde información al cambiar de entidad/perfil
3. **Auditoría robusta**: JSON en `DATOS_ANTERIORES` y `DATOS_NUEVOS` permite reconstruir cualquier cambio
4. **Escalabilidad**: Añadir nuevos perfiles/versiones sin modificar código existente
5. **Integridad**: Foreign keys + unique constraints evitan duplicados e inconsistencias

### ⚠️ Consideraciones de Implementación

1. **Consultas complejas**: Algunos reportes requieren múltiples JOINs (optimizar con vistas)
2. **Gestión de JSON**: Requiere validación en aplicación y base de datos
3. **Particionado**: Auditoría debe particionarse mensualmente para mantener rendimiento
4. **Índices**: Crear índices adicionales según patrones de uso real

---

**Generado por:** GitHub Copilot  
**Fecha:** 21 de Noviembre de 2025  
**Versión:** 1.0  
**Relacionado con:**
- PropuestaFinal_GestionUsuarios_INDAR.md
- DiagramaUML_GestionUsuarios_INDAR.md
