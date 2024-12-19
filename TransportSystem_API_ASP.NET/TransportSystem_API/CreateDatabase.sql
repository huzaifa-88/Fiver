Create the database
IF EXISTS (SELECT * FROM sys.databases WHERE name = 'BuaTransportSystem')
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


-- Drop tables in the correct order (child tables first)
IF OBJECT_ID('BusCheckIns', 'U') IS NOT NULL DROP TABLE BusCheckIns;
IF OBJECT_ID('DisplayBoards', 'U') IS NOT NULL DROP TABLE DisplayBoards;
IF OBJECT_ID('TimetableQueries', 'U') IS NOT NULL DROP TABLE TimetableQueries;
IF OBJECT_ID('BusTimeTable', 'U') IS NOT NULL DROP TABLE BusTimeTable;
IF OBJECT_ID('RouteStops', 'U') IS NOT NULL DROP TABLE RouteStops;
IF OBJECT_ID('BusCheckIns', 'U') IS NOT NULL DROP TABLE BusCheckIns;
IF OBJECT_ID('Buses', 'U') IS NOT NULL DROP TABLE Buses;
IF OBJECT_ID('Passengers', 'U') IS NOT NULL DROP TABLE Passengers;
IF OBJECT_ID('Routes', 'U') IS NOT NULL DROP TABLE Routes;
IF OBJECT_ID('Stops', 'U') IS NOT NULL DROP TABLE Stops;
IF OBJECT_ID('Holidays', 'U') IS NOT NULL DROP TABLE Holidays;
IF OBJECT_ID('TransportCompanies', 'U') IS NOT NULL DROP TABLE TransportCompanies;
GO

-- Parent Table: TransportCompanies
CREATE TABLE TransportCompanies (
    CompanyID INT IDENTITY(1,1) PRIMARY KEY,
    CompanyName NVARCHAR(100) NOT NULL,
    ContactEmail NVARCHAR(100) NOT NULL,
    PhoneNumber NVARCHAR(20),
    Password NVARCHAR(256),
    RegisteredDate DATE NOT NULL DEFAULT GETDATE()
);

-- Parent Table: Passengers
CREATE TABLE Passengers (
    PassengerID INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL,
    Email NVARCHAR(100),
    Password NVARCHAR(256)
);

-- Parent Table: Holidays
CREATE TABLE Holidays (
    HolidayID INT IDENTITY(1,1) PRIMARY KEY,
    HolidayName NVARCHAR(255) NOT NULL,
    StartDate DATE NOT NULL,
    EndDate DATE NOT NULL,
    IsSchoolVacation BIT NOT NULL,
    HolidayType NVARCHAR(50) NOT NULL,
    CHECK (StartDate <= EndDate)
);

-- Parent Table: Stops
CREATE TABLE Stops (
    StopID INT IDENTITY(1,1) PRIMARY KEY,
    StopName NVARCHAR(255) NOT NULL,
    ShortDesignation NVARCHAR(10) NOT NULL UNIQUE,
    Latitude DECIMAL(9, 6) NOT NULL,
    Longitude DECIMAL(9, 6) NOT NULL,
    CONSTRAINT CHK_ShortDesignation CHECK (ShortDesignation NOT LIKE '%[^a-zA-Z0-9]%')
);

-- Parent Table: Routes
CREATE TABLE Routes (
    RouteID INT IDENTITY(1,1) PRIMARY KEY,
    RouteNumber INT NOT NULL UNIQUE,  -- RouteNumber is now numeric (INT) and must be unique
    RouteName NVARCHAR(100) NOT NULL,  -- Added RouteName column for the route name
    ValidFrom DATE NOT NULL,
    ValidTo DATE NOT NULL,
    DailyValidity NVARCHAR(50) NOT NULL,
    StartStopID INT NOT NULL,
    EndStopID INT NOT NULL,
    FOREIGN KEY (StartStopID) REFERENCES Stops(StopID),
    FOREIGN KEY (EndStopID) REFERENCES Stops(StopID)
);

-- Parent Table: Buses
CREATE TABLE Buses (
    BusID INT IDENTITY(1,1) PRIMARY KEY,
    CompanyID INT NOT NULL,
    BusNumber NVARCHAR(50) NOT NULL,
    Capacity INT NOT NULL,
    FOREIGN KEY (CompanyID) REFERENCES TransportCompanies(CompanyID)
);

-- Child Table: RouteStops
CREATE TABLE RouteStops (
    RouteStopID INT IDENTITY(1,1) PRIMARY KEY,
    RouteID INT NOT NULL,
    StopID INT NOT NULL,
    SequenceNumber INT NOT NULL,
    ScheduledDepartureTime TIME NOT NULL,
    FOREIGN KEY (RouteID) REFERENCES Routes(RouteID),
    FOREIGN KEY (StopID) REFERENCES Stops(StopID),
    -- CONSTRAINT UC_Route_Stop UNIQUE (RouteID, StopID)
);

-- Child Table: BusTimeTable
CREATE TABLE BusTimeTable (
    BusTimeTableID INT IDENTITY(1,1) PRIMARY KEY,
    BusID INT NOT NULL,
    RouteStopID INT NOT NULL,
    ArrivalTime TIME NOT NULL,
    DepartureTime TIME NOT NULL,
    DayOfWeek NVARCHAR(20) NOT NULL,
    IsHolidayApplicable BIT NOT NULL DEFAULT 0,
    FOREIGN KEY (BusID) REFERENCES Buses(BusID),
    FOREIGN KEY (RouteStopID) REFERENCES RouteStops(RouteStopID)
);

CREATE TABLE BusCheckIns(
    BusCheckInID INT IDENTITY(1,1) PRIMARY KEY,
    BusID INT NOT NULL,
    RouteStopID INT NOT NULL,
    CheckINArrivalTime DATETIME NOT NULL DEFAULT GETDATE(),
    Delay INT NOT NULL,
    FOREIGN KEY (BusID) REFERENCES Buses(BusID),
    FOREIGN KEY (RouteStopID) REFERENCES RouteStops(RouteStopID)
)

-- Child Table: TimetableQueries
CREATE TABLE TimetableQueries (
    QueryID INT IDENTITY(1,1) PRIMARY KEY,
    PassengerID INT NOT NULL,
    StartStopID INT NOT NULL,
    DestinationStopID INT NOT NULL,
    QueryDateTime DATETIME NOT NULL DEFAULT GETDATE(),
    DepartureDateTime DATETIME NULL,
    IsArrivalTime BIT NOT NULL DEFAULT 0,
    NumberOfConnections INT NOT NULL DEFAULT 1 CHECK (NumberOfConnections >= 1),
    FOREIGN KEY (PassengerID) REFERENCES Passengers(PassengerID),
    FOREIGN KEY (StartStopID) REFERENCES Stops(StopID),
    FOREIGN KEY (DestinationStopID) REFERENCES Stops(StopID)
);

-- Child Table: DisplayBoards
CREATE TABLE DisplayBoards (
    DisplayID INT IDENTITY(1,1) PRIMARY KEY,
    StopID INT NOT NULL,
    RouteID INT NOT NULL,
    NextDepartureTime DATETIME NOT NULL,
    DelayMinutes INT DEFAULT 0,
    FOREIGN KEY (StopID) REFERENCES Stops(StopID),
    FOREIGN KEY (RouteID) REFERENCES Routes(RouteID)
);