-- Create the database
DROP DATABASE EPAMonitoring_Assignment2;
CREATE DATABASE EPAMonitoring_Assignment2;
GO
USE EPAMonitoring_Assignment2;

-- Create DIM_Activity
CREATE TABLE DIM_Activity (
    Activity_ID INT PRIMARY KEY,
    Activity_Type NVARCHAR(100),
);

-- Create DIM_Officer
CREATE TABLE DIM_Officer (
    Officer_ID INT PRIMARY KEY,
    Officer_Name NVARCHAR(100)
);

-- Create DIM_Site
CREATE TABLE DIM_Site (
    Site_ID INT PRIMARY KEY,
    Site_Name NVARCHAR(100),
    Site_Location NVARCHAR(255)
);

-- Create price history table
CREATE TABLE DIM_PriceHistory (
    Price_ID UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    Price DECIMAL(10, 2),
    Monitoring_Date DATE,
);

-- Create the Fact Table
CREATE TABLE Fact_EPAMonitoring (
    Fact_ID UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),  -- UUID Primary Key
    Transaction_ID INT,
    Officer_ID INT,
    Site_ID INT,
    Activity_ID INT,
    Use_More_Than_Five_Equipments BIT,
    Equipment_Used INT,
    Compliance_Status NVARCHAR(50),
    Community_Feedback_Rating INT,
    Pollution_Level_Detected DECIMAL(10, 2),
    Activity_Duration DECIMAL(5, 2),
    Activity_Description NVARCHAR(255),
    Price_ID UNIQUEIDENTIFIER,
    Total DECIMAL(10, 2),
    Office_Location NVARCHAR(50),
    Incentive_Received NVARCHAR(5),
    Compliance_Target_Achieved NVARCHAR(5)
    FOREIGN KEY (Officer_ID) REFERENCES DIM_Officer(Officer_ID),
    FOREIGN KEY (Site_ID) REFERENCES DIM_Site(Site_ID),
    FOREIGN KEY (Activity_ID) REFERENCES DIM_Activity(Activity_ID),
    FOREIGN KEY (Price_ID) REFERENCES DIM_PriceHistory(Price_ID),
);

CREATE TABLE Temp_EPAMonitoring (
    Monitoring_Date VARCHAR(100),
    Officer_ID INT,
    Officer_Name NVARCHAR(100),
    Office_Location NVARCHAR(50),
    Site_ID INT,
    Site_Name NVARCHAR(100),
    Site_Location NVARCHAR(255),
    Activity_ID VARCHAR(10),
    Activity_Type NVARCHAR(100),
    Activity_Description NVARCHAR(255),
    Activity_Duration VARCHAR(20),
    Equipment_Used VARCHAR(50),
    Pollution_Level_Detected DECIMAL(10, 2),
    Compliance_Status NVARCHAR(50),
    Community_Feedback_Rating INT,
    Transaction_ID INT,
    Incentive_Received NVARCHAR(5),
    Compliance_Target_Achieved NVARCHAR(5)
);

-- I am using datagrip for running SQL, and I am importing the data in TEMP_EPAMonitoring with the GUI

-- delete all values without ids
DELETE FROM Temp_EPAMonitoring WHERE Activity_ID IS NULL OR Site_ID IS NULL OR Officer_ID IS NULL;

-- Change data from Equipment Used to integer or easier calculation
UPDATE Temp_EPAMonitoring
SET Equipment_Used = SUBSTRING(Equipment_Used,
                                  PATINDEX('%[0-9]%', Equipment_Used),
                                  LEN(Equipment_Used))
WHERE Equipment_Used IS NOT NULL;

-- update unique ids for each officer
-- create temporary table for storing unique officer
CREATE TABLE #UniqueOfficer (
    Officer_ID INT,
    Officer_Name NVARCHAR(100)
);

-- insert distinct values in #UniqueOfficer table
INSERT INTO #UniqueOfficer (Officer_ID, Officer_Name)
SELECT DISTINCT
    NUll As Officer_ID,
    Officer_Name
FROM Temp_EPAMonitoring;

-- insert unique values and ids in DIM_Officer table after checking duplicates
INSERT INTO DIM_Officer (Officer_ID, Officer_Name)
SELECT
    ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) + (SELECT ISNULL(MAX(Officer_ID), 0) FROM DIM_Officer),
    ua.Officer_Name
FROM #UniqueOfficer ua
LEFT JOIN DIM_Officer da ON
    ua.Officer_Name = da.Officer_Name
WHERE da.Officer_Id IS NULL; -- Only insert if it doesn't exist

-- update Temp_EPAMonitoring database officer ids with one in DIM_Officer table
UPDATE t
SET t.Officer_ID = am.Officer_ID
FROM Temp_EPAMonitoring t
JOIN DIM_Officer am ON
    t.Officer_Name = am.Officer_Name

-- drop temporary table
DROP TABLE #UniqueOfficer;



-- update unique ids for each site
-- create temporary table for storing unique site
CREATE TABLE #UniqueSite (
    Site_ID INT,
    Site_Name NVARCHAR(100),
    Site_Location NVARCHAR(255)
);

-- insert distinct values in #UniqueSite table
INSERT INTO #UniqueSite (Site_ID, Site_Name, Site_Location)
SELECT DISTINCT
    NUll As Site_ID,
    Site_Name,
    Site_Location
FROM Temp_EPAMonitoring;

-- insert unique values and ids in DIM_Site table after checking duplicates
INSERT INTO DIM_Site (Site_ID, Site_Name, Site_Location)
SELECT
    ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) + (SELECT ISNULL(MAX(Site_ID), 0) FROM DIM_Site),
    ua.Site_Name,
    ua.Site_Location
FROM #UniqueSite ua
LEFT JOIN DIM_Site da ON
    ua.Site_Name = da.Site_Name AND
    ua.Site_Location = da.Site_Location
WHERE da.Site_ID IS NULL; -- Only insert if it doesn't exist

-- update Temp_EPAMonitoring database site ids with one in DIM_Site table
UPDATE t
SET t.Site_ID = am.Site_ID
FROM Temp_EPAMonitoring t
JOIN DIM_Site am ON
    t.Site_Name = am.Site_Name AND
    t.Site_Location = am.Site_Location

-- drop temporary table
DROP TABLE #UniqueSite;


-- update unique ids for each site
-- create temporary table for storing unique activity
CREATE TABLE #UniqueActivity (
    Activity_ID INT,
    Activity_Type NVARCHAR(100),
);

-- insert distinct values in #UniqueSite table
INSERT INTO #UniqueActivity (Activity_ID, Activity_Type)
SELECT DISTINCT
    NUll As Activity_ID,
    Activity_Type
FROM Temp_EPAMonitoring;

-- insert unique values and ids in DIM_Site table after checking duplicates
INSERT INTO DIM_Activity (Activity_ID, Activity_Type)
SELECT
    ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) + (SELECT ISNULL(MAX(Activity_ID), 0) FROM DIM_Activity),
    ua.Activity_Type
FROM #UniqueActivity ua
LEFT JOIN DIM_Activity da ON
    ua.Activity_Type = da.Activity_Type
WHERE da.Activity_ID IS NULL; -- Only insert if it doesn't exist

-- update Temp_EPAMonitoring database site ids with one in DIM_Site table
UPDATE t
SET t.Activity_ID = am.Activity_ID
FROM Temp_EPAMonitoring t
JOIN DIM_Activity am ON
    t.Activity_Type = am.Activity_Type

-- drop temporary table
DROP TABLE #UniqueActivity;

-- update price history table with random values and unique monitoring date
INSERT INTO DIM_PriceHistory (Monitoring_Date, Price)
SELECT DISTINCT
    CONVERT(DATE, Monitoring_Date, 105),  -- Convert Monitoring_Date to DATE
    CAST(ROUND((RAND(CHECKSUM(NEWID())) * (500 - 100) + 100), 2) AS NVARCHAR(100))  -- Generate unique random price between 100 and 500 for each row
FROM Temp_EPAMonitoring
WHERE Monitoring_Date IS NOT NULL

ALTER TABLE Temp_EPAMonitoring
ADD Price_ID UNIQUEIDENTIFIER;

UPDATE t
SET t.Price_ID = ph.Price_ID
FROM Temp_EPAMonitoring t
LEFT JOIN DIM_PriceHistory ph
    ON CONVERT(DATE, t.Monitoring_Date, 105) = ph.Monitoring_Date;

SELECT t.Monitoring_Date, t.Price_ID, ph.Price
FROM Temp_EPAMonitoring t
LEFT JOIN DIM_PriceHistory ph
    ON t.Price_ID = ph.Price_ID
WHERE t.Price_ID IS NULL; -- Ensure no missing mappings

INSERT INTO Fact_EPAMonitoring (
    Transaction_ID,
    Officer_ID,
    Site_ID,
    Activity_ID,
    Use_More_Than_Five_Equipments,
    Equipment_Used,
    Compliance_Status,
    Community_Feedback_Rating,
    Pollution_Level_Detected,
    Activity_Duration,
    Activity_Description,
    Price_ID,
    Total,
    Office_Location,
    Incentive_Received,
    Compliance_Target_Achieved
)
SELECT
    Transaction_ID,
    Officer_ID,
    Site_ID,
    Activity_ID,
    IIF(Equipment_Used > 5, 1, 0) AS Use_More_Than_Five_Equipments,
    Equipment_Used,
    Compliance_Status,
    Community_Feedback_Rating,
    Pollution_Level_Detected,
    Activity_Duration,
    Activity_Description,
    ph.Price_ID,
    (ph.Price * Equipment_Used),
    Office_Location,
    Incentive_Received,
    Compliance_Target_Achieved
FROM
    Temp_EPAMonitoring t
LEFT JOIN DIM_PriceHistory ph ON t.Price_ID = ph.Price_ID
WHERE ph.Price_ID IS NOT NULL;  -- Ensure you are inserting only when there's a matching price

UPDATE Fact_EPAMonitoring
SET Compliance_Target_Achieved = 'No'
WHERE Compliance_Target_Achieved IS NULL
  AND Incentive_Received = 'No';

DROP TABLE Temp_EPAMonitoring;

-- This step I did because I tried working with powerBI and since I use mac, 
-- I only could use the web version for it.
-- I am running SQL server in docker so couldnt connect to online powerBI version.
-- So either I needed to host my database online or use csv.
-- However, later, I decided to use Excel and used csv to load data there.

-- Drop the denormalized table if it already exists
DROP TABLE IF EXISTS Denormalized_EPAMonitoring;

-- Drop the denormalized table if it already exists
IF OBJECT_ID('Denormalized_EPAMonitoring', 'U') IS NOT NULL
    DROP TABLE Denormalized_EPAMonitoring;

-- Create the denormalized table structure
CREATE TABLE Denormalized_EPAMonitoring (
    Transaction_ID INT,
    Officer_ID INT,
    Officer_Name NVARCHAR(100),
    Site_ID INT,
    Site_Name NVARCHAR(100),
    Site_Location NVARCHAR(255),
    Activity_ID INT,
    Activity_Type NVARCHAR(100),
    Activity_Description NVARCHAR(255),
    Activity_Duration DECIMAL(5, 2),
    Equipment_Used INT,
    Use_More_Than_Five_Equipments BIT,
    Pollution_Level_Detected DECIMAL(10, 2),
    Compliance_Status NVARCHAR(50),
    Community_Feedback_Rating INT,
    Office_Location NVARCHAR(50),
    Incentive_Received NVARCHAR(5),
    Compliance_Target_Achieved NVARCHAR(5),
    Price_ID UNIQUEIDENTIFIER,
    Monitoring_Date DATE,
    Price DECIMAL(10, 2),
    Total DECIMAL(10, 2)
);

-- Insert data into the denormalized table
INSERT INTO Denormalized_EPAMonitoring (
    Transaction_ID,
    Officer_ID,
    Officer_Name,
    Site_ID,
    Site_Name,
    Site_Location,
    Activity_ID,
    Activity_Type,
    Activity_Description,
    Activity_Duration,
    Equipment_Used,
    Use_More_Than_Five_Equipments,
    Pollution_Level_Detected,
    Compliance_Status,
    Community_Feedback_Rating,
    Office_Location,
    Incentive_Received,
    Compliance_Target_Achieved,
    Price_ID,
    Monitoring_Date,
    Price,
    Total
)
SELECT
    f.Transaction_ID,
    f.Officer_ID,
    o.Officer_Name,
    f.Site_ID,
    s.Site_Name,
    s.Site_Location,
    f.Activity_ID,
    a.Activity_Type,
    f.Activity_Description,
    f.Activity_Duration,
    f.Equipment_Used,
    IIF(f.Equipment_Used > 5, 1, 0) AS Use_More_Than_Five_Equipments,
    f.Pollution_Level_Detected,
    f.Compliance_Status,
    f.Community_Feedback_Rating,
    f.Office_Location,
    f.Incentive_Received,
    f.Compliance_Target_Achieved,
    f.Price_ID,
    ph.Monitoring_Date,
    ph.Price,
    f.Total
FROM
    Fact_EPAMonitoring f
LEFT JOIN DIM_Officer o ON f.Officer_ID = o.Officer_ID
LEFT JOIN DIM_Site s ON f.Site_ID = s.Site_ID
LEFT JOIN DIM_Activity a ON f.Activity_ID = a.Activity_ID
LEFT JOIN DIM_PriceHistory ph ON f.Price_ID = ph.Price_ID;