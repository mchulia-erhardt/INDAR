# RASMIA – Conclusiones y Decisiones Finales

Este documento recoge las conclusiones consolidadas y las decisiones arquitectónicas, funcionales y de implementación para la construcción de la nueva plataforma RASMIA (Registro de Actuaciones en Seguridad y Metrología Industrial en Aragón), tomando como base los documentos de análisis funcional, el piloto de Inspección Periódica AT y el esquema de base de datos propuesto (Versión 2).

---

## 1. Objetivo General
Disponer de una plataforma unificada y extensible para:
- Configurar y tramitar dinámicamente expedientes de múltiples ámbitos reglamentarios.
- Versionar trámites y formularios garantizando la continuidad de los expedientes iniciados en versiones antiguas.
- Integrar y convivir con aplicaciones existentes (DIGITA, RUI, GEKO, Pegasso) hasta su sustitución progresiva.
- Acelerar la incorporación masiva de procedimientos (≈450) mediante tipificación + parametrización + formularios dinámicos.

## 2. Alcance Inicial (Fase Núcleo / Piloto)
1. Entrada única (listado y acceso a expedientes RASMIA + RUI + DIGITA).
2. Alta y visualización de expedientes RASMIA para un tipo de procedimiento piloto (Inspección Periódica AT) y su comunicación a RUI.
3. Modelo de datos base + soporte de versionado (TRÁMITE y FORMULARIO).
4. Captura inmutable de datos específicos mediante snapshots JSON.
5. Motor de tramitación “básico”: Control / Devolución / Cierre / Consolidación.
6. Gestión de inspecciones con defectología y medidas provisionales.
7. Primeras integraciones WS (lectura / redirección).
8. Evolución incremental hacia más ámbitos y tipos de procedimiento (Comunicación, Cambio de Titular, Aportación Documental).

## 3. Principios Arquitectónicos
- Modularidad (Capas API / Dominio / Persistencia / Integraciones).
- Extensibilidad vía definiciones y datos dinámicos (JSON) sin migraciones estructurales frecuentes.
- Inmutabilidad y trazabilidad de formularios capturados.
- Versionado explícito y programable para trámites y formularios.
- Integración desacoplada (puertos/adaptadores hexagonal).
- Idempotencia y trazabilidad en intercambios con sistemas externos.
- Seguridad basada en roles/ámbitos/provincia + autenticación robusta.
- Auditoría funcional y técnica.
- Escalabilidad horizontal (stateless + token/JWT).
- Evitar bloqueos prolongados de instalaciones (usar estados, no locks duros).

## 4. Decisiones Tecnológicas
**Backend**: Java 21 + Spring Boot (Web, Data JPA, Security, Validation, Actuator). Oracle. Migraciones con Flyway. Datos dinámicos (definiciones) en tablas; instancias en CLOB JSON. Motor de tramitación propio ligero, extensible.
**Frontend**: Angular última versión. Generador dinámico de formularios desde definiciones. Componentes por tipo de campo. Estado simple (servicios + BehaviorSubject); escalar a NgRx/Signals más adelante.
**Integraciones**: REST JSON. Adaptadores con resiliencia (Resilience4j: retry, circuit breaker). Posible adopción de mensajería (Kafka/RabbitMQ) para desacoplar consolidaciones en fases posteriores.
**Infra** (futuro): Contenedores, orquestación (Kubernetes), observabilidad (Prometheus + Grafana + ELK/OpenSearch).

## 5. Modelo de Datos y Versionado
- TRAMITE_DEF / TRAMITE_VERSION: separación definición vs versiones activas/programadas.
- FORMULARIO_DEF / FORMULARIO_VERSION: cada versión congela entidades y propiedades.
- ENTIDAD_DEF y PROPIEDAD_DEF ligadas a FORMULARIO_VERSION para asegurar congelación estructural.
- EXPEDIENTE referencia la versión vigente en su inicio (VERSION_BLOQUEADA por defecto ‘S’).
- FORM_DATA_SNAPSHOT: captura inmutable de los datos aportados (inicial, subsanaciones, cierre, etc.).
- Inspecciones: estructura adicional (EXPEDIENTE_INSPECCION + DEFECTOS) extendiendo el modelo sin romper núcleo.

## 6. Motor de Tramitación
Estados base: 
- PENDIENTE_ACCION_ADMON
- PENDIENTE_ACCION_INTERESADO
- PENDIENTE_TRASLADO
- CERRADO_TRASLADADO_RUI
- CANCELADO
- EN_SUBSANACION (futuro)
- EN_REVISION_POSTERIOR / TRASLADADO_EN_REVISION / TRASLADADO_REVISADO (para inspecciones)
Transiciones codificadas en MVP; posterior parametrización (tabla de reglas / DSL ligera). Hooks post-cierre: consolidación en RUI + actualización instalación (última y próxima inspección).

## 7. Formularios Dinámicos
Tipos: TEXT, TEXTAREA, NUMBER, DATE, SELECT_SINGLE, SELECT_MULTI, BOOLEAN, FILE, URL.
Validaciones JSON (longitud, formato, rango, dependencias condicionales). Fuente de datos (listas estáticas, WS externos). Entidades con MULTIPLE='S' → arrays en snapshot. Render + validación espejo en backend.

## 8. Intervinientes y Roles
Catálogo TIPO_INTERVINIENTE. Asociación TRAMITE_INTERVINIENTE con indicador de responsable. EXPEDIENTE_INTERVINIENTE guarda instancias (persona física/jurídica). Validaciones externas diferidas (RII/PEA) con flags de “pendiente verificación”.

## 9. Instalaciones y Ubicaciones
UBICACION (sin titular) separada de INSTALACION (con ámbito y datos titular). Posibilidad de generar código ficticio si falta referencia catastral. Actualización de fechas post-inspección desde consolidación. Evitar bloqueo físico: estado transitorio mientras trámites críticos.

## 10. Seguridad
Autenticación inicial con certificado; evolución a OIDC (Keycloak u otro). Autorización por rol + ámbito + provincia (deny-by-default). Auditoría (quién/qué/cuándo). Hash de documentos. Protección ante escalado de privilegios (revisión periódica de asignaciones).

## 11. Documentación
EXPEDIENTE_DOCUMENTO y EXPEDIENTE_INSPECCION_DOC diferenciados. HASH_DOCUMENTO (SHA-256) para integridad. RUTA_STORAGE abstracta (filesystem institucional / S3 compatible). Metadatos de validez y origen.

## 12. Migración / Convivencia
Fases: 
1. Lectura agregada (mostrar expediente legado).
2. Alta nuevos trámites en RASMIA.
3. Sustitución progresiva (comunicaciones, cambios de titular).
4. Retirada gradual GEKO / TTO.
5. Migración histórica selectiva (solo datos con valor analítico / regulatorio).

## 13. BI y Métricas
Staging nocturno para consolidar: ámbito, procedimiento, versión, estado, tiempos. KPIs: tiempo medio alta→cierre, % devoluciones, distribución defectos por categoría, instalaciones próximas a caducidad, obsolescencia de versiones (expedientes en versiones antiguas).

## 14. Roadmap Resumido
MVP Entrada Única → Motor Básico + Inspección AT → Procedimientos comunes (Comunicación, Cambio Titular, Aportación Doc) → Herramienta configuración ámbitos → Masificación procedimientos → BI / cuadro de mando → Desacoplo completo de sistemas legados.

## 15. Riesgos Clave y Mitigaciones
- Complejidad versionado cruzado: política estricta de congelación y sólo añadir nueva versión (no mutar activa).
- Crecimiento snapshots: retención + archivado + compresión.
- Latencia servicios externos: circuit breakers + colas diferidas.
- Divergencia validaciones front/back: catálogo único y tests contractuales.
- Sobrecarga por masificación: automatización de carga de definiciones + plantillas.
- Seguridad documental: hash, control de acceso y registro de descargas.

## 16. Backlog Inicial (Epics)
1. Entrada Única.
2. Modelo Versionado.
3. Formularios Dinámicos (render + validaciones).
4. Motor Básico (estados + transiciones).
5. Inspecciones AT (defectos + medidas provisionales).
6. Integraciones RUI/DIGITA (lectura y redirección).
7. Seguridad y Auditoría.
8. Documentos y almacenamiento.
9. BI Seed (extracción inicial).

## 17. KPIs
- % procedimientos incorporados vs plan.
- Lead time medio (Alta → Cierre).
- Ratio devoluciones / total expedientes.
- Expedientes por versión activa vs versiones obsoletas.
- Tiempo generación acta inspección.
- Incidencias por inconsistencias de versión (objetivo 0).

## 18. Próximos Pasos
1. Confirmar campos mínimos de EXPEDIENTE (índices de búsqueda).
2. Aprobar política de versionado (activación programada + cierre automático anterior).
3. Definir OpenAPI servicios RUI (obtener / redireccionar / consolidar).
4. Scaffolding repositorios (backend y frontend) + CI inicial.
5. Implementar mock Entrada Única para demo temprana.
6. Validar estados normalizados con negocio.
7. Cargar catálogos iniciales (Ámbitos, Tipos Procedimiento, Tipos Documento, Tipos Interviniente).
8. Diseñar plantilla Acta inspección (HTML → PDF/Freemarker).

## 19. Futuro
- Posible BPMN (Camunda / Flowable) si proliferan flujos divergentes.
- Almacenamiento documental externo (MinIO / S3) + antivirus.
- Firma electrónica avanzada (no MVP).
- Cache Redis para catálogos.
- Multi-idioma y accesibilidad (WCAG AA).
- Eventos y streaming para analítica en tiempo casi real.

## 20. Resumen Ejecutivo
RASMIA se fundamenta en definiciones versionadas de trámites y formularios + snapshots inmutables + motor ligero evolutivo, permitiendo acelerar la incorporación masiva de procedimientos mientras conviven sistemas legados controladamente. El enfoque reduce coste de cambio reglamentario y asegura trazabilidad y auditabilidad completas.

---

Última actualización: 2025-11-11  
Autor: <pendiente>  
Aprobación: <pendiente>  

Observación: Documento vivo; revisar en cada hito mayor (motor, masificación, BI).
