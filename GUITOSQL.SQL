---EXECUTE ON CONTROL DATABASE

SELECT DISTINCT xp.pacName as PackageName,tableName,feedPopDescription as Population, 
CONVERT(VARCHAR(12),xazf.zipFileDate,107) CurrentThrough,xpt.progressTypeName as Progress,loadSubPercentComplete,resultTypeName as TableStatus
FROM dbo.xfu_LoadSubToLoadJob xlstlj(NOLOCK)
JOIN dbo.xfu_LoadJob xlj(NOLOCK) ON xlj.loadJobId = xlstlj.loadJobId
JOIN dbo.xfu_LoadSub xls(NOLOCK) ON xlstlj.loadSubId = xls.loadSubId
JOIN (
SELECT xlstlj.loadSubId, xlj.loadJobId, xlj.progress, xlj.actualStartDateTime, xlj.actualEndDateTime,
DENSE_RANK() OVER( PARTITION BY xlstlj.loadSubId ORDER BY COALESCE(xlj.actualEndDateTime, GETUTCDATE()) DESC ) AS rnk
FROM xfu_LoadSubToLoadJob xlstlj(NOLOCK) -- For Table Start and End Time
JOIN xfu_LoadJob xlj(NOLOCK) ON xlj.loadJobId = xlstlj.loadJobId ) xl ON xl.loadSubId = xlstlj.loadSubId
AND xl.loadJobId = xlstlj.loadJobId AND xl.rnk = 1
JOIN dbo.xfc_PacVerToFeedPop xpvtfp(NOLOCK) ON xpvtfp.pacVerToFeedPopId = xls.pacVerToFeedPopId
JOIN dbo.xfc_PacVer xpv(NOLOCK) ON xpv.pacVerId = xpvtfp.pacVerId
JOIN dbo.xfc_Pac xp(NOLOCK) ON xp.pacId = xpv.pacId


JOIN xfc_FeedPop xfp (NOLOCK) ON xfp.feedPopId = xpvtfp.feedPopId
JOIN xfu_LoadSubTableState xlsts (NOLOCK) ON xlsts.loadSubId = xls.loadSubId
JOIN xfu_ActualZipFile xazf (NOLOCK) ON xazf.actualZipFileId = xlsts.lastActualZipFileId -- For  CurrentThrough Info
JOIN dbo.xfc_ProgressType xpt(NOLOCK) ON xpt.progressTypeId = xlstlj.loadSubProgressTypeId
  JOIN xfc_TableInst XTL (NOLOCK)   -- For Table Info
  ON xlsts.tableInstId=XTL.tableInstId
  JOIN xfc_Table XTT(NOLOCK)  -- For Table Info
  ON XTL.tableId=XTT.tableId
JOIN dbo.xfu_Source xs(NOLOCK) ON xs.sourceId = xlstlj.loadSubUsedSourceId -- For Source Info
JOIN dbo.xfu_Target xt(NOLOCK) ON xt.targetId = xls.targetId -- For Target Info
JOIN xfc_ProgressType XPRGRS (NOLOCK)   -- For Package Progress Info
  ON xlsts.tableProgressTypeId=XPRGRS.progressTypeId -- For  Table Level Progress Info
  JOIN xfc_ResultType XR (NOLOCK) on XR.resultTypeId =xlsts.lastResultTypeId 

  
WHERE xls.loadSubDeletedFlag = 0 --- -- To process the files which are not deleted  
ORDER BY xp.pacName
