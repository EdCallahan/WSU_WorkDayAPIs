use WorkDay
GO

---
--- MS SQL is pretty efficient at processing fairly huge XML documents. The code below processesa 2 gig
--- XML file from the WorkData API GetWorkers call with Include_Organizations set to true
---
--- Ed Callahan, Winona State University, 2/7/2023
--


/*

---
--- Create tables we'll populate
---

-- Suck the entire XML file into one row cell into this table
CREATE TABLE dbo.WorkerDataLoad
(
    Id INT IDENTITY PRIMARY KEY,
    XMLData XML,
    LoadedDateTime DATETIME default getdate()
)

-- holds XML for each individual worker, basically we just split the XML data from WorkerDataLoad into parts that we hold here
CREATE TABLE dbo.WorkerData_Workers
(
    Id INT IDENTITY PRIMARY KEY,
    WorkerId char(10),
    Name varchar(100),
    OrgXML XML,
    LoadedDateTime DATETIME default getdate()
)

-- holds extracted organizational data for each worker
CREATE TABLE dbo.WorkerData_WorkerOrg
(
    Id INT IDENTITY PRIMARY KEY,
    WorkerId char(10),
    Name varchar(100),
    Code varchar(20),
    Type varchar(50),
    SubType varchar(50),
    OrgXML XML,
    LoadedDateTime DATETIME default getdate()
)

*/

--
-- clear data from previous runs. We're not doing incremental updates (yet)
--

delete from dbo.WorkerDataLoad
delete from dbo.WorkerData_Workers
delete from dbo.WorkerData_WorkerOrg
go

--
-- Read the (maybe huge) XML file we generated from Powershell and insert it into a SQL table
-- This file should be from the Get-Workers API called with Include_Organizations set to true
--
-- Folder specifications for file location refer to the SQL Server, not your workstation
--

insert into dbo.WorkerDataLoad(XMLData)
select CONVERT(XML, BulkColumn) AS XMLData
    from OPENROWSET(BULK 'c:\temp\WD_Workers_20230206_035959.xml', SINGLE_BLOB) AS x;

--
-- using XML we loaded from file, create a table with one record per user
--

insert into dbo.WorkerData_Workers(WorkerId, Name, OrgXML)
select 
     x.y.value('(*:Worker_Reference/*:ID[@*:type=''Employee_ID''])[1]', 'varchar(50)') WorkerID
    ,x.y.value('(*:Worker_Descriptor)[1]', 'varchar(50)') Name
    ,x.y.query('*:Worker_Data/*:Organization_Data/*') OrgXML
    from WorkerDataLoad wd
    cross apply wd.XMLData.nodes('*:Worker') x(y)

--
-- Extract organizational records from worker XML
--

insert into dbo.WorkerData_WorkerOrg (WorkerID, Name, Code, Type, SubType, OrgXML)
select 
     wd.WorkerID
    ,x.y.value('(*:Organization_Data/*:Organization_Name)[1]', 'varchar(100)') Name
    ,x.y.value('(*:Organization_Data/*:Organization_Code)[1]', 'varchar(100)') Code
    ,x.y.value('(*:Organization_Data/*:Organization_Type_Reference/*:ID[@*:type=''Organization_Type_ID''])[1]', 'varchar(100)') Type
    ,x.y.value('(*:Organization_Data/*:Organization_Subtype_Reference/*:ID[@*:type=''Organization_Subtype_ID''])[1]', 'varchar(100)') SubType
    ,x.y.query('*:Organization_Data/*') Organization_Data
    from WorkerData_Workers wd
    cross apply wd.OrgXML.nodes('*:Worker_Organization_Data') x(y)
