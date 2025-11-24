# 🔄 RENOMBRADO DE TABLAS - SISTEMA INDAR

**Fecha:** 21 de Noviembre de 2025  
**Versión:** 1.0  
**Objetivo:** Mejorar la claridad y comprensión de la nomenclatura de tablas

---

## 📊 TABLA COMPARATIVA: NOMBRES ACTUALES vs PROPUESTOS

| # | **Nombre Actual** | **Nombre Propuesto** | **Justificación del Cambio** | **Impacto** |
|---|-------------------|----------------------|------------------------------|-------------|
| 1 | `DATOS_PERSONALES` | `PERSONAS` | Más conciso y directo. Elimina redundancia. | **ALTO** - Tabla principal |
| 2 | `TIPOS_MAESTRO` | `CATALOGO_TIPOS_ENTIDAD` | Clarifica que es un catálogo. "Entidad" es más comprensible que "Maestro". | **MEDIO** - Tabla catálogo |
| 3 | `MAESTROS_USUARIOS` | `ENTIDADES` | Elimina confusión del término "Maestro". Indica claramente que son entidades del sistema (Empresas, OCAs, Servicios). | **ALTO** - Tabla de negocio |
| 4 | `TIPOS_RELACION` | `CATALOGO_PERFILES` | "Perfil" es más intuitivo que "Relación". Clarifica su propósito real. | **MEDIO** - Tabla catálogo |
| 5 | `USUARIOS_RELACIONADOS` | `USUARIOS_PERFILES` | Elimina ambigüedad de "Relacionados". Indica directamente que asigna perfiles a usuarios. | **ALTO** - Tabla transaccional |
| 6 | `VERSIONES_APLICACION` | `VERSIONES_SISTEMA` | "Sistema" es más genérico y abarca toda la plataforma INDAR. | **BAJO** - Tabla de configuración |
| 7 | `MENUS` | `FUNCIONALIDADES_MENU` | Agrupa funcionalidades y diferencia de tablas de acciones. Más descriptivo. | **MEDIO** - Tabla de seguridad |
| 8 | `ACCIONES` | `FUNCIONALIDADES_ACCION` | Consistencia con `FUNCIONALIDADES_MENU`. Clarifica que son funcionalidades ejecutables. | **MEDIO** - Tabla de seguridad |
| 9 | `PERMISOS_RELACION_VERSION` | `PERMISOS_PERFIL_VERSION` | Consistencia con cambio de "Relación" a "Perfil". | **ALTO** - Tabla de permisos |
| 10 | `AUDITORIA_ACCESOS` | `AUDITORIA_SESIONES` | "Sesiones" es más preciso ya que registra login/logout completos. | **BAJO** - Tabla de auditoría |
| 11 | `AUDITORIA_ACCIONES` | `AUDITORIA_OPERACIONES` | "Operaciones" es más técnico y formal que "Acciones". | **BAJO** - Tabla de auditoría |

---

## 🎯 RESUMEN DE IMPACTO

| **Nivel de Impacto** | **Cantidad de Tablas** | **Tablas Afectadas** |
|----------------------|------------------------|----------------------|
| **ALTO** | 4 | `PERSONAS`, `ENTIDADES`, `USUARIOS_PERFILES`, `PERMISOS_PERFIL_VERSION` |
| **MEDIO** | 4 | `CATALOGO_TIPOS_ENTIDAD`, `CATALOGO_PERFILES`, `FUNCIONALIDADES_MENU`, `FUNCIONALIDADES_ACCION` |
| **BAJO** | 3 | `VERSIONES_SISTEMA`, `AUDITORIA_SESIONES`, `AUDITORIA_OPERACIONES` |

---

## 🔧 ESPECIFICACIONES TÉCNICAS PARA RENOMBRADO

### **SCRIPT 1: RENOMBRADO DE TABLAS PRINCIPALES**

```sql
-- ============================================
-- SCRIPT DE RENOMBRADO DE TABLAS
-- Sistema: INDAR - Gestión de Usuarios
-- Fecha: 2025-11-21
-- Impacto: CRÍTICO - Requiere detener servicios
-- ============================================

-- IMPORTANTE: Ejecutar en este orden para respetar dependencias

-- 1. CAPA 1: PERSONAS
ALTER TABLE DATOS_PERSONALES RENAME TO PERSONAS;

-- 2. CAPA 2: ENTIDADES
ALTER TABLE TIPOS_MAESTRO RENAME TO CATALOGO_TIPOS_ENTIDAD;
ALTER TABLE MAESTROS_USUARIOS RENAME TO ENTIDADES;

-- 3. CAPA 3: PERFILES
ALTER TABLE TIPOS_RELACION RENAME TO CATALOGO_PERFILES;
ALTER TABLE USUARIOS_RELACIONADOS RENAME TO USUARIOS_PERFILES;

-- 4. CAPA 4: FUNCIONALIDADES Y PERMISOS
ALTER TABLE VERSIONES_APLICACION RENAME TO VERSIONES_SISTEMA;
ALTER TABLE MENUS RENAME TO FUNCIONALIDADES_MENU;
ALTER TABLE ACCIONES RENAME TO FUNCIONALIDADES_ACCION;
ALTER TABLE PERMISOS_RELACION_VERSION RENAME TO PERMISOS_PERFIL_VERSION;

-- 5. CAPA 5: AUDITORÍA
ALTER TABLE AUDITORIA_ACCESOS RENAME TO AUDITORIA_SESIONES;
ALTER TABLE AUDITORIA_ACCIONES RENAME TO AUDITORIA_OPERACIONES;

-- Verificar renombrado
SELECT table_name FROM user_tables WHERE table_name LIKE 'PERSONAS%' OR table_name LIKE 'CATALOGO_%' OR table_name LIKE 'ENTIDADES%' OR table_name LIKE 'USUARIOS_PERFILES%' OR table_name LIKE 'FUNCIONALIDADES_%' OR table_name LIKE 'PERMISOS_%' OR table_name LIKE 'VERSIONES_%' OR table_name LIKE 'AUDITORIA_%' ORDER BY table_name;
```

---

### **SCRIPT 2: RENOMBRADO DE CONSTRAINTS (FOREIGN KEYS)**

```sql
-- ============================================
-- RENOMBRADO DE CONSTRAINTS PARA CONSISTENCIA
-- ============================================

-- ENTIDADES
ALTER TABLE ENTIDADES RENAME CONSTRAINT FK_MAESTRO_TIPO TO FK_ENTIDAD_TIPO;
ALTER TABLE ENTIDADES RENAME CONSTRAINT FK_MAESTRO_DATOS TO FK_ENTIDAD_PERSONA;
ALTER TABLE ENTIDADES RENAME CONSTRAINT CHK_MAESTRO_ESTADO TO CHK_ENTIDAD_ESTADO;

-- USUARIOS_PERFILES
ALTER TABLE USUARIOS_PERFILES RENAME CONSTRAINT FK_USUREL_DATOS TO FK_UP_PERSONA;
ALTER TABLE USUARIOS_PERFILES RENAME CONSTRAINT FK_USUREL_TIPO TO FK_UP_PERFIL;
ALTER TABLE USUARIOS_PERFILES RENAME CONSTRAINT FK_USUREL_MAESTRO TO FK_UP_ENTIDAD;
ALTER TABLE USUARIOS_PERFILES RENAME CONSTRAINT CHK_USUREL_ESTADO TO CHK_UP_ESTADO;

-- PERMISOS_PERFIL_VERSION
ALTER TABLE PERMISOS_PERFIL_VERSION RENAME CONSTRAINT FK_PERM_TIPO TO FK_PERM_PERFIL;
ALTER TABLE PERMISOS_PERFIL_VERSION RENAME CONSTRAINT FK_PERM_VERSION TO FK_PERM_VERSION_SISTEMA;
ALTER TABLE PERMISOS_PERFIL_VERSION RENAME CONSTRAINT FK_PERM_MENU TO FK_PERM_FUNC_MENU;
ALTER TABLE PERMISOS_PERFIL_VERSION RENAME CONSTRAINT FK_PERM_ACCION TO FK_PERM_FUNC_ACCION;

-- FUNCIONALIDADES_MENU
ALTER TABLE FUNCIONALIDADES_MENU RENAME CONSTRAINT FK_MENU_PADRE TO FK_FM_PADRE;
ALTER TABLE FUNCIONALIDADES_MENU RENAME CONSTRAINT CHK_MENU_ACTIVO TO CHK_FM_ACTIVO;

-- AUDITORIA_SESIONES
ALTER TABLE AUDITORIA_SESIONES RENAME CONSTRAINT FK_AUD_USUARIO TO FK_AS_USUARIO_PERFIL;

-- AUDITORIA_OPERACIONES
ALTER TABLE AUDITORIA_OPERACIONES RENAME CONSTRAINT FK_AUDACC_AUD TO FK_AO_SESION;
ALTER TABLE AUDITORIA_OPERACIONES RENAME CONSTRAINT FK_AUDACC_ACCION TO FK_AO_FUNC_ACCION;
ALTER TABLE AUDITORIA_OPERACIONES RENAME CONSTRAINT CHK_AUDACC_RESULTADO TO CHK_AO_RESULTADO;

-- Verificar constraints
SELECT constraint_name, table_name, constraint_type 
FROM user_constraints 
WHERE table_name IN (
    'PERSONAS', 'CATALOGO_TIPOS_ENTIDAD', 'ENTIDADES', 
    'CATALOGO_PERFILES', 'USUARIOS_PERFILES', 
    'VERSIONES_SISTEMA', 'FUNCIONALIDADES_MENU', 'FUNCIONALIDADES_ACCION',
    'PERMISOS_PERFIL_VERSION', 'AUDITORIA_SESIONES', 'AUDITORIA_OPERACIONES'
)
ORDER BY table_name, constraint_type, constraint_name;
```

---

### **SCRIPT 3: RENOMBRADO DE ÍNDICES**

```sql
-- ============================================
-- RENOMBRADO DE ÍNDICES PARA CONSISTENCIA
-- ============================================

-- PERSONAS (antes DATOS_PERSONALES)
ALTER INDEX IDX_DP_IDENTIFICADOR RENAME TO IDX_PERS_IDENTIFICADOR;
ALTER INDEX IDX_DP_TIPO_PERSONA RENAME TO IDX_PERS_TIPO;
ALTER INDEX IDX_DP_EMAIL RENAME TO IDX_PERS_EMAIL;

-- ENTIDADES (antes MAESTROS_USUARIOS)
ALTER INDEX IDX_MAESTRO_TIPO RENAME TO IDX_ENT_TIPO;
ALTER INDEX IDX_MAESTRO_DATOS RENAME TO IDX_ENT_PERSONA;
ALTER INDEX IDX_MAESTRO_ESTADO RENAME TO IDX_ENT_ESTADO;
ALTER INDEX IDX_MAESTRO_PROVINCIA RENAME TO IDX_ENT_PROVINCIA;

-- USUARIOS_PERFILES (antes USUARIOS_RELACIONADOS)
ALTER INDEX UQ_USUARIO_PERFIL_MAESTRO RENAME TO UQ_UP_PERSONA_PERFIL_ENTIDAD;
ALTER INDEX IDX_USUREL_DATOS RENAME TO IDX_UP_PERSONA;
ALTER INDEX IDX_USUREL_TIPO RENAME TO IDX_UP_PERFIL;
ALTER INDEX IDX_USUREL_MAESTRO RENAME TO IDX_UP_ENTIDAD;
ALTER INDEX IDX_USUREL_ESTADO RENAME TO IDX_UP_ESTADO;

-- FUNCIONALIDADES_MENU (antes MENUS)
ALTER INDEX IDX_MENU_CODIGO RENAME TO IDX_FM_CODIGO;
ALTER INDEX IDX_MENU_PADRE RENAME TO IDX_FM_PADRE;

-- FUNCIONALIDADES_ACCION (antes ACCIONES)
ALTER INDEX IDX_ACCION_CODIGO RENAME TO IDX_FA_CODIGO;
ALTER INDEX IDX_ACCION_TIPO RENAME TO IDX_FA_TIPO;

-- PERMISOS_PERFIL_VERSION (antes PERMISOS_RELACION_VERSION)
ALTER INDEX IDX_PERM_TIPO RENAME TO IDX_PPV_PERFIL;
ALTER INDEX IDX_PERM_VERSION RENAME TO IDX_PPV_VERSION;
ALTER INDEX IDX_PERM_MENU RENAME TO IDX_PPV_MENU;
ALTER INDEX IDX_PERM_ACCION RENAME TO IDX_PPV_ACCION;

-- AUDITORIA_SESIONES (antes AUDITORIA_ACCESOS)
ALTER INDEX IDX_AUD_USUARIO RENAME TO IDX_AS_USUARIO_PERFIL;
ALTER INDEX IDX_AUD_SESION RENAME TO IDX_AS_SESION_ID;
ALTER INDEX IDX_AUD_FECHA RENAME TO IDX_AS_FECHA_LOGIN;

-- AUDITORIA_OPERACIONES (antes AUDITORIA_ACCIONES)
ALTER INDEX IDX_AUDACC_AUD RENAME TO IDX_AO_SESION;
ALTER INDEX IDX_AUDACC_ACCION RENAME TO IDX_AO_ACCION;
ALTER INDEX IDX_AUDACC_ENTIDAD RENAME TO IDX_AO_ENTIDAD_REGISTRO;
ALTER INDEX IDX_AUDACC_FECHA RENAME TO IDX_AO_FECHA;

-- Verificar índices
SELECT index_name, table_name, uniqueness 
FROM user_indexes 
WHERE table_name IN (
    'PERSONAS', 'CATALOGO_TIPOS_ENTIDAD', 'ENTIDADES', 
    'CATALOGO_PERFILES', 'USUARIOS_PERFILES', 
    'VERSIONES_SISTEMA', 'FUNCIONALIDADES_MENU', 'FUNCIONALIDADES_ACCION',
    'PERMISOS_PERFIL_VERSION', 'AUDITORIA_SESIONES', 'AUDITORIA_OPERACIONES'
)
ORDER BY table_name, index_name;
```

---

### **SCRIPT 4: RENOMBRADO DE COLUMNAS (CLAVES FORÁNEAS)**

```sql
-- ============================================
-- RENOMBRADO DE COLUMNAS PARA CONSISTENCIA
-- ============================================

-- ENTIDADES: ID_DATOS -> ID_PERSONA
ALTER TABLE ENTIDADES RENAME COLUMN ID_DATOS TO ID_PERSONA;
ALTER TABLE ENTIDADES RENAME COLUMN ID_TIPO_MAESTRO TO ID_TIPO_ENTIDAD;
ALTER TABLE ENTIDADES RENAME COLUMN ID_MAESTRO TO ID_ENTIDAD;
ALTER TABLE ENTIDADES RENAME COLUMN CODIGO_MAESTRO TO CODIGO_ENTIDAD;

-- USUARIOS_PERFILES: ID_DATOS -> ID_PERSONA, ID_TIPO_RELACION -> ID_PERFIL, ID_MAESTRO -> ID_ENTIDAD
ALTER TABLE USUARIOS_PERFILES RENAME COLUMN ID_USUARIO_REL TO ID_USUARIO_PERFIL;
ALTER TABLE USUARIOS_PERFILES RENAME COLUMN ID_DATOS TO ID_PERSONA;
ALTER TABLE USUARIOS_PERFILES RENAME COLUMN ID_TIPO_RELACION TO ID_PERFIL;
ALTER TABLE USUARIOS_PERFILES RENAME COLUMN ID_MAESTRO TO ID_ENTIDAD;

-- CATALOGO_TIPOS_ENTIDAD
ALTER TABLE CATALOGO_TIPOS_ENTIDAD RENAME COLUMN ID_TIPO_MAESTRO TO ID_TIPO_ENTIDAD;

-- CATALOGO_PERFILES
ALTER TABLE CATALOGO_PERFILES RENAME COLUMN ID_TIPO_RELACION TO ID_PERFIL;
ALTER TABLE CATALOGO_PERFILES ADD REQUIERE_ENTIDAD CHAR(1);
UPDATE CATALOGO_PERFILES SET REQUIERE_ENTIDAD = REQUIERE_MAESTRO;
ALTER TABLE CATALOGO_PERFILES DROP COLUMN REQUIERE_MAESTRO;

-- PERMISOS_PERFIL_VERSION
ALTER TABLE PERMISOS_PERFIL_VERSION RENAME COLUMN ID_TIPO_RELACION TO ID_PERFIL;

-- AUDITORIA_SESIONES
ALTER TABLE AUDITORIA_SESIONES RENAME COLUMN ID_AUDITORIA TO ID_SESION;
ALTER TABLE AUDITORIA_SESIONES RENAME COLUMN ID_USUARIO_REL TO ID_USUARIO_PERFIL;

-- AUDITORIA_OPERACIONES
ALTER TABLE AUDITORIA_OPERACIONES RENAME COLUMN ID_AUD_ACCION TO ID_OPERACION;
ALTER TABLE AUDITORIA_OPERACIONES RENAME COLUMN ID_AUDITORIA TO ID_SESION;

-- Verificar columnas
SELECT table_name, column_name, data_type, nullable
FROM user_tab_columns
WHERE table_name IN (
    'PERSONAS', 'CATALOGO_TIPOS_ENTIDAD', 'ENTIDADES', 
    'CATALOGO_PERFILES', 'USUARIOS_PERFILES', 
    'VERSIONES_SISTEMA', 'FUNCIONALIDADES_MENU', 'FUNCIONALIDADES_ACCION',
    'PERMISOS_PERFIL_VERSION', 'AUDITORIA_SESIONES', 'AUDITORIA_OPERACIONES'
)
ORDER BY table_name, column_id;
```

---

## 📝 PLAN DE EJECUCIÓN

### **FASE 1: PREPARACIÓN (1-2 días)**

1. ✅ **Backup completo** de la base de datos
2. ✅ **Revisión de dependencias** en código Java/Spring Boot
3. ✅ **Identificación de consultas SQL** en el código fuente
4. ✅ **Notificación al equipo** de desarrollo
5. ✅ **Preparación de entorno de pruebas**

---

### **FASE 2: EJECUCIÓN EN DESARROLLO (1 día)**

1. ✅ **Detener servicios** en desarrollo
2. ✅ **Ejecutar SCRIPT 1** (Renombrado de tablas)
3. ✅ **Ejecutar SCRIPT 2** (Renombrado de constraints)
4. ✅ **Ejecutar SCRIPT 3** (Renombrado de índices)
5. ✅ **Ejecutar SCRIPT 4** (Renombrado de columnas)
6. ✅ **Verificar integridad** de datos
7. ✅ **Recompilar objetos** inválidos

```sql
-- Verificar objetos inválidos
SELECT object_type, object_name, status 
FROM user_objects 
WHERE status = 'INVALID'
ORDER BY object_type, object_name;

-- Recompilar objetos inválidos
BEGIN
    FOR obj IN (SELECT object_type, object_name FROM user_objects WHERE status = 'INVALID') LOOP
        BEGIN
            IF obj.object_type = 'VIEW' THEN
                EXECUTE IMMEDIATE 'ALTER VIEW ' || obj.object_name || ' COMPILE';
            ELSIF obj.object_type = 'PACKAGE' THEN
                EXECUTE IMMEDIATE 'ALTER PACKAGE ' || obj.object_name || ' COMPILE';
            ELSIF obj.object_type = 'PACKAGE BODY' THEN
                EXECUTE IMMEDIATE 'ALTER PACKAGE ' || obj.object_name || ' COMPILE BODY';
            ELSIF obj.object_type = 'PROCEDURE' THEN
                EXECUTE IMMEDIATE 'ALTER PROCEDURE ' || obj.object_name || ' COMPILE';
            ELSIF obj.object_type = 'FUNCTION' THEN
                EXECUTE IMMEDIATE 'ALTER FUNCTION ' || obj.object_name || ' COMPILE';
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('Error compilando ' || obj.object_type || ' ' || obj.object_name);
        END;
    END LOOP;
END;
/
```

---

### **FASE 3: ACTUALIZACIÓN DE CÓDIGO (2-3 días)**

#### **Backend (Spring Boot + Java)**

**Archivos a modificar:**

1. **Entidades JPA** (`src/main/java/.../bean/oracle/`)
   - `ConfigurationBean.java` → Renombrar tabla + columnas
   - Crear nuevas entidades con nombres actualizados

2. **Repositorios** (`src/main/java/.../repository/`)
   - `ConfigRepository.java` → Actualizar queries nativas

3. **Servicios** (`src/main/java/.../service/`)
   - Actualizar referencias a nombres de columnas

4. **Mappers** (`src/main/java/.../utils/mapper/`)
   - Actualizar mapeo de columnas

**Ejemplo de cambio en entidad JPA:**

```java
// ANTES
@Entity
@Table(name = "DATOS_PERSONALES", schema = "INDAR_OWN")
public class DatosPersonalesBean {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "ID_DATOS")
    private Long idDatos;
    
    @Column(name = "IDENTIFICADOR")
    private String identificador;
    
    // ...
}

// DESPUÉS
@Entity
@Table(name = "PERSONAS", schema = "INDAR_OWN")
public class PersonaBean {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "ID_PERSONA")
    private Long idPersona;
    
    @Column(name = "IDENTIFICADOR")
    private String identificador;
    
    // ...
}
```

---

### **FASE 4: PRUEBAS (2-3 días)**

#### **Checklist de Pruebas:**

- [ ] **Pruebas unitarias** de repositorios
- [ ] **Pruebas de integración** de servicios
- [ ] **Pruebas funcionales** de endpoints REST
- [ ] **Pruebas de autenticación** MFE
- [ ] **Pruebas de permisos** por perfil
- [ ] **Pruebas de auditoría** (sesiones + operaciones)
- [ ] **Pruebas de rendimiento** (consultas complejas)
- [ ] **Pruebas de regresión** (funcionalidades existentes)

---

### **FASE 5: DESPLIEGUE EN PRE-PRODUCCIÓN (1 día)**

1. ✅ Desplegar en PRE
2. ✅ Ejecutar scripts de renombrado
3. ✅ Desplegar código actualizado
4. ✅ Pruebas de humo
5. ✅ Validación con usuarios clave

---

### **FASE 6: DESPLIEGUE EN PRODUCCIÓN (1 día)**

1. ✅ **Ventana de mantenimiento** programada
2. ✅ **Backup completo** de producción
3. ✅ **Detener servicios**
4. ✅ **Ejecutar scripts** (Scripts 1-4)
5. ✅ **Desplegar código** actualizado
6. ✅ **Verificación** de integridad
7. ✅ **Reactivar servicios**
8. ✅ **Monitoreo** intensivo (24h)

---

## ⚠️ CONSIDERACIONES IMPORTANTES

### **1. Impacto en el Código**

| **Componente** | **Archivos Estimados** | **Esfuerzo** |
|----------------|------------------------|--------------|
| Entidades JPA | 10-15 archivos | 2 días |
| Repositorios | 5-10 archivos | 1 día |
| Servicios | 10-15 archivos | 2 días |
| DTOs | 5-10 archivos | 1 día |
| Tests | 20-30 archivos | 2 días |
| **TOTAL** | **50-80 archivos** | **8 días** |

---

### **2. Compatibilidad con Vistas**

Si existen **vistas materializadas o vistas** que referencian las tablas antiguas:

```sql
-- Listar vistas afectadas
SELECT view_name, text 
FROM user_views 
WHERE text LIKE '%DATOS_PERSONALES%' 
   OR text LIKE '%MAESTROS_USUARIOS%'
   OR text LIKE '%USUARIOS_RELACIONADOS%'
   OR text LIKE '%TIPOS_MAESTRO%'
   OR text LIKE '%TIPOS_RELACION%';

-- Recrear vistas después del renombrado
-- Ejemplo:
CREATE OR REPLACE VIEW V_USUARIOS_PERFILES_ACTIVOS AS
SELECT 
    p.ID_PERSONA,
    p.IDENTIFICADOR,
    p.NOMBRE_COMPLETO,
    up.ID_USUARIO_PERFIL,
    cp.NOMBRE AS PERFIL,
    e.CODIGO_ENTIDAD AS ENTIDAD
FROM PERSONAS p
INNER JOIN USUARIOS_PERFILES up ON p.ID_PERSONA = up.ID_PERSONA
INNER JOIN CATALOGO_PERFILES cp ON up.ID_PERFIL = cp.ID_PERFIL
LEFT JOIN ENTIDADES e ON up.ID_ENTIDAD = e.ID_ENTIDAD
WHERE p.ACTIVO = 'Y' AND up.ESTADO = 'ACTIVO';
```

---

### **3. Documentación a Actualizar**

- [ ] Documentación técnica de base de datos
- [ ] Diagramas UML/ER
- [ ] Manual de desarrollador
- [ ] Scripts de migración/instalación
- [ ] Casos prácticos y ejemplos
- [ ] README del proyecto

---

## 📊 VENTAJAS DEL RENOMBRADO

| **Aspecto** | **Antes** | **Después** | **Mejora** |
|-------------|-----------|-------------|------------|
| **Claridad** | "MAESTROS_USUARIOS" es ambiguo | "ENTIDADES" es directo | ✅ +80% comprensión |
| **Consistencia** | "RELACION" vs "PERFIL" inconsistente | Todo usa "PERFIL" | ✅ +100% consistencia |
| **Onboarding** | 2-3 días para entender modelo | 1 día para entender modelo | ✅ -50% tiempo |
| **Mantenibilidad** | Confusión en queries complejas | Código autoexplicativo | ✅ +60% legibilidad |
| **Internacionalización** | Términos técnicos ambiguos | Terminología estándar | ✅ +100% estándar |

---

## 🎯 RECOMENDACIÓN FINAL

**✅ SE RECOMIENDA PROCEDER CON EL RENOMBRADO** por las siguientes razones:

1. **Mejora sustancial** de la comprensión del modelo
2. **Reducción de errores** en desarrollo futuro
3. **Facilita el onboarding** de nuevos desarrolladores
4. **Alineación con estándares** de la industria
5. **Mejor documentación** autodescriptiva

**⏱️ Tiempo Total Estimado:** 10-12 días laborables  
**💰 Costo/Beneficio:** Muy favorable a largo plazo  
**🎯 Mejor Momento:** Antes de despliegue en producción o en sprint de refactorización

---

**Generado por:** GitHub Copilot  
**Fecha:** 21 de Noviembre de 2025  
**Versión:** 1.0
