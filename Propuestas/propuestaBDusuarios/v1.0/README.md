# 📁 Propuesta Base de Datos Usuarios - Versión 1.0

**Fecha:** 21 de Noviembre de 2025  
**Versión:** 1.0 - Esquema Único  

Esta carpeta contiene la documentación de la **versión 1.0** de la propuesta de base de datos para gestión de usuarios INDAR.

## 📋 Contenido

- **PropuestaFinal_GestionUsuarios_INDAR.md**: Especificación completa de tablas y modelo de datos
- **DiagramaUML_GestionUsuarios_INDAR.md**: Diagramas Mermaid ERD del modelo
- **CasosPracticos_GestionUsuarios_INDAR.md**: Casos de uso prácticos con datos de ejemplo

## 🏗️ Arquitectura

**Modelo:** Esquema único (INDAR_OWN) con todas las tablas centralizadas.

```
┌─────────────────────────────┐
│     ESQUEMA: INDAR_OWN      │
│                             │
│  - DATOS_PERSONALES         │
│  - TIPOS_MAESTRO            │
│  - MAESTROS_USUARIOS        │
│  - TIPOS_RELACION           │
│  - USUARIOS_RELACIONADOS    │
│  - PERMISOS                 │
│  - AUDITORIA                │
└─────────────────────────────┘
```

## 🔄 Evolución

Esta versión fue sustituida por **v2.0** que introduce arquitectura de dos esquemas (RUIAR_OWN + INDAR_OWN) para permitir acceso multi-aplicación.

## 📚 Referencias

- [Versión 2.0](../v2.0/) - Arquitectura dual-schema con RUIAR
- [Comparativa v1.0 vs v2.0](../v2.0/PropuestaFinal_GestionUsuarios_INDAR_v2.md#comparativa-v10-vs-v20)