SELECT
    count(*) AS "TOTAL RESOURCE",
    sum(case when RSC.Availability = 1 then 1 else 0 end) AS UP,
    sum(case when RSC.Availability = 0 then 1 else 0 end) AS DOWN,
    sum(case when RSC.Availability IS NULL then 1 else 0 end) AS "N/A"
FROM
    [ExCoreOLTP].[ExCoreOLTPSchema].ResourceDef R
    LEFT OUTER JOIN [ExCoreOLTP].[ExCoreOLTPSchema].ResourceType RT ON R.ResourceTypeId = RT.ResourceTypeId
    LEFT OUTER JOIN [ExCoreOLTP].[ExCoreOLTPSchema].ProductionStatus PS ON R.ProductionStatusId = PS.ProductionStatusId
    LEFT OUTER JOIN [ExCoreOLTP].[ExCoreOLTPSchema].ResourceStatusCode RSC ON PS.StatusId = RSC.ResourceStatusCodeId