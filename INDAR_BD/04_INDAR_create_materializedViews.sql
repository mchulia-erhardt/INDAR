
-- La creación de vistas materializadas requiere para su ejecución la conexión 
--directa con el usuario propietario de las mismas, por lo que la ejecución 
--mediante la herramienta rundeck por parte del personal de operaciones devuelve 
--errores. Asegúrese de solicitarlo correctamente en futuras peticiones de 
--servicio para que se ejecuten con el usuario adecuado. 



CREATE MATERIALIZED VIEW INDAR_OWN.MV_EXPE_COMP_JSON
  ORGANIZATION HEAP
  BUILD IMMEDIATE
  USING INDEX
  REFRESH FORCE ON DEMAND
  USING DEFAULT LOCAL ROLLBACK SEGMENT
  USING ENFORCED CONSTRAINTS
  DISABLE ON QUERY COMPUTATION
  DISABLE QUERY REWRITE
AS
SELECT
    ecd.ID_EXPEDIENTE,
    JSON_OBJECTAGG(
        c.NOMBRE VALUE
            JSON_QUERY(ecd.DATOS_EXPEDIENTE_COMPONENTE, '$' RETURNING CLOB)
        NULL ON NULL
        RETURNING CLOB
    ) AS COMPONENTES_JSON
FROM
    INDAR_OWN.INDAR_EXPE_COMP_DATOS      ecd
    JOIN INDAR_OWN.INDAR_TM_VERSION_COMP vc ON vc.ID_VERSION_COMP = ecd.ID_VERSION_COMP
    JOIN INDAR_OWN.INDAR_TM_COMPONENTES   c ON c.ID_COMPONENTE    = vc.ID_COMPONENTE
GROUP BY ecd.ID_EXPEDIENTE;
/