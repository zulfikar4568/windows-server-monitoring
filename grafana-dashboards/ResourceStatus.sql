SELECT
		ROW_NUMBER() OVER (ORDER BY R.ResourceName) Seq
		, R.ResourceName Resource
		, CASE WHEN R.[Description] IS NULL THEN '-' ELSE R.[Description] END "Description"
		, CASE WHEN RF.ResourceFamilyName IS NULL THEN '-' ELSE RF.ResourceFamilyName END "Resource Family"
		, CASE WHEN PS.LastStatusChangeDate IS NULL THEN '-' ELSE CONVERT(VARCHAR(20),PS.LastStatusChangeDate,100) END "Last Status Change"
		, CASE WHEN RSC.Availability = 1 THEN 'Up' WHEN RSC.Availability = 2 THEN 'Down' ELSE '-' END Availability
		, CASE WHEN RSR.ResourceStatusReasonName IS NULL THEN '-' ELSE RSR.ResourceStatusReasonName END "Reason"
	    , CASE WHEN MC.MaintenanceClassName IS NULL THEN '-' ELSE MC.MaintenanceClassName END "Maintenance Class"
		, CASE WHEN ISNULL(L.LabelValue, MR_CD.CDOName) IS NULL THEN '-' ELSE ISNULL(L.LabelValue, MR_CD.CDOName) END "Maintenance Type"
		, CASE WHEN MRB.MaintenanceReqName IS NULL THEN '-' ELSE MRB.MaintenanceReqName + ':' + MR.Revision END "Maintenance Req"
		, CASE WHEN AMR.ActivationDate IS NULL THEN '-' ELSE CONVERT(VARCHAR(20),AMR.ActivationDate,100) END "Maintenance Activation"
		, CASE WHEN MR.ScheduleDate IS NOT NULL AND GETDATE() >= MR.ScheduleDate + ISNULL(MR.TolerancePeriod, 0) THEN 'Past Due'
				WHEN MR.ScheduleDate IS NOT NULL AND GETDATE() >= MR.ScheduleDate THEN 'Due'
				WHEN MR.ScheduleDate IS NOT NULL AND GETDATE() >= MR.ScheduleDate - ISNULL(MR.WarningPeriod, 0) THEN 'Pending'
				WHEN MS.NextDateDue IS NOT NULL AND GETDATE() >= MS.NextDateDue + ISNULL(MR.TolerancePeriod, 0) THEN 'Past Due'
				WHEN MS.NextDateDue IS NOT NULL AND GETDATE() >= MS.NextDateDue THEN 'Due'
				WHEN MS.NextDateDue IS NOT NULL AND GETDATE() >= MS.NextDateDue - ISNULL(MR.WarningPeriod, 0) THEN 'Pending'
				WHEN MR.ToleranceQty IS NOT NULL AND (PS.TotalThruputQty - MS.LastThruputQty + MS.ThruputQtyAdjustment) >= MR.Qty + MR.ToleranceQty THEN 'Past Due'
				WHEN MR.ToleranceQty IS NOT NULL AND (PS.TotalThruputQty - MS.LastThruputQty + MS.ThruputQtyAdjustment) >= MR.Qty THEN 'Due'
				WHEN MR.ToleranceQty IS NOT NULL AND (PS.TotalThruputQty - MS.LastThruputQty + MS.ThruputQtyAdjustment) >= MR.Qty - MR.WarningQty THEN 'Pending'
				WHEN MR.ToleranceQty2 IS NOT NULL AND (PS.TotalThruputQty2 - MS.LastThruputQty2 + MS.ThruputQty2Adjustment) >= MR.Qty2 + MR.ToleranceQty2 THEN 'Past Due'
				WHEN MR.ToleranceQty2 IS NOT NULL AND (PS.TotalThruputQty2 - MS.LastThruputQty2 + MS.ThruputQty2Adjustment) >= MR.Qty2 THEN 'Due'
				WHEN MR.ToleranceQty2 IS NOT NULL AND (PS.TotalThruputQty2 - MS.LastThruputQty2 + MS.ThruputQty2Adjustment) >= MR.Qty2 - MR.WarningQty2 THEN 'Pending'
				WHEN MRB.MaintenanceReqName IS NOT NULL THEN 'Active'
                WHEN MRB.MaintenanceReqName IS NULL THEN '-'
				ELSE NULL END MaintenanceStatus
	FROM
		[ExCoreOLTP].[ExCoreOLTPSchema].ResourceDef R
		LEFT OUTER JOIN [ExCoreOLTP].[ExCoreOLTPSchema].ChangeStatus CS ON R.ChangeStatusId = CS.ChangeStatusId
		LEFT OUTER JOIN [ExCoreOLTP].[ExCoreOLTPSchema].ResourceFamily RF ON R.ResourceFamilyId = RF.ResourceFamilyId
		LEFT OUTER JOIN [ExCoreOLTP].[ExCoreOLTPSchema].ResourceType RT ON R.ResourceTypeId = RT.ResourceTypeId
		LEFT OUTER JOIN [ExCoreOLTP].[ExCoreOLTPSchema].ProductionStatus PS ON R.ProductionStatusId = PS.ProductionStatusId
		LEFT OUTER JOIN [ExCoreOLTP].[ExCoreOLTPSchema].Factory F ON R.FactoryId = F.FactoryId
		LEFT OUTER JOIN [ExCoreOLTP].[ExCoreOLTPSchema].Container C ON PS.ContainerId = C.ContainerId
		LEFT OUTER JOIN [ExCoreOLTP].[ExCoreOLTPSchema].ResourceStatusCode RSC ON PS.StatusId = RSC.ResourceStatusCodeId
		LEFT OUTER JOIN [ExCoreOLTP].[ExCoreOLTPSchema].ResourceStatusReason RSR ON PS.ReasonId = RSR.ResourceStatusReasonId
		LEFT OUTER JOIN [ExCoreOLTP].[ExCoreOLTPSchema].ProductBase PB ON PS.ProductBaseId = PB.ProductBaseId
		LEFT OUTER JOIN [ExCoreOLTP].[ExCoreOLTPSchema].Product P ON PB.RevOfRcdId = P.ProductId OR PS.ProductId = P.ProductId
		LEFT OUTER JOIN [ExCoreOLTP].[ExCoreOLTPSchema].ProductBase PB2 ON P.ProductBaseId = PB2.ProductBaseId
		LEFT OUTER JOIN [ExCoreOLTP].[ExCoreOLTPSchema].MfgOrder C_MO ON C.MfgOrderId = C_MO.MfgOrderId
		LEFT OUTER JOIN [ExCoreOLTP].[ExCoreOLTPSchema].AssignedMaintReq AMR ON R.ResourceId = AMR.ParentId
		LEFT OUTER JOIN [ExCoreOLTP].[ExCoreOLTPSchema].MaintenanceStatus MS ON AMR.AssignedMaintReqId = MS.AssignedMaintReqId
		LEFT OUTER JOIN [ExCoreOLTP].[ExCoreOLTPSchema].MaintenanceReq MR ON AMR.MaintenanceReqId = MR.MaintenanceReqId
		LEFT OUTER JOIN [ExCoreOLTP].[ExCoreOLTPSchema].MaintenanceReqBase MRB ON MR.MaintenanceReqBaseId = MRB.MaintenanceReqBaseId
		LEFT OUTER JOIN [ExCoreOLTP].[ExCoreOLTPSchema].CDODefinition MR_CD ON MR.CDOTypeId = MR_CD.CDODefID
		LEFT OUTER JOIN [ExCoreOLTP].[ExCoreOLTPSchema].Labels L ON MR_CD.DisplayNameLabelId = L.LabelID
		LEFT OUTER JOIN [ExCoreOLTP].[ExCoreOLTPSchema].MaintenanceClass MC ON R.MaintenanceClassId = MC.MaintenanceClassId