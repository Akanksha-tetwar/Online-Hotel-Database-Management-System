---Project Team 13
---Online Hotel Booking Database Management system
--Team Members
--1.Aditya Bhabhe
--2.Akansha Tetwar
--3.Ashlesha Gokhale
--4.Durga Bhavani.
--5.Surbhi Wagh


----AccountNumber constraint-------------------

CREATE FUNCTION mydb.isValidAccount(@AccountNumber INT)
RETURNS BIT
BEGIN
RETURN IIF(LEN(@AccountNumber) = 6, 1, 0)
END

GO

ALTER TABLE mydb.Customer
ADD CONSTRAINT checkAccount CHECK (mydb.isValidAccount(AccountNumber) = 1)

---Valid zip constraint-----
CREATE FUNCTION mydb.isValidZipcode(@zipcode VARCHAR(100))
RETURNS BIT
BEGIN
RETURN IIF(LEN(@zipcode) = 5, 1, 0)
END

GO

ALTER TABLE mydb.Location
ADD CONSTRAINT checkZipcode CHECK (mydb.isValidZipcode(zipcode) = 1)



----CheckOut Date constraint-------------------

CREATE FUNCTION mydb.CheckDateCorrect2 (@CheckinDate DateTime, @CheckoutDate DateTime )
RETURNS int
AS 
BEGIN
  DECLARE @retval int
    SELECT @retval = CASE WHEN @CheckoutDate >= @CheckinDate THEN 0 ELSE 1 END
    FROM mydb.BOOKING_DETAILS

  RETURN @retval
END;
GO

ALTER TABLE mydb.BOOKING_DETAILS 
  ADD CONSTRAINT CheckCorrectDate 
  CHECK (mydb.CheckDateCorrect2(CheckinDate, CheckoutDate) = 0); 



------CardNumber Constraint-------------

CREATE FUNCTION mydb.isValidCard(@CardNumber VARCHAR(50))
RETURNS INT
BEGIN
RETURN IIF(LEN(@CardNumber) = 16, 1, 0)
END

GO

ALTER TABLE mydb.CUSTOMER
ADD CONSTRAINT CheckCardNo CHECK (mydb.isValidCard(CardNumber) = 1)

-------Account Balance Check constraint----------------

CREATE FUNCTION mydb.CorrectBal(@amount FLOAT)
RETURNS BIT
BEGIN
RETURN IIF(@amount > 1000, 1, 0)
END

GO

ALTER TABLE mydb.Customer
ADD CONSTRAINT CheckAccBal CHECK (mydb.CorrectBal(AccountBalance) = 1)


-----Payment check contraint----

CREATE FUNCTION mydb.isValidPayment(@amount FLOAT)
RETURNS BIT
BEGIN
RETURN IIF(@amount > 0, 1, 0)
END

GO

ALTER TABLE mydb.Payment
ADD CONSTRAINT checkPaymentAmt CHECK (mydb.isValidPayment(PaymentAmount) = 1)


-----Computed column for actual stay----

ALTER FUNCTION mydb.staydurationhotel (@CheckinDate DateTime, @CheckoutDate DateTime )
RETURNS int
AS 
BEGIN
  RETURN DATEDIFF(day, @CheckinDate,@CheckoutDate) 
    END;
GO

ALTER TABLE mydb.BOOKING_DETAILS
ADD  Actualstay_duration  as  mydb.staydurationhotel(CheckinDate, CheckoutDate)



------------FullName computed column ------

CREATE function mydb.get_full_name (@first_name VARCHAR(45), @last_name VARCHAR(45))
RETURNs VARCHAR(92) 
AS
BEGIN
DECLARE @full_name VARCHAR(92) = CONCAT(@first_name, ' ', @last_name)

RETURN @full_name;
END

GO

ALTER TABLE mydb.person
ADD FullName AS mydb.get_full_name(FirstName, LastName)

select * from mydb.PERSON



----RoomBooking_Computed column----------

CREATE FUNCTION mydb.getTotalPriceAfterDiscount(@TotalPrice FLOAT, @Discount FLOAT)
RETURNS FLOAT
BEGIN

RETURN @TotalPrice - @Discount

END

GO
ALTER TABLE mydb.ROOM_BOOKING
ADD Discount FLOAT DEFAULT 0,
	TotalPriceAfterDiscount AS mydb.getTotalPriceAfterDiscount(TotalPrice, Discount)



----------Restaurant Computed column------


CREATE function mydb.RestName_Cuisine (@RestaurantName VARCHAR(100), @Cuisine VARCHAR(50))
RETURNs VARCHAR(100) 
AS
BEGIN
DECLARE @RestName_Cuisine VARCHAR(100) = CONCAT(@RestaurantName, ' ', @Cuisine)

RETURN @RestName_Cuisine;
END

GO

ALTER TABLE mydb.RESTAURANTS
ADD RestName_Cuisine AS mydb.RestName_Cuisine(RestaurantName, Cuisine)

---Function which takes hotel id as input and returns avg of that particular hotel CREATE FUNCTION CalAvgOfHotel2(@hotelID int)

CREATE FUNCTION CalAvgOfHotel2(@hotelID int)
RETURNS FLOAT
AS
    BEGIN

        DECLARE @TotalRating FLOAT
        SET @TotalRating = (SELECT a.TotalRating FROM (SELECT r.HOTEL_HotelID, COUNT(r.CUSTOMER_CustomerID) as NoOfCustomerID, sum(r.Rating)  As TotalRating  
        from mydb.Rating r
        where r.HOTEL_HotelID =@hotelID
        GROUP BY r.HOTEL_HotelID) AS a)

        DECLARE @NoOfCustomer FLOAT 
        SET @NoOfCustomer = (SELECT a.NoOfCustomerID FROM (SELECT r.HOTEL_HotelID, COUNT(r.CUSTOMER_CustomerID) as NoOfCustomerID, sum(r.Rating)  As TotalRating  
        from mydb.Rating r
        where r.HOTEL_HotelID =@hotelID
        GROUP BY r.HOTEL_HotelID) AS a)

        DECLARE @AvgOfHotel FLOAT
        SET @AvgOfHotel = (@TotalRating / @NoOfCustomer)
        
RETURN @AvgOfHotel 
END;

select dbo.CalAvgOfHotel2(8);

---Function which calculates the percentage change in the number of reservations of given input months

CREATE FUNCTION PercentChange2(@prevMonth int, @month int)
RETURNS FLOAT
AS
    BEGIN
        DECLARE @NoOdReservationsPrevMonth float 
            set @NoOdReservationsPrevMonth= ( select a.NoOfReservations from(
        select MONTH(BOOKINGDATE) As month1, COUNT([ROOM_BOOKING _ReservationID]) As NoOfReservations 
        FROM mydb.BOOKING_DETAILS bd 
        join mydb.ROOM_BOOKING rb 
        on bd.[ROOM_BOOKING _ReservationID] = rb.ReservationID
        group by MONTH(BOOKINGDATE) ) As a 
        WHERE month1 =@prevMonth) 

        DECLARE @NoOfReservationsMonth float 
        set @NoOfReservationsMonth= ( select a.NoOfReservations from(
        select MONTH(BOOKINGDATE) As month1, COUNT([ROOM_BOOKING _ReservationID]) As NoOfReservations 
        FROM mydb.BOOKING_DETAILS bd 
        join mydb.ROOM_BOOKING rb 
        on bd.[ROOM_BOOKING _ReservationID] = rb.ReservationID
        group by MONTH(BOOKINGDATE) ) As a 
        WHERE month1 =@month) 

RETURN ((@NoOfReservationsMonth - @NoOdReservationsPrevMonth) / @NoOfReservationsMonth )*100 

END;

select dbo.PercentChange2(6,7);



--------------Trigger------------------------------------

Create table mydb.HOTEL_RATING(HotelID INT,RATING FLOAT)
GO

CREATE TRIGGER Update_Hotel_Rating ON  mydb.RATING
AFTER INSERT, UPDATE 
AS
BEGIN
TRUNCATE TABLE mydb.HOTEL_RATING
INSERT INTO mydb.HOTEL_RATING
SELECT HOTEL_HotelID, AVG(Rating)
FROM mydb.RATING
GROUP BY HOTEL_HotelID

END

-------View to get the rating for the hotesl that had customer

create view mydb.HotelView as
WITH
  cte1 (HotelId,Rating)
  AS
(select a.HotelID, 
CAST(sum(d.Rating) as FLOAT)/COUNT(CUSTOMER_CustomerID) as 'rating' from mydb.HOTEL as a

inner join mydb.LOCATION as b on  a.LOCATION_LocationID = b.LocationID
inner join mydb.NEARBY_AIRPORT as c on b.LocationID = c.LOCATION_LocationID
inner join mydb.RATING as d on d.HOTEL_HotelID = a.HotelID

GROUP BY a.HotelID), 
--inner join


  cte2 (city, state, country, airportname, hotelid, hotelName)
  AS
  (
select loc.City, loc.State, loc.Country,  nea.airportname, hot.HotelID, hot.HotelName from mydb.LOCATION as loc
join mydb.NEARBY_AIRPORT as nea on loc.LocationID = nea.LOCATION_LocationID
inner join mydb.HOTEL as hot on hot.LOCATION_LocationID = loc.LocationID
)
select cte1.HotelId,cte2.hotelName, cte2.city,cte2.state,cte2.country,cte2.airportname,cte1.Rating from cte1 inner join cte2 on cte1.hotelid = cte2.hotelid


------View Price and rating---------

CREATE VIEW Price_and_rating  AS
select rb.TotalPrice, rb.CUSTOMER_CustomerID, r.Rating, r.HOTEL_HotelID from mydb.ROOM_BOOKING rb
join mydb.RATING r 
on rb.CUSTOMER_CustomerID = r.CUSTOMER_CustomerID
where rb.TotalPrice > 1000 and r.Rating > 3;


-------View for viewing the booking information-----

Create view  mydb.BookinINFO as 
select distinct  P.FirstName , P.LastName, P.EmailId,RB.NoOfGuests,BD.CheckinDate,BD.CheckoutDate,
BD.BookingDate,H.HotelName ,L.City,R.Rating,PA.PaymentAmount 
from mydb.PERSON P
JOIN mydb.CUSTOMER C
ON P.personID =C.Person_PersonId
JOIN mydb.ROOM_BOOKING RB 
ON C.CustomerID = RB.CUSTOMER_CustomerID
JOIN mydb.RATING R
ON C.CustomerID =R.CUSTOMER_CustomerID
JOIN mydb.BOOKING_DETAILS BD
ON RB.ReservationID = BD.[ROOM_BOOKING _ReservationID]
JOIN mydb.BOOKING_ROOM_DETAILS BRD
ON RB.ReservationID =BRD.[ROOM_BOOKING _ReservationID]
JOIN mydb.HOTEL_ROOM HR
ON BRD.HOTEL_ROOM_RoomID = HR.HOTEL_HotelID
JOIN mydb.HOTEL H
ON HR.HOTEL_HotelID = H.HotelID
JOIN mydb.LOCATION L
ON H.LOCATION_LocationID = L.LocationID
JOIN  mydb.PAYMENT PA
ON PA.BOOKING_DETAILS_BookingID = BD.BookingID
JOIN mydb.FEEDBACK FE
ON FE.HOTEL_HotelID = H.HotelID;



-----View for Hotel guest information-----------------------------------------------------------

CREATE  VIEW Hotel_guests as
	select FirstName , LastName ,EmailId , PhoneNumber
		from mydb.PERSON
		join mydb.CUSTOMER 
		on PERSON.PersonId = CUSTOMER.PERSON_PersonId
		where PersonId IN (SELECT DISTINCT CustomerID from mydb.CUSTOMER);

---------------------------------------------------------------------------------------------------------------------------------
---------------------CREATE QUERY--------------------------------------------------------------------------
CREATE SCHEMA mydb ;
USE [mydb] ;

-- Create Tble for CHECKIN

CREATE TABLE mydb.CHECKIN (
  [CheckinID] INT NOT NULL ,
  [CheckinDate] DATETIME2(0) NOT NULL,
  [CheckoutDate] DATETIME2(0) NOT NULL,
  PRIMARY KEY (CheckinID));


-- Create Tble for BOOKING_SOURCE

CREATE TABLE mydb.BOOKING_SOURCE (
  [BookingTypeID] INT NOT NULL ,
  [BookingType] VARCHAR(100) NULL DEFAULT NULL,
  PRIMARY KEY ([BookingTypeID]));


-- Create table Person
CREATE TABLE mydb.PERSON (
  [PersonId] INT NOT NULL,
  [FirstName] VARCHAR(45) NULL,
  [LastName] VARCHAR(45) NULL,
  [EmailId] VARCHAR(100) NULL,
  [BirthDate] DATE NULL,
  [PhoneNumber] INT NULL,
  [Gender] VARCHAR(45) NULL,
  PRIMARY KEY ([PersonId]));


-- Customer table creation

CREATE TABLE mydb.CUSTOMER (
  [CustomerID] INT NOT NULL ,
  [CardNumber] VARCHAR(50) NULL DEFAULT NULL,
  [SecurityCode] VARCHAR(10) NULL DEFAULT NULL,
  [NameOnCard] VARCHAR(100) NULL DEFAULT NULL,
  [BankName] VARCHAR(50) NULL DEFAULT NULL,
  [RoutingNumber] VARCHAR(50) NULL DEFAULT NULL,
  [AccountNumber] INT NULL DEFAULT NULL,
  [PERSON_PersonId] INT NOT NULL,
  PRIMARY KEY ([CustomerID]),
   FOREIGN KEY ([PERSON_PersonId])
    REFERENCES mydb.PERSON([PersonId]));
    

-- Table for ROOM_BOOKING

CREATE TABLE mydb.ROOM_BOOKING  (
  [ReservationID] INT NOT NULL ,
  [NoOfGuests] INT NULL DEFAULT NULL,
  [NoOfRooms] INT NULL DEFAULT NULL,
  [BookingStartDate] DATE NULL DEFAULT NULL,
  [BookingEndDate] DATE NULL DEFAULT NULL,
  [TotalPrice] FLOAT NULL DEFAULT NULL,
  [BOOKING _SOURCE_BookingTypeID] INT NOT NULL,
  [CUSTOMER_CustomerID] INT NOT NULL,
  PRIMARY KEY ([ReservationID]),
  FOREIGN KEY ([BOOKING _SOURCE_BookingTypeID])
  REFERENCES mydb.BOOKING_SOURCE ([BookingTypeID]),
  FOREIGN KEY ([CUSTOMER_CustomerID]) REFERENCES mydb.CUSTOMER([CustomerID]));
    

-- Create table for BOOKING_DETAILS

CREATE TABLE mydb.BOOKING_DETAILS (
  [BookingID] INT NOT NULL,
  [BookingStatus] VARCHAR(50) NULL DEFAULT NULL,
  [BookingTime] DATETIME2(0) NOT NULL,
  [CHECKIN_CheckinID] INT NOT NULL,
  [ROOM_BOOKING _ReservationID] INT NOT NULL,
  [CheckinDate] DATETIME2(0)  NULL,
  [CheckoutDate] DATETIME2(0)  NULL,
  PRIMARY KEY (BookingID),
    FOREIGN KEY ([CHECKIN_CheckinID]) REFERENCES mydb.CHECKIN ([CheckinID]),
    FOREIGN KEY ([ROOM_BOOKING _ReservationID]) REFERENCES mydb.ROOM_BOOKING ([ReservationID]));
  

-- Create table for PAYMENT

CREATE TABLE mydb.PAYMENT (
  [HotelPaymentID] INT NOT NULL ,
  [PaymentType] VARCHAR(50) NULL DEFAULT NULL,
  [PaymentAmount] FLOAT NULL DEFAULT NULL,
  [PaymentDate] DATETIME2(0) NULL DEFAULT NULL,
  [BOOKING_DETAILS_BookingID] INT NOT NULL,
  PRIMARY KEY ([HotelPaymentID]),
    FOREIGN KEY ([BOOKING_DETAILS_BookingID]) REFERENCES mydb.BOOKING_DETAILS ([BookingID]));
 

-- Create table for Location

CREATE TABLE mydb.LOCATION (
  [LocationID] INT NOT NULL ,
  [LocationName] VARCHAR(100) NULL DEFAULT NULL,
  [City] VARCHAR(100) NULL DEFAULT NULL,
  [State] VARCHAR(100) NULL DEFAULT NULL,
  [Country] VARCHAR(100) NULL DEFAULT NULL,
  [Zipcode] VARCHAR(100) NULL DEFAULT NULL,
  PRIMARY KEY ([LocationID]));


-- Create table for hotel

CREATE TABLE mydb.HOTEL (
  [HotelID] INT NOT NULL ,
  [HotelName] VARCHAR(100) NULL DEFAULT NULL,
  [LOCATION_LocationID] INT NOT NULL,
  PRIMARY KEY ([HotelID]),
    FOREIGN KEY ([LOCATION_LocationID]) REFERENCES mydb.LOCATION ([LocationID]));
  

-- create table for feedback
CREATE TABLE mydb.FEEDBACK (
  [FeedbackID] INT NOT NULL ,
  [FeedbackDescription] VARCHAR(500) NULL DEFAULT NULL,
  [HOTEL_HotelID] INT NOT NULL,
  [CUSTOMER_CustomerID] INT NOT NULL,
  PRIMARY KEY ([FeedbackID]),
    FOREIGN KEY ([HOTEL_HotelID]) REFERENCES mydb.HOTEL([HotelID]),
    FOREIGN KEY ([CUSTOMER_CustomerID]) REFERENCES mydb.CUSTOMER ([CustomerID]));
   

-- Create table for Restaurants

CREATE TABLE mydb.RESTAURANTS (
  [RestaurantID] INT NOT NULL ,
  [RestaurantName] VARCHAR(100) NULL DEFAULT NULL,
  [Cuisine] VARCHAR(50) NULL DEFAULT NULL,
  [HOTEL_HotelID] INT NOT NULL,
  PRIMARY KEY ([RestaurantID]),
    FOREIGN KEY ([HOTEL_HotelID]) REFERENCES mydb.HOTEL([HotelID]));
    
-- Create team RoomType

CREATE TABLE mydb.ROOMTYPE (
  [RoomTypeID] INT NOT NULL ,
  [RoomTypeDesc ] VARCHAR(50) NULL DEFAULT NULL,
  [NoOfBeds] INT NULL DEFAULT NULL,
  [StandardRate] FLOAT NULL DEFAULT NULL,
  PRIMARY KEY ([RoomTypeID]));


-- Create table for Hotel_room

CREATE TABLE mydb.HOTEL_ROOM (
  [RoomID] INT NOT NULL ,
  [IsAvailable] SMALLINT NULL DEFAULT NULL,
  [TotalPrice] FLOAT NULL DEFAULT NULL,
  [HOTEL_HotelID] INT NOT NULL,
  [ROOMTYPE_RoomTypeID] INT NOT NULL,
  [BOOKING_DETAILS_BookingID] INT NOT NULL,
  [ROOM_BOOKING _ReservationID1] INT NOT NULL,
  PRIMARY KEY ([RoomID]),
    FOREIGN KEY ([HOTEL_HotelID]) REFERENCES mydb.HOTEL ([HotelID]),
    FOREIGN KEY ([ROOMTYPE_RoomTypeID]) REFERENCES mydb.ROOMTYPE ([RoomTypeID]),
    FOREIGN KEY ([BOOKING_DETAILS_BookingID]) REFERENCES mydb.BOOKING_DETAILS ([BookingID]),
    FOREIGN KEY ([ROOM_BOOKING _ReservationID1]) REFERENCES mydb.ROOM_BOOKING  ([ReservationID]));
  

-- CREATE TABLE BOOKING_ROOM_DETAILS

CREATE TABLE mydb. BOOKING_ROOM_DETAILS (
  [ROOM_BOOKING _ReservationID] INT NOT NULL,
  [HOTEL_ROOM_RoomID] INT NOT NULL
  PRIMARY KEY ([HOTEL_ROOM_RoomID]),
    FOREIGN KEY ([ROOM_BOOKING _ReservationID]) REFERENCES mydb.ROOM_BOOKING ([ReservationID]),
    FOREIGN KEY ([HOTEL_ROOM_RoomID]) REFERENCES mydb.HOTEL_ROOM ([RoomID]));
 

-- Create table for nearby airport 
CREATE TABLE mydb.NEARBY_AIRPORT (
  [AirportID] INT NOT NULL ,
  [AirportName] VARCHAR(100) NULL DEFAULT NULL,
  [LOCATION_LocationID] INT NOT NULL,
  PRIMARY KEY ([AirportID]),
    FOREIGN KEY ([LOCATION_LocationID]) REFERENCES mydb.LOCATION ([LocationID]));


-- Create table for rating
CREATE TABLE mydb.RATING (
  [RatingID] INT NOT NULL ,
  [Rating] INT NULL DEFAULT NULL,
  [RatingDate] DATETIME2(0) NULL DEFAULT NULL,
  [CUSTOMER_CustomerID] INT NOT NULL,
  [HOTEL_HotelID] INT NOT NULL,
  PRIMARY KEY ([RatingID]),
    FOREIGN KEY ([CUSTOMER_CustomerID]) REFERENCES mydb.CUSTOMER ([CustomerID]),
    FOREIGN KEY ([HOTEL_HotelID]) REFERENCES mydb.HOTEL([HotelID]));
 


-- Create table for Reservation details

CREATE TABLE mydb.RESERVATION_DETAILS (
  [EndDate] DATE NOT NULL ,
  [ReservationStatus] VARCHAR(50) NULL DEFAULT NULL,
  [ROOM_BOOKING _ReservationID] INT NOT NULL
    FOREIGN KEY ([ROOM_BOOKING _ReservationID]) REFERENCES mydb.ROOM_BOOKING  ([ReservationID]));



-- Create table for amenity 
CREATE TABLE mydb.AMENITY (
  [AmenityID] INT NOT NULL ,
  [AmentiyName] VARCHAR(100) NULL DEFAULT NULL,
  [HOTEL_HotelID] INT NOT NULL,
  PRIMARY KEY ([AmenityID]),
    FOREIGN KEY ([HOTEL_HotelID]) REFERENCES mydb.HOTEL ([HotelID]));
  

-- Create script for ROOM_STATUS
CREATE TABLE mydb.ROOM_STATUS (
  [RoomStatusID] INT NOT NULL ,
  [RoomStatus] VARCHAR(50) NULL DEFAULT NULL,
  PRIMARY KEY ([RoomStatusID]));
 

-- Create table for refund

CREATE TABLE mydb.REFUND (
  [RefundDate] DATETIME2(0) NULL DEFAULT NULL,
  [RefundStatus] VARCHAR(100) NULL DEFAULT NULL,
  [PAYMENT_HotelPaymentID] INT NOT NULL,
    FOREIGN KEY ([PAYMENT_HotelPaymentID]) REFERENCES mydb.PAYMENT ([HotelPaymentID]));
 


----------------------------------------------------------------------------------------------------------------------------
---Insert Data Query----------------------------------------------


INSERT INTO mydb.ROOM_BOOKING(ReservationID ,NoOfGuests ,NoOfRooms,BookingStartDate,BookingEndDate,TotalPrice,[BOOKING _SOURCE_BookingTypeID], CUSTOMER_CustomerID)
VALUES
(16,6,2,'2021-05-09 12:00:00', '2021-05-10 23:00:00',21500,5,21),
(17,3,2,'2021-05-10 12:00:00', '2021-05-15 23:00:00',56130,4,14),
(18,5,2,'2021-05-13 12:00:00', '2021-05-15 23:00:00',154260,6,28),
(19,3,1,'2021-05-16 12:00:00', '2021-05-18 23:00:00',7850,7,25),
(20,3,2,'2021-05-17 12:00:00', '2021-05-23 23:00:00',5600,5,13),
(21,5,2,'2021-04-04 12:00:00', '2021-04-09 23:00:00',2700,7,18),
(22,4,2,'2021-04-01 12:00:00', '2021-04-06 23:00:00',2400,8,21),
(23,4,1,'2021-04-03 12:00:00', '2021-04-08 23:00:00',35600,1,16),
(24,4,3,'2021-04-02 12:00:00', '2021-04-09 23:00:00',8800,7,23), 
(25,4,4,'2021-04-07 12:00:00', '2021-04-10 23:00:00',3566,9,29),
(26,4,4,'2021-04-14 12:00:00', '2021-04-18 23:00:00',6000,3,10),
(27,7,3,'2021-04-28 12:00:00', '2020-04-30 23:00:00',2500,2,27),
(28,8,2,'2021-05-15 12:00:00', '2021-05-25 23:00:00',10000,1,12);

--------------------------------------------------------------------------------------------------

INSERT INTO mydb.PERSON (PersonID, FirstName, LastName, EmailID, BirthDate, PhoneNumber, Gender, LOCATION_LocationID)
 VALUES
	(1,'Micheal','Scott','micheal.scott@gmail.com','08-25-1996','7984453309','M',7),
	(2,'Dwight','Schrute','dwight.schrute@gmail.com','01-07-1993','7984453301','M',5),
	(3,'Jim','Halpert','jim.halpert@gmail.com','02-07-1990','7984453302','M',1),
	(4,'Pamela','Besley','pamela.besley@gmail@gmail.com','10-07-1992','7984453304','F',20),
	(5,'Andy','Bernard','any.bernard@gmail.com','11-09-1989','7984453306','M',13),
	(6,'Phyllis','Vance','phyllis.vance@gmail@gmail.com','05-04-1991','7981153304','F',17),
	(7,'Stanley','Hudson','stanley.hudson@gmail.com','01-25-1992','7985553304','M',4),
	(8,'Oscar','Martinez','oscar.martinez@gmail.com','08-01-1980','8985553304','M',10),
	(9,'Toby','Flenderson','toby.flenderson@gmail.com','12-27-19850','7984664532','M',11),
	(10,'Mindy','Kaling','mindy.kaling@gmail.com','01-21-1982','8375430341','F',15),
	(11,'Kelly','Biswas','kelly.biswas@gmail.com','08-07-1997','8375442034','M',20),
	(12,'Ryan','Howard','ryan.howard@gmail.com','01-25-1996','8275442034','M',19),
	(13,'Angela','Kinsey','angela.kinsey@gmail.com','03-25-1986','8575123456','F',11),
	(14,'Creed','Braton','creed.braton@gmail.com','03-03-1966','8125442034','M',4),
	(15,'Ellie','Kemper','Ellie.kemper@gmail.com','01-07-1986','8345442034','F',1),
	(16,'Darryl','Phylbin','darryl.phylbin@gmail.com','02-27-1993','8575444144','M',1),
	(17,'Karen','Filipelli','karen.filipelli@gmail.com','01-10-1996','8575444444','F',19),
	(18,'Holly','Flax','holly.flax@gmail.com','08-25-1996','8575442034','F',14),
	(19,'Cecilia','Halpert','cecilia.halpert@gmail.com','01-25-2000','8100442034','F',6),
	(20,'Erin','Hannon','erin.hannon@gmail.com','06-06-1986','8575442666','F',5),
	(21,'Rachel','Green','rachel.green@gmail.com','08-10-1996','7984453310','F',7),
	(22,'Monica','Geller','monica.geller@gmail.com','08-11-1991','7984453314','F',19),
	(23,'Phoebe','Buffay','phoebe.buffay@gmail.com','08-11-1991','7984423314','F',1),
	(24,'Joey','Tribbani','joey.tribbani@gmail.com','05-16-1993','7984423414','M',4),
	(25,'Chandler','Bing','chandler.bing@gmail.com','10-09-1995','7923673314','M',5),
	(26,'Tag','Jones','tag.jones@gmail.com','01-09-1998','7916953314','M',4),
	(27,'Ben','Geller','ben.galler@gmail.com','05-18-1990','7928463714','M',8),
	(28,'Clifford','Burnet','clifford.burnet@gmail.com','10-03-1995','7984452847','M',5),
	(29,'Bitsy','Hanningan','bitsy.hanningan@gmail.com','05-12-1994','7826453314','F',8),
	(30,'Andrea','Waltham','andrea.waltha@gmail.com','07-12-1990','7920053314','M',6);

--------------------------------------------------------------------------------------------------------------------

INSERT INTO mydb.AMENITY (AmenityID, AmentiyName, HOTEL_HotelID)
 VALUES
	(1,'24-hour Room Service',5),
	(2,'Currency Exchange',3),
	(3,'Laundry',6),
	(4,'Entertainment Room',7),
	(5,'Swimming Pool',7),
	(6,'Gym',4),
	(7,'Casino',8),
	(8,'Parking',10),
	(9,'Wi-Fi',2),
	(10,'Fitness Centre',1)

-------------------------------------------------------------------------------------------

INSERT INTO mydb.ROOMTYPE(RoomTypeID,[RoomTypeDesc ],NoofBeds,StandardRate)
VALUES
      (1, 'Standard Room',1,103),
      (2, 'Standard Twin Room',2,203),
      (3, 'Executive Room',1,103),
      (4, 'Club Room',3,1030),
	  (5, 'SuperClass Room',2,1103),
	  (6, 'Friends Room',3,1500),
	  (7, 'King Bed',1,100),
	  (8, 'Queen bed',1,130),
	  (9, 'Delux',1,1350),
	  (10, 'Super Delux',1,1560);

-----------------------------------------------------------------------------------------------

INSERT INTO mydb.CHECKIN(CheckinID , CheckinDate,CheckOutDate)
VALUES
(1,'2021-07-10 12:00:00', '2021-07-15 23:00:00'),
(2,'2021-06-08 12:00:00', '2021-06-28 23:00:00'),
(3,'2021-06-08 12:00:00', '2021-06-18 23:00:00'),
(4,'2021-06-08 12:00:00', '2021-06-10 23:00:00'),
(5,'2021-06-08 12:00:00', '2021-06-11 23:00:00'),
(6,'2021-06-08 12:00:00', '2021-06-13 23:00:00'),
(7,'2021-06-13 12:00:00', '2021-06-15 23:00:00'),
(8,'2021-07-11 12:00:00', '2021-07-13 23:00:00'),
(9,'2021-07-12 12:00:00', '2021-07-16 23:00:00'),
(10,'2021-07-12 12:00:00', '2021-07-16 23:00:00'), 
(11,'2021-07-15 12:00:00', '2021-07-17 23:00:00'),
(12,'2021-07-16 12:00:00', '2021-07-21 23:00:00'),
(13,'2021-07-17 12:00:00', '2021-09-07 23:00:00'),
(14,'2021-07-15 12:00:00', '2021-07-25 23:00:00'),
(15,'2021-07-16 12:00:00', '2021-07-18 23:00:00'),
(16,'2021-07-17 12:00:00', '2021-07-20 23:00:00'),
(17,'2021-07-15 12:00:00', '2021-07-17 23:00:00');

------------------------------------------

INSERT INTO mydb.ROOM_BOOKING(ReservationID ,NoOfGuests ,NoOfRooms,BookingStartDate,BookingEndDate,TotalPrice,[BOOKING _SOURCE_BookingTypeID], CUSTOMER_CustomerID)
VALUES
(1,2,1,'2021-07-10 12:00:00', '2021-07-15 23:00:00',1300,2,10),
(2,5,2,'2021-06-08 12:00:00', '2021-06-28 23:00:00',1500,4,5),
(3,2,1,'2021-06-08 12:00:00', '2021-06-18 23:00:00',130,3,4),
(4,4,2,'2021-06-08 12:00:00', '2021-06-10 23:00:00',260,5,2),
(5,2,1,'2021-06-08 12:00:00', '2021-06-11 23:00:00',1550,2,1),
(6,2,1,'2021-06-08 12:00:00', '2021-06-13 23:00:00',1300,4,3),
(7,4,2,'2021-06-13 12:00:00', '2021-06-15 23:00:00',2600,6,8),
(8,3,1,'2021-07-11 12:00:00', '2021-07-13 23:00:00',1500,7,7),
(9,3,1,'2021-07-12 12:00:00', '2021-07-16 23:00:00',1200,2,6),
(10,3,2,'2021-07-12 12:00:00', '2021-07-16 23:00:00',590,1,4), 
(11,3,1,'2021-07-15 12:00:00', '2021-07-17 23:00:00',460,5,9),
(12,3,1,'2021-07-16 12:00:00', '2021-07-21 23:00:00',540,6,10),
(13,3,2,'2021-07-17 12:00:00', '2020-09-07 23:00:00',760,5,13),
(14,4,2,'2021-07-15 12:00:00', '2021-07-25 23:00:00',670,4,12);

---------------------------------------

INSERT INTO mydb.ROOM_STATUS(RoomStatusID,RoomStatus)
VALUES
	(1,'Occupied'),
	(2,'Vaccant'),
	(3,'HouseKeeping'),
	(4,'Vaccant & Dirty'),
	(5,'unavailable');

----------------------------------

	INSERT INTO mydb.BOOKING_DETAILS(BookingID,BookingDate,[ROOM_BOOKING _ReservationID],CheckinDate,CheckoutDate)
VALUES
(1,'2021-07-01 12:00:00',1,'2021-07-10 12:00:00', '2021-07-15 23:00:00'),
(2,'2021-06-03 12:00:00',2,'2021-06-08 12:00:00', '2021-06-28 23:00:00'),
(3,'2021-06-02 12:00:00',3,'2021-06-08 12:00:00', '2021-06-18 23:00:00'),
(4,'2021-06-01 12:00:00',4,'2021-06-08 12:00:00', '2021-06-10 23:00:00'),
(5,'2021-06-06 12:00:00',5,'2021-06-08 12:00:00', '2021-06-11 23:00:00'),
(6,'2021-06-01 12:00:00',6,'2021-06-08 12:00:00', '2021-06-13 23:00:00'),
(7,'2021-06-01 12:00:00',7,'2021-06-13 12:00:00', '2021-06-15 23:00:00'),
(8,'2021-07-01 12:00:00',8,'2021-07-11 12:00:00', '2021-07-13 23:00:00'),
(9,'2021-07-02 12:00:00',9,'2021-07-12 12:00:00', '2021-07-16 23:00:00'),
(10,'2021-07-04 12:00:00',10,'2021-07-12 12:00:00','2021-07-16 23:00:00');

----------------------------------------

INSERT INTO mydb.HOTEL_ROOM(RoomID, HOTEL_HotelID,ROOMTYPE_RoomTypeID,BOOKING_DETAILS_BookingID,[ROOM_BOOKING _ReservationID],ROOM_STATUS_RoomStatusID)
VALUES
(1,2,2,1,1,2),
(2,3,2,2,2,2),
(3,1,3,3,5,1),
(4,1,4,2,3,2),
(5,4,5,4,4,2),
(6,5,6,5,8,2),
(7,6,7,6,6,1),
(8,3,8,7,9,2),
(9,7,9,8,12,2),
(10,8,1,9,10,3),
(11,9,2,10,11,2);

-----------------------------------------

INSERT INTO mydb.CHECKIN(CheckinID , CheckinDate,CheckOutDate)
VALUES
(1,'2021-07-10 12:00:00', '2021-07-15 23:00:00'),
(2,'2021-06-08 12:00:00', '2021-06-28 23:00:00'),
(3,'2021-06-08 12:00:00', '2021-06-18 23:00:00'),
(4,'2021-06-08 12:00:00', '2021-06-10 23:00:00'),
(5,'2021-06-08 12:00:00', '2021-06-11 23:00:00'),
(6,'2021-06-08 12:00:00', '2021-06-13 23:00:00'),
(7,'2021-06-13 12:00:00', '2021-06-15 23:00:00'),
(8,'2021-07-11 12:00:00', '2021-07-13 23:00:00'),
(9,'2021-07-12 12:00:00', '2021-07-16 23:00:00'),
(10,'2021-07-12 12:00:00', '2021-07-16 23:00:00'), 
(11,'2021-07-15 12:00:00', '2021-07-17 23:00:00'),
(12,'2021-07-16 12:00:00', '2021-07-21 23:00:00'),
(13,'2021-07-17 12:00:00', '2021-09-07 23:00:00'),
(14,'2021-07-15 12:00:00', '2021-07-25 23:00:00'),
(15,'2021-07-16 12:00:00', '2021-07-18 23:00:00'),
(16,'2021-07-17 12:00:00', '2021-07-20 23:00:00'),
(17,'2021-07-15 12:00:00', '2021-07-17 23:00:00');

---------------------------------------

INSERT INTO mydb.BOOKING_SOURCE(BookingTypeID,BookingType)
VALUES
      (1,'Hotels.com' ),
      (2,'Oyo'),
      (3,'Airbnb'),
      (4,'MakemyTrip'),
	  (5,'TripAdvisor'),
	  (6,'Booking.com'),
	  (7,'Trivago' ),
	  (8,'Cleartrip'),
	  (9,'Paytm' ),
	  (10,'Whotels');

---------------------------------------------

INSERT INTO mydb.PAYMENT(HotelPaymentID, PaymentType,PaymentAmount,[Payment Timestamp],BOOKING_DETAILS_BookingID)
VALUES
(1,'Card',1550,'2021-07-01 12:00:00',5),
(2,'Card',260,'2021-06-03 12:00:00',4),
(3,'Mobile Payment',130,'2021-06-02 12:00:00',3),
(4,'BankTrasfer',1500,'2021-06-01 12:00:00',2),
(5,'Card',1300,'2021-06-06 12:00:00',1),
(6,'Mobile Payment',1300,'2021-06-01 12:00:00',6),
(7,'Card',1500,'2021-06-01 12:00:00',8),
(8,'Card',2600,'2021-07-01 12:00:00',7),
(9,'Card',590,'2021-07-02 12:00:00',10),
(10,'Card',1200,'2021-07-04 12:00:00',9);

----------------------------------------------------

INSERT INTO mydb.RESTAURANTS(RestaurantID,RestaurantName,Cuisine,HOTEL_HotelID)
VALUES
	(1,'La Voile','French',3),
	(2,'Delhi Darbar','Indian',6),
	(3,'Mumbai Spice','Indian',7),
	(4,'Piattini','Italian',8),
	(5,'Eataly','Italian',9),
	(6,'Peka','American',8),
	(7,'Lincoln','American',9),
	(8,'Stillwater','Australian',3),
	(9,'Penang','Malaysian',2),
	(10,'New China','Chinese',2),
	(11,'Korean Kitchen','Korean',18),
	(12,'HAJU Kitchen','Korean',16),
	(13,'Douzo','Japaneese',20),
	(14,'Ped Thai','Thai',20),
	(15,'Bankok Pinto','Thai',10);


------------------------------------------------------------------

INSERT INTO mydb.HOTEL(HotelID, HotelName, LOCATION_LocationID)
VALUES
	(1,'Best Western Hotel',6),
	(2,'China Town Hotel',16),
	(3,'Elite Hotel',17),
	(4,'Cosmopolitan Hotel',18),
	(5,'Prestige Hotel',19),
	(6,'Hyatt',9),
	(7,'Four Seasons',9),
	(8,'Westin',3),
	(9,'Mandarin Oriental',1),
	(10,'The Peninsula',10),
	(11, 'Four Seasons',39),
	(12,'Primland',36),
	(13,'Hotel Indigo',17),
	(14,'Hilton',23),
	(15,'Candlewood',26),
	(16,'Hotel Vitale',20),
	(17,'Sapphires',20),
	(18,'The Breakers',40),
	(19,'Spring Brook',29),
	(20,'Etiquette',17);

-----------------------------------------------------------

INSERT INTO mydb.LOCATION(LocationID, City, Country, State, Country, zipcode)
VALUES 
	 (1,'Pheonix', 'AZ', 'USA', 03456),
	 (2,'Tucson', 'AZ', 'USA', 14567),
	 (3,'Los Angeles', 'CA','USA',98456),
	 (4,'San Jose', 'CA','USA',87345),
	 (5,'San Diego', 'CA','USA',35674),
	 (6,'Denver','CO','USA',46352),
	 (7,'Silverton', 'CO','USA',56921),
	 (8,'Bristol', 'CT','USA',85501),
	 (9,'New Heaven','CT','USA',45707),
	 (10,'Miami','FL','USA',04287),
	 (11,'Chicago','IL','USA',53801),
	 (12,'Cambridge','MA','USA',10573),
	 (13,'Boston','MA','USA',92574),
	 (14,'Minnealpolis','MN','USA',03152),
	 (15,'Las Vegas','NV','USA',23919),
	 (16,'Jersey City','NJ','USA',05939),
	 (17,'New York City','NY','USA',75614),
	 (18,'Newark','NJ','USA',92315),
	 (19,'Stony Brook','NY','USA',90423),
	 (20, 'San Francisco','CA','USA',38429);

---------------------------------------------

INSERT INTO mydb.NEARBY_AIRPORT (AirportID, AirportName, LOCATION_LocationID)
VALUES
	(1, 'Pheonix Sky Harbour International Airport',1),
	(2, 'Tucson International Airport',2),
	(3, 'Los Angeles International Airport',3),
	(4, 'Normal Y.Mineta San Jose International Airport',4),
	(5, 'San Diego International Airport', 5),
	(6, 'Denver International Airport',6),
	(7, 'Tweed New Haven International Airport',9),
	(8, 'Miami International Airport', 10),
	(9, 'Chicago Midway International Airport', 11),
	(10, 'Boston Logan International Airport', 13),
	(11, 'Saint Paul International Airport', 14),
	(12, 'McCarren International Airport', 15),
	(13, 'John F Kennedy International Airport', 17),
	(14, 'Newark Liberty International Airport', 18);
------------------------------------------------------------------------

INSERT INTO mydb.CUSTOMER (CustomerID,CardNumber,SecurityCode,NameOnCard,BankName,RoutingNumber,AccountNumber,PERSON_PersonId,AccountBalance)
VALUES
	
(1,1234567891011121,123	,'Micheal Scott'	,'Chase Bank'	,123456789	,124456	,1	,13000),
(2,1234567891011122,124	,'Dwight Schrute'	,'BOA',123456780,343546,2,5600),
(3,	1234467891011123,	335	,'Jim Halpert'	,'Santander Bank',	123456781	,135234,	3	,7300),
(4	,1234467891567123	,315	,'Pamela Besley',	'Chase Bank',	123156781,	556622,	4	,9945),
(5,	1234463674567123,	222	,'Andy Bernard','	Santander Bank',	121156781,	456234,	5,	6889),
(6	,1210003674567123,	212	,'Phyllis Vance',	'TD Bank',	121156782,	56567345	,6	,11000),
(7,	1210003674567111,	012,'	Stanley Hudson','	Citi Bank',	121096782	,848373	,7	,24583),
(8,	1210001938567111,	316,'	Oscar Martinez','	HSBC Bank',	126412782,	235765	,8,	5555),
(9,	1210001836567111,	397	,'Toby Flenderson','	Capital One',	126296782,	483273,	9,	5634),
(10,	1210111836567111,	237,'	Mindy Kaling','	UBS',	126291082	,272263,	10	,7776),
(11,	1210111836567121,	231,'	Kelly Kapoor','	Barclays',	126277082,	696384,	11,	1300),
(12,	1210146836567121,	241,'	Ryan Howard','	Texas Capital',	125477082,	293273,	12	,8675),
(13,	1210183296567121,	072,'	Angela Kinsey','	South State Bank',	125417082,	356456	,13,	19045),
(14,	1210183296537291,	772	,'Creed Braton','Discover Financial',	125412642,	294378	,14	,4890),
(15,	0000183296537291,	712	,'Creed Braton','	Chase Bank',	000412642	,293586,	14,	2234),
(16	,0350183296537291,	020	,'Ellie Kemper','BOA',	010412642,	289498	,15,	135),
(17,	1937181236537291,	123	,'Darry Phylibin',	'Santander Bank',	382946642,	284768	,16	,12000),
(18,	1909883296537291,	153	,'Karen Filepelli','	Citi Bank'	,382446642,	284727,	17	,14567),
(19,	1937256296537291,	923	,'Holly Flax','	Citi Bank',	381346642,	293485	,18,	789),
(20,1937253829461528,	103	,'Erin Hanon','	UBS',	380306642,	284584	,20	,3456),
(21,	1923684635879034,	109,'	Cecilia Halpert',	'Citi Bank',	234595678,	574256	,19,	4356),
(22,	1058753829461528,	159,'	Rachel Green','	BOA',	233456789,	453434,	21,	888),
(23,	1823183296537291,	329	,'Monica Geller','	Texas Capital',	948456789,	111234	,22	,24566),
(24,	1485781236537291,	279,'	Phoebe Buffay','	Santander Bank',	045456789,	243234,	23,	48484),
(25,	1372603674567123,	519	,'Joey Tribbani','	Citi Bank',	156756789,	245234,	24,	10000),
(26,	1934765296537291,	089,	'Chandler Bing','	UBS',	121256789	,597234,	25	,287877660),
(27	,1291084635879034	,439	,'Tag Jones	','TD Bank'	,563784789,	286234,	26,	38884),
(28	,0243467891567123,	019	,'Ben Geller'	,'Discover Financial',	126576789,	94234	,27	,2341),
(29	,1394763674567123	,249,	'Clifford Burnet',	'Chase Bank'	,903456789,	430234,	28,	9000),
(30	,1100139296537291,	349	,'Bitsy Hanningan',	'Chase Bank',	143456789	,455834	,29	,7600);

-----------------------------------------------------------------------------------------------------

INSERT INTO mydb.rating (RatingID, Rating, RatingDate, CUSTOMER_CustomerID, HOTEL_HotelID)
VALUES (1, 5, '2021-05-13', 5, 3),
(2, 3, '2021-05-13', 5, 3),
(3, 5, '2020-03-03', 1, 1),
(4, 4, '2019-01-24', 4, 1),
(5, 3, '2018-02-02', 2, 4),
(6, 4, '2021-06-12', 7, 5),
(7, 1, '2020-09-09', 3, 6),
(8, 2, '2020-05-19', 6, 3),
(9, 3, '2019-07-15', 4, 8),
(10, 4, '2021-05-14', 13, 17),
(11, 3, '2021-05-10', 14, 19),
(12, 2, '2020-04-02', 16, 9),
(13, 3, '2020-04-28', 18, 13),
(14, 4, '2019-03-17', 21, 18),
(15, 3, '2019-03-20', 23, 13),
(16, 1, '2021-02-03', 25, 19),
(17, 4, '2021-02-05', 28, 13),
(18, 3, '2020-06-27', 29, 12);

-------------------------------------------

INSERT INTO mydb.FEEDBACK(FeedbackID, FeedbackDescription, HOTEL_HotelID, CUSTOMER_CustomerID)
VALUES
      (1,'Awsome service',2, 10),
	  (2,'Good place', 3, 5),
	  (3,'Extraordinary place and tasty food', 1, 1),
	  (4,'Okay service', 1, 4),
	  (5,'Nice hotel and awsome service',4, 2),
	  (6,'Great service', 5,7),
	  (7, 'Not good service try other place', 6, 3),
	  (8, 'Long Waiting time', 3, 6),
      (9, 'Good for one visit', 8, 4),
	  (10, 'Very Great', 17, 13),
	  (11, 'Average Stay', 19, 14),
	  (12, 'Did not like the service', 9, 16),
	  (13, 'Lack of cleanliness', 13, 18),
	  (14, 'Great', 18, 21),
	  (15, 'Okay!', 13, 23),
	  (16, 'Disappointed', 19, 25),
	  (17, 'Above expectations', 13, 28),
	  (18, 'Nice, food was okay', 12, 29);


--------------------------------------------------------

 INSERT INTO mydb.BOOKING_ROOM_DETAILS([ROOM_BOOKING _ReservationID],	HOTEL_ROOM_RoomID)
VALUES(1,1),
	  (2,2),
	  (5,3),
	  (3,4),
	  (4,5),
	  (8,6),
	  (6,7),
	  (9,8),
	  (12,9),
	  (10,10),
	  (11,11);
	  
----------------------------------------------------------------------------------------------------





