/*

** Author: Tomaz Kastrun
** Web: http://tomaztsql.wordpress.com
** Twitter: @tomaz_tsql
** Created: 10.08.2016; Ljubljana
** Handling R installed and required libraries and packages using T-SQL
** R and T-SQL

*/

USE WideWorldImporters;
GO


EXECUTE sp_execute_external_script    
		   @language = N'R'
		  ,@script=N'library(Hmisc) 
					df <- data.frame(rcorr(as.matrix(sp_RStats_query), type="pearson")$P)
					OutputDataSet<-df'
		  ,@input_data_1 = N'SELECT 
					 SupplierID
					,UnitPackageID
					,OuterPackageID
				FROM [Warehouse].[StockItems]'
		  ,@input_data_1_name = N'sp_RStats_query'
	WITH RESULT SETS ((SupplierID NVARCHAR(200)
					,UnitPackageID NVARCHAR(200)
					,OuterPackageID NVARCHAR(200)));



/*
We will rephrase this code a little bit; parametrization of @script parameter!

*/


DECLARE @OutScript NVARCHAR(MAX) 
SET @OutScript =N'library(Hmisc) 
					library(test123)
					df <- data.frame(rcorr(as.matrix(sp_RStats_query), type="pearson")$P)
					OutputDataSet<-df'


DECLARE @Tally TABLE (num TINYINT,R_Code NVARCHAR(MAX))
INSERT INTO @Tally VALUES (1,@OutScript)
DECLARE @libstatement NVARCHAR(MAX)
DECLARE @cmdstatement NVARCHAR(MAX)



;WITH CTE_R(num,R_Code, libname)
AS
(
SELECT
	  1 AS num,
      RIGHT(R_Code, LEN(R_Code) - CHARINDEX(')', R_Code, 0)) AS  R_Code, 
	  substring(R_Code, CHARINDEX('library(', R_Code, 0) + 0, CHARINDEX(')', R_Code, 0) - CHARINDEX('library(', R_Code, 0) + 1) AS libname
FROM @Tally
WHERE  
		CHARINDEX('(', R_Code, 0) > 0 
	AND CHARINDEX('library(',R_Code,0) > 0

UNION ALL

SELECT
     1 AS num,
	 RIGHT(R_Code, LEN(R_Code) - CHARINDEX(')', R_Code, 0)) AS  R_Code,
     substring(R_Code, CHARINDEX('library(', R_Code, 0) + 0, CHARINDEX(')', R_Code, 0) - CHARINDEX('library(', R_Code, 0) + 1) AS libname
FROM CTE_R
WHERE 
	CHARINDEX('(', R_Code, 0) > 0 
AND CHARINDEX('library(',R_Code,0) > 0

)
, fin AS
(
SELECT TOP 1 stuff((SELECT ' install.packages(''''' + REPLACE(REPLACE(REPLACE(c1.libname,'library',''),')',''),'(','') + ''''')'
              FROM CTE_R AS c1 
			  WHERE 
					c1.num = c2.num
              FOR XML PATH (''),TYPE).value('.','NVARCHAR(MAX)'),1,1,'') AS lib_stat
			  FROM CTE_R AS c2
)
SELECT 
		@libstatement = lib_stat 
FROM fin

SET @cmdstatement = 'EXEC xp_cmdshell ''"C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\R_SERVICES\bin\R.EXE" cmd -e ' + @libstatement + ''''
EXEC SP_EXECUTESQL @cmdstatement


EXECUTE sp_execute_external_script    
		   @language = N'R'
		  ,@script= @OutScript
		  ,@input_data_1 = N'SELECT 
					 SupplierID
					,UnitPackageID
					,OuterPackageID
				FROM [Warehouse].[StockItems]'
		  ,@input_data_1_name = N'sp_RStats_query'
	WITH RESULT SETS ((
						 SupplierID    NVARCHAR(200)
						,UnitPackageID NVARCHAR(200)
						,OuterPackageID NVARCHAR(200)
					));





/*
Always an elegent way to ensure the library/package existence or installation
*/

USE WideWorldImporters;
GO

EXECUTE sp_execute_external_script    
           @language = N'R'
          ,@script=N'if(!is.element("Hmisc", installed.packages()))
                      {install.packages("Hmisc")
                        }else{library("Hmisc")}
                    df <- data.frame(rcorr(as.matrix(sp_RStats_query), 
					type="pearson")$P)
                    OutputDataSet<-df'
          ,@input_data_1 = N'SELECT 
                     SupplierID
                    ,UnitPackageID
                    ,OuterPackageID
                FROM [Warehouse].[StockItems]'
          ,@input_data_1_name = N'sp_RStats_query'
    WITH RESULT SETS ((SupplierID NVARCHAR(200)
                    ,UnitPackageID NVARCHAR(200)
                    ,OuterPackageID NVARCHAR(200)));