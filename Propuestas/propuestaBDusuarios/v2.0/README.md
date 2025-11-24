# 📁 Propuesta Base de Datos Usuarios - Versión 2.0

**Fecha:** 24 de Noviembre de 2025  
**Versión:** 2.0 - Integración RUIAR  

Esta carpeta contiene la documentación de la **versión 2.0** de la propuesta de base de datos para gestión de usuarios INDAR con integración del esquema RUIAR.

## 📋 Contenido

- **PropuestaFinal_GestionUsuarios_INDAR_v2.md**: Especificación completa con arquitectura dual-schema
- **DiagramaUML_GestionUsuarios_INDAR_v2.md**: Diagramas Mermaid ERD con referencias cross-schema
- **CasosPracticos_GestionUsuarios_INDAR_v2.md**: Casos de uso actualizados para dual-schema

## 🏗️ Arquitectura

**Modelo:** Dos esquemas independientes con referencias cross-schema.

```
┌─────────────────────────────┐  ┌─────────────────────────────┐
│   ESQUEMA: RUIAR_OWN        │  │   ESQUEMA: INDAR_OWN        │
│   (Maestros Compartidos)    │←→│   (Permisos Específicos)    │
│                             │  │                             │
│  - RUIAR_PERSONAS           │  │  - TIPOS_RELACION           │
│  - RUIAR_TIPOS_ENTIDAD      │  │  - USUARIOS_RELACIONADOS    │
│  - RUIAR_ENTIDADES          │  │  - PERMISOS                 │
│  - RUIAR_EXP_CONSOLIDADOS   │  │  - AUDITORIA                │
│  - RUIAR_SYNC_CONTROL       │  │  - VERSIONES                │
└─────────────────────────────┘  └─────────────────────────────┘
```

## 🆕 Novedades v2.0

1. **Separación en 2 esquemas**: RUIAR_OWN (maestros) + INDAR_OWN (permisos)
2. **Multi-aplicación**: RUIAR accesible desde múltiples sistemas
3. **Referencias cross-schema**: Foreign Keys entre esquemas
4. **Sincronización**: Procedimiento SYNC_EXPEDIENTE_A_RUIAR
5. **Expedientes consolidados**: RUIAR_EXP_CONSOLIDADOS para estado final
6. **Control de sincronización**: RUIAR_SYNC_CONTROL para auditoría multi-app
7. **Vistas de compatibilidad**: Mantienen código v1.0 funcionando

## ✅ Ventajas sobre v1.0

- ✅ Registro único multi-aplicación
- ✅ Sin duplicación de entidades entre apps
- ✅ Mayor escalabilidad
- ✅ Independencia entre aplicaciones
- ✅ Auditoría centralizada en RUIAR

## 📚 Referencias

- [Versión 1.0](../v1.0/) - Arquitectura original single-schema
- [Propuesta RUIAR](PropuestaFinal_GestionUsuarios_INDAR_v2.md)
- [Casos Prácticos v2.0](CasosPracticos_GestionUsuarios_INDAR_v2.md)