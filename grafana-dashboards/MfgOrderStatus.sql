SELECT
			ROW_NUMBER () OVER (ORDER BY MO.MfgOrderName) Seq
			, PB2.ProductName  + ':' + P.ProductRevision Product
			, MO.MfgOrderName MfgOrder
			, OT.OrderTypeName OrderType
			, MO.PlannedStartDate
			, MO.PlannedCompletionDate
			, C.FactoryStartDate FirstStartDate
			, C.LastCompletionDate
			, ISNULL(MO.Qty, 0) MfgOrderQty
			, C.TotalContainer
			, ISNULL(C.FactoryStartQty, 0) TotalQtyStarted
			, ISNULL(C.Qty, 0) TotalQty
			, ISNULL(C.Qty2, 0) TotalQty2
			, CASE WHEN ISNULL(MO.Qty, 0) > ISNULL(C.FactoryStartQty, 0) THEN ISNULL(MO.Qty, 0) - ISNULL(C.FactoryStartQty, 0) ELSE 0 END TotalQtyPending
			, CASE WHEN ISNULL(C.FactoryStartQty, 0) > ISNULL(C.Qty, 0) THEN ISNULL(C.FactoryStartQty, 0) - ISNULL(C.Qty, 0) ELSE 0 END TotalQtyRejected
			, ISNULL(C.TotalQtyInProcess, 0) TotalQtyInProcess
			, ISNULL(C.TotalQtyCompleted, 0) TotalQtyCompleted
		FROM
			MfgOrder MO
			LEFT OUTER JOIN OrderType OT ON MO.OrderTypeId = OT.OrderTypeId
			LEFT OUTER JOIN OrderStatus OS ON MO.OrderStatusId = OS.OrderStatusId
			LEFT OUTER JOIN ProductBase PB ON MO.ProductBaseId = PB.ProductBaseId
			LEFT OUTER JOIN Product P ON PB.RevOfRcdId = P.ProductId OR MO.ProductId = P.ProductId
			LEFT OUTER JOIN ProductBase PB2 ON P.ProductBaseId = PB2.ProductBaseId
			LEFT OUTER JOIN
			(
				SELECT
					C.MfgOrderId
					, COUNT(C.ContainerName) TotalContainer
					, MIN(SO.SalesOrderName) SalesOrder
					, SUM(C.Qty) Qty
					, SUM(C.Qty2) Qty2
					, MIN(CS.WorkflowStepId) WorkflowStepId
					, MIN(CS.FactoryId) FactoryId
					, MIN(C.FactoryStartDate) FactoryStartDate
					, SUM(C.FactoryStartQty) FactoryStartQty
					, SUM(C.FactoryStartQty2) FactoryStartQty2
					, MAX(CASE WHEN WS.IsLastStep = 1 THEN CS.LastMoveDate ELSE NULL END) LastCompletionDate
					, SUM(CASE WHEN WS.IsLastStep = 0 AND C.Status = 1 THEN ISNULL(C.Qty, 0) ELSE 0 END) TotalQtyInProcess
					, SUM(CASE WHEN WS.IsLastStep = 0 AND C.Status = 1 THEN ISNULL(C.Qty2, 0) ELSE 0 END) TotalQty2InProcess
					, SUM(CASE WHEN WS.IsLastStep = 1 THEN ISNULL(C.Qty, 0) ELSE 0 END) TotalQtyCompleted
					, SUM(CASE WHEN WS.IsLastStep = 1 THEN ISNULL(C.Qty2, 0) ELSE 0 END) TotalQty2Completed
				FROM
					Container C
					INNER JOIN CurrentStatus CS ON C.CurrentStatusId = CS.CurrentStatusId
					INNER JOIN WorkflowStep WS ON CS.WorkflowStepId = WS.WorkflowStepId
					LEFT OUTER JOIN SalesOrder SO ON C.SalesOrderId = SO.SalesOrderId
				WHERE
					C.ParentContainerId IS NULL
				GROUP BY
					C.MfgOrderId
			) C ON MO.MfgOrderId = C.MfgOrderId
			LEFT OUTER JOIN Factory MO_F2 ON MO.ReportingFactoryId = MO_F2.FactoryId
			LEFT OUTER JOIN Factory F ON C.FactoryId = F.FactoryId