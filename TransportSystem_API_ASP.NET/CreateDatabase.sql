Create the database
IF EXISTS (SELECT * FROM sys.databases WHERE name = 'PublicTransportSystem')
BEGIN
   ALTER DATABASE PublicTransportSystem SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
   DROP DATABASE PublicTransportSystem;
END
GO

CREATE DATABASE PublicTransportSystem;
GO

-- Use the database
USE PublicTransportSystem;
GO

-- Drop tables if they already exist
IF OBJECT_ID('DelayStatisticsDiagrams', 'U') IS NOT NULL DROP TABLE DelayStatisticsDiagrams;
IF OBJECT_ID('DelayStatistics', 'U') IS NOT NULL DROP TABLE DelayStatistics;
IF OBJECT_ID('BusCheckIns', 'U') IS NOT NULL DROP TABLE BusCheckIns;
IF OBJECT_ID('DisplayBoards', 'U') IS NOT NULL DROP TABLE DisplayBoards;
IF OBJECT_ID('PassengerQueries', 'U') IS NOT NULL DROP TABLE PassengerQueries;
IF OBJECT_ID('Timetables', 'U') IS NOT NULL DROP TABLE Timetables;
IF OBJECT_ID('Buses', 'U') IS NOT NULL DROP TABLE Buses;
IF OBJECT_ID('Passengers', 'U') IS NOT NULL DROP TABLE Passengers;
IF OBJECT_ID('Routes', 'U') IS NOT NULL DROP TABLE Routes;
IF OBJECT_ID('Stops', 'U') IS NOT NULL DROP TABLE Stops;
IF OBJECT_ID('Holidays', 'U') IS NOT NULL DROP TABLE Holidays;
IF OBJECT_ID('TransportCompanies', 'U') IS NOT NULL DROP TABLE TransportCompanies;
GO

-- Create TransportCompanies table
CREATE TABLE TransportCompanies (
    CompanyID INT IDENTITY(1,1) PRIMARY KEY,
    CompanyName NVARCHAR(100) NOT NULL,
    ContactEmail NVARCHAR(100) NOT NULL,
    PhoneNumber NVARCHAR(20),
    Password NVARCHAR(256),
    RegisteredDate DATE NOT NULL DEFAULT GETDATE()
);

-- Create Holidays table
CREATE TABLE Holidays (
    HolidayID INT IDENTITY(1,1) PRIMARY KEY,
    HolidayName NVARCHAR(255) NOT NULL,
    StartDate DATE NOT NULL,            -- Start date for the holiday or vacation
    EndDate DATE NOT NULL,              -- End date for the holiday or vacation
    IsSchoolVacation BIT NOT NULL,      -- TRUE if it's a school vacation, FALSE otherwise
    HolidayType NVARCHAR(50) NOT NULL,  -- Type of the holiday (e.g., 'School', 'Public', 'Other')
    CHECK (StartDate <= EndDate)        -- Ensure start date is before or equal to end date
);

-- Create Stops table
CREATE TABLE Stops (
    StopID INT IDENTITY(1,1) PRIMARY KEY,
    StopName NVARCHAR(255) NOT NULL,
    ShortDesignation NVARCHAR(10) NOT NULL UNIQUE,  -- Unique, no spaces or special characters
    Latitude DECIMAL(9, 6) NOT NULL,  -- GPS Coordinates
    Longitude DECIMAL(9, 6) NOT NULL, -- GPS Coordinates
    CONSTRAINT CHK_ShortDesignation CHECK (ShortDesignation NOT LIKE '%[^a-zA-Z0-9]%')  -- Ensure no special characters
);


CREATE TABLE Routes (
    RouteID INT IDENTITY(1,1) PRIMARY KEY,
    RouteNumber NVARCHAR(50) NOT NULL UNIQUE,     -- Route number
    ValidFrom DATE NOT NULL,                      -- Validity period start date
    ValidTo DATE NOT NULL,                        -- Validity period end date
    DailyValidity NVARCHAR(50) NOT NULL,          -- Daily validity (e.g., weekdays, holidays)
    StartStopID INT NOT NULL,                     -- Foreign key to Stops table (Start Stop)
    EndStopID INT NOT NULL,                       -- Foreign key to Stops table (End Stop)
    FOREIGN KEY (StartStopID) REFERENCES Stops(StopID),
    FOREIGN KEY (EndStopID) REFERENCES Stops(StopID)
);


-- 3. RouteStops Table
CREATE TABLE RouteStops (
    RouteStopID INT IDENTITY(1,1) PRIMARY KEY,
    RouteID INT NOT NULL,                         -- Foreign key to Routes table
    StopID INT NOT NULL,                          -- Foreign key to Stops table
    SequenceNumber INT NOT NULL,                  -- Sequence of stops in the route
    ScheduledDepartureTime TIME NOT NULL,         -- Scheduled departure time
    FOREIGN KEY (RouteID) REFERENCES Routes(RouteID),
    FOREIGN KEY (StopID) REFERENCES Stops(StopID),
    CONSTRAINT UC_Route_Stop UNIQUE (RouteID, StopID)
);

-- Create Timetables table
CREATE TABLE Timetables (
    TimetableID INT IDENTITY(1,1) PRIMARY KEY,
    RouteID INT NOT NULL,
    DepartureTime DATETIME NOT NULL,
    ArrivalTime DATETIME NOT NULL,
    IsHolidayApplicable BIT NOT NULL DEFAULT 0,
    FOREIGN KEY (RouteID) REFERENCES Routes(RouteID)
);

-- Create Passengers table
CREATE TABLE Passengers (
    PassengerID INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL,
    Email NVARCHAR(100),
    PhoneNumber NVARCHAR(20)
);

-- Create PassengerQueries table
CREATE TABLE PassengerQueries (
    QueryID INT IDENTITY(1,1) PRIMARY KEY,
    PassengerID INT,
    QueryType NVARCHAR(20) CHECK (QueryType IN ('StopSearch', 'TimetableSearch')),
    QueryDetails NVARCHAR(MAX) NOT NULL,
    QueryTimestamp DATETIME NOT NULL DEFAULT GETDATE(),
    FOREIGN KEY (PassengerID) REFERENCES Passengers(PassengerID)
);

-- Create DisplayBoards table
CREATE TABLE DisplayBoards (
    DisplayID INT IDENTITY(1,1) PRIMARY KEY,
    StopID INT NOT NULL,
    RouteID INT NOT NULL,
    NextDepartureTime DATETIME NOT NULL,
    DelayMinutes INT DEFAULT 0,
    FOREIGN KEY (StopID) REFERENCES Stops(StopID),
    FOREIGN KEY (RouteID) REFERENCES Routes(RouteID)
);

-- Create Buses table
CREATE TABLE Buses (
    BusID INT IDENTITY(1,1) PRIMARY KEY,
    CompanyID INT NOT NULL,
    BusNumber NVARCHAR(50) NOT NULL,
    Capacity INT NOT NULL,
    FOREIGN KEY (CompanyID) REFERENCES TransportCompanies(CompanyID)
);

-- Create BusCheckIns table
CREATE TABLE BusCheckIns (
    CheckInID INT IDENTITY(1,1) PRIMARY KEY,
    BusID INT NOT NULL,
    CheckInTimestamp DATETIME NOT NULL DEFAULT GETDATE(),
    CurrentStopID INT NOT NULL,
    LocationLatitude DECIMAL(10, 8) NOT NULL,
    LocationLongitude DECIMAL(11, 8) NOT NULL,
    DelayMinutes INT DEFAULT 0,
    FOREIGN KEY (BusID) REFERENCES Buses(BusID),
    FOREIGN KEY (CurrentStopID) REFERENCES Stops(StopID)
);

-- Create DelayStatistics table
CREATE TABLE DelayStatistics (
    StatisticID INT IDENTITY(1,1) PRIMARY KEY,
    BusID INT NOT NULL,
    TotalDelays INT NOT NULL,
    AverageDelayMinutes FLOAT NOT NULL,
    LastUpdated DATETIME NOT NULL DEFAULT GETDATE(),
    FOREIGN KEY (BusID) REFERENCES Buses(BusID)
);

-- Create DelayStatisticsDiagrams table
CREATE TABLE DelayStatisticsDiagrams (
    DiagramID INT IDENTITY(1,1) PRIMARY KEY,
    StatisticID INT NOT NULL,
    DiagramData VARBINARY(MAX),
    FOREIGN KEY (StatisticID) REFERENCES DelayStatistics(StatisticID)
);
