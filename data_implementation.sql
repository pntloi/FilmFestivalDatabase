SHOW DATABASES;

CREATE DATABASE IF NOT EXISTS pham_22317009;
USE pham_22317009;

SHOW TABLES;

DROP TABLE IF EXISTS PersonNominated;
DROP TABLE IF EXISTS FilmNominated;
DROP TABLE IF EXISTS Produce;
DROP TABLE IF EXISTS Nomination;
DROP TABLE IF EXISTS AwardCategory;
DROP TABLE IF EXISTS YearlyCeremony;
DROP TABLE IF EXISTS Studio;
DROP TABLE IF EXISTS Film;
DROP TABLE IF EXISTS Person;
DROP TABLE IF EXISTS Festival;

-- Festival table
CREATE TABLE Festival (
    festivalID  VARCHAR(10) PRIMARY KEY NOT NULL,
    name    VARCHAR(80)  NOT NULL,
    country VARCHAR(80),
    organizer   VARCHAR(80)
);

-- YearlyCeremony table
CREATE TABLE YearlyCeremony (
    festivalID  VARCHAR(10) NOT NULL,
    ceremonyYear    INTEGER NOT NULL,
    startDate   DATE NOT NULL,
    endDate DATE NOT NULL,
    location    VARCHAR(80),
    numOfGuests INTEGER NOT NULL,
    PRIMARY KEY (festivalID, ceremonyYear),
    FOREIGN KEY (festivalID) REFERENCES Festival(festivalID)
);

-- Stored Procedure to insert into YearlyCeremony with constraints
DROP PROCEDURE IF EXISTS insYearlyCeremony;
DELIMITER //
CREATE PROCEDURE insYearlyCeremony(
    IN inp_festivalID   VARCHAR(10),
    IN inp_ceremonyYear INTEGER,
    IN inp_startDate    DATE,
    IN inp_endDate  DATE,
    IN inp_location VARCHAR(80),
    IN inp_numOfGuests  INTEGER
)
COMMENT 'Insert a YearlyCeremony row and check constraints'
BEGIN
    IF inp_numOfGuests IS NULL OR inp_numOfGuests < 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'numOfGuests must be >= 0';
    END IF;

    IF inp_startDate IS NULL OR inp_endDate IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'startDate/endDate cannot be NULL';
    END IF;

    IF inp_startDate > inp_endDate THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'startDate must be <= endDate';
    END IF;

    INSERT INTO YearlyCeremony(
        festivalID, ceremonyYear, startDate, endDate, location, numOfGuests
    ) VALUES (
        inp_festivalID, inp_ceremonyYear, inp_startDate, inp_endDate, inp_location, inp_numOfGuests
    );
END //
DELIMITER ;

-- Film table
CREATE TABLE Film (
    filmID  VARCHAR(10) PRIMARY KEY NOT NULL,
    title   VARCHAR(80) NOT NULL,
    year    INTEGER NOT NULL, 
    genre   VARCHAR(80),
    duration    INTEGER NOT NULL
);

-- Stored Procedure to insert into Film with constraints
DROP PROCEDURE IF EXISTS insFilm;
DELIMITER //
CREATE PROCEDURE insFilm(
    IN inp_filmID   VARCHAR(10),
    IN inp_title    VARCHAR(80),
    IN inp_year INTEGER,
    IN inp_genre    VARCHAR(80),
    IN inp_duration INTEGER
)
COMMENT 'Insert into Film with validation for year & duration'
BEGIN
    -- Validate year
    IF inp_year IS NULL OR inp_year < 1927 OR inp_year > YEAR(CURDATE()) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'year must be between 1927 and current year';
    END IF;

    -- Validate duration
    IF inp_duration IS NULL OR inp_duration <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'duration must be > 0 (in minutes)';
    END IF;

    INSERT INTO Film(filmID, title, year, genre, duration)
    VALUES (inp_filmID, inp_title, inp_year, inp_genre, inp_duration);
END //
DELIMITER ;

-- Person table
CREATE TABLE Person (
    personID    VARCHAR(10) PRIMARY KEY NOT NULL,
    name    VARCHAR(80) NOT NULL,
    birthday    DATE NOT NULL,
    birthPlace  VARCHAR(80),
    gender  VARCHAR(80),
    role    VARCHAR(80)
);

-- Stored Procedure to insert into Person with constraints
DROP PROCEDURE IF EXISTS insPerson;
DELIMITER //
CREATE PROCEDURE insPerson(
    IN inp_personID VARCHAR(10),
    IN inp_name VARCHAR(80),
    IN inp_birthday DATE,
    IN inp_birthPlace   VARCHAR(80),
    IN inp_gender   VARCHAR(80),
    IN inp_role VARCHAR(80)
)
COMMENT 'Insert into Person with validation: birthday <= CURDATE()'
BEGIN
    IF inp_birthday IS NULL OR inp_birthday > CURDATE() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'birthday must be <= CURDATE()';
    END IF;

    INSERT INTO Person(personID, name, birthday, birthPlace, gender, role)
    VALUES (inp_personID, inp_name, inp_birthday, inp_birthPlace, inp_gender, inp_role);
END //
DELIMITER ;

-- AwardCategory table
CREATE TABLE AwardCategory (
    categoryID  VARCHAR(10) PRIMARY KEY NOT NULL,
    categoryName    VARCHAR(80) NOT NULL,
    awardClass  VARCHAR(80),
    festivalID  VARCHAR(10) NOT NULL,
    FOREIGN KEY (festivalID) REFERENCES Festival(festivalID)
);

-- Nomination table
CREATE TABLE Nomination (
    nomID   VARCHAR(10) PRIMARY KEY NOT NULL,
    nominationDate  DATE,
    detail  TEXT,
    isWinner    BOOLEAN NOT NULL DEFAULT FALSE,
    festivalID  VARCHAR(10) NOT NULL,
    ceremonyYear    INTEGER     NOT NULL,
    categoryID     VARCHAR(10) NOT NULL,
    FOREIGN KEY (festivalID, ceremonyYear) REFERENCES YearlyCeremony(festivalID, ceremonyYear),
    FOREIGN KEY (categoryID) REFERENCES AwardCategory(categoryID)

);

-- Studio table
CREATE TABLE Studio (
    studioID    VARCHAR(10) PRIMARY KEY NOT NULL,
    studioName  VARCHAR(80) NOT NULL UNIQUE,
    country VARCHAR(80),
    foundedYear INTEGER NOT NULL,
    type    VARCHAR(80)
);

-- Stored Procedure to insert into Studio with constraints
DROP PROCEDURE IF EXISTS insStudio;
DELIMITER //
CREATE PROCEDURE insStudio(
    IN inp_studioID VARCHAR(10),
    IN inp_studioName   VARCHAR(80),
    IN inp_country  VARCHAR(80),
    IN inp_foundedYear  INT,
    IN inp_type VARCHAR(80)
)
COMMENT 'Insert into Studio with foundedYear <= YEAR(CURDATE())'
BEGIN
    IF inp_foundedYear IS NULL OR inp_foundedYear > YEAR(CURDATE()) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'foundedYear must be <= current year';
    END IF;

    INSERT INTO Studio(studioID, studioName, country, foundedYear, type)
    VALUES (inp_studioID, inp_studioName, inp_country, inp_foundedYear, inp_type);
END //
DELIMITER ;

-- PersonNominated table
CREATE TABLE PersonNominated (
    nomID   VARCHAR(10) NOT NULL,
    personID    VARCHAR(10) NOT NULL,
    personRole  VARCHAR(80),
    characterName   VARCHAR(80), 
    PRIMARY KEY (nomID, personID),
    FOREIGN KEY (nomID)   REFERENCES Nomination(nomID),
    FOREIGN KEY (personID) REFERENCES Person(personID)
);

-- FilmNominated table
CREATE TABLE FilmNominated (
    nomID   VARCHAR(10) NOT NULL,
    filmID  VARCHAR(10) NOT NULL,
    specialNote TEXT,
    PRIMARY KEY (nomID, filmID),
    FOREIGN KEY (nomID)  REFERENCES Nomination(nomID),
    FOREIGN KEY (filmID) REFERENCES Film(filmID)
);

-- Produce table
CREATE TABLE Produce (
    filmID   VARCHAR(10) NOT NULL,
    studioID VARCHAR(10) NOT NULL,
    cost     INTEGER, 
    PRIMARY KEY (filmID, studioID),
    FOREIGN KEY (filmID)   REFERENCES Film(filmID),
    FOREIGN KEY (studioID) REFERENCES Studio(studioID)
);

-- Stored Procedure to insert into Produce with constraints
DROP PROCEDURE IF EXISTS insProduce;
DELIMITER //
CREATE PROCEDURE insProduce(
    IN inp_filmID   VARCHAR(10),
    IN inp_studioID VARCHAR(10),
    IN inp_cost INT
)
COMMENT 'Insert into Produce with validation: cost > 0'
BEGIN
    IF inp_cost <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'cost must be > 0 (in dollars)';
    END IF;

    INSERT INTO Produce(filmID, studioID, cost)
    VALUES (inp_filmID, inp_studioID, inp_cost);
END //
DELIMITER ;



-- insert values for Festival
INSERT INTO Festival(festivalID, name, country, organizer) VALUES
('OSC', 'Academy Awards', 'USA', 'AMPAS'),
('BAF', 'BAFTA Film Awards', 'UK', 'BAFTA'),
('CAN', 'Festival de Cannes', 'France', 'Cannes Org'),
('VEN', 'Venice Film Festival', 'Italy', 'La Biennale di Venezia'),
('BER', 'Berlin International FF', 'Germany', 'Berlinale'),
('SAG', 'SAG Awards', 'USA', 'SAG-AFTRA'),
('SAN', 'San Sebastian Film Fest', 'Spain', 'SIFF'),
('BFA', 'BFI London Film Fest', 'UK', 'BFI'),
('HKO', 'Hong Kong Film Awards', 'Hong Kong', 'HKFA'),
('JPB', 'Japan Academy Prize', 'Japan', 'Nippon Academy');

-- insert values for YearlyCeremony using stored procedure
CALL insYearlyCeremony('OSC', 1929, '1929-05-16', '1929-05-16', 'Los Angeles', 270);
CALL insYearlyCeremony('OSC', 1994, '1994-03-21', '1994-03-21', 'Los Angeles', 3000);
CALL insYearlyCeremony('OSC', 2019, '2019-02-24', '2019-02-24', 'Los Angeles', 3200);
CALL insYearlyCeremony('OSC', 2023, '2023-03-12', '2023-03-12', 'Los Angeles', 3500);
CALL insYearlyCeremony('BAF', 2019, '2019-02-10', '2019-02-10', 'London', 2500);
CALL insYearlyCeremony('BAF', 2021, '2021-04-10', '2021-04-11', 'London', 2300);
CALL insYearlyCeremony('BAF', 2023, '2023-02-19', '2023-02-19', 'London', 2600);
CALL insYearlyCeremony('BAF', 2024, '2024-02-18', '2024-02-18', 'London', 2700);
CALL insYearlyCeremony('CAN', 2019, '2019-05-14', '2019-05-25', 'Cannes', 12000);
CALL insYearlyCeremony('CAN', 2021, '2021-07-06', '2021-07-17', 'Cannes', 11500);
CALL insYearlyCeremony('CAN', 2023, '2023-05-16', '2023-05-27', 'Cannes', 12500);
CALL insYearlyCeremony('CAN', 2024, '2024-05-14', '2024-05-25', 'Cannes', 12600);
CALL insYearlyCeremony('VEN', 2019, '2019-08-28', '2019-09-07', 'Venice', 8000);
CALL insYearlyCeremony('VEN', 2020, '2020-09-02', '2020-09-12', 'Venice', 6000);
CALL insYearlyCeremony('VEN', 2022, '2022-08-31', '2022-09-10', 'Venice', 8200);
CALL insYearlyCeremony('VEN', 2023, '2023-08-30', '2023-09-09', 'Venice', 8300);
CALL insYearlyCeremony('BER', 2019, '2019-02-07', '2019-02-17', 'Berlin', 7000);
CALL insYearlyCeremony('BER', 2020, '2020-02-20', '2020-03-01', 'Berlin', 7100);
CALL insYearlyCeremony('BER', 2022, '2022-02-10', '2022-02-20', 'Berlin', 6800);
CALL insYearlyCeremony('BER', 2023, '2023-02-16', '2023-02-26', 'Berlin', 7200);
CALL insYearlyCeremony('OSC', 2015, '2015-02-22','2015-02-22','Los Angeles', 3200);
CALL insYearlyCeremony('OSC', 2016, '2016-02-28','2016-02-28','Los Angeles', 3250);
CALL insYearlyCeremony('OSC', 2017, '2017-02-26','2017-02-26','Los Angeles', 3300);
CALL insYearlyCeremony('OSC', 2018, '2018-03-04','2018-03-04','Los Angeles', 3350);
CALL insYearlyCeremony('OSC', 2021, '2021-04-25','2021-04-25','Los Angeles', 3000);
CALL insYearlyCeremony('OSC', 2022, '2022-03-27','2022-03-27','Los Angeles', 3450);
CALL insYearlyCeremony('BAF', 2016, '2016-02-14','2016-02-14','London', 2200);
CALL insYearlyCeremony('BAF', 2017, '2017-02-12','2017-02-12','London', 2250);
CALL insYearlyCeremony('BAF', 2018, '2018-02-18','2018-02-18','London', 2400);
CALL insYearlyCeremony('BAF', 2022, '2022-03-13','2022-03-13','London', 2550);
CALL insYearlyCeremony('CAN', 2018, '2018-05-08','2018-05-19','Cannes', 11800);
CALL insYearlyCeremony('CAN', 2020, '2020-06-22','2020-06-27','Cannes', 8000);
CALL insYearlyCeremony('CAN', 2022, '2022-05-17','2022-05-28','Cannes', 12300);
CALL insYearlyCeremony('VEN', 2017, '2017-08-30','2017-09-09','Venice', 7900);
CALL insYearlyCeremony('VEN', 2018, '2018-08-29','2018-09-08','Venice', 8050);
CALL insYearlyCeremony('VEN', 2021, '2021-09-01','2021-09-11','Venice', 8100);
CALL insYearlyCeremony('BER', 2018, '2018-02-15','2018-02-25','Berlin', 6900);
CALL insYearlyCeremony('BER', 2021, '2021-03-01','2021-03-05','Berlin', 6400);
CALL insYearlyCeremony('SAG', 2019, '2019-01-27','2019-01-27','Los Angeles', 2000);
CALL insYearlyCeremony('SAG', 2020, '2020-01-19','2020-01-19','Los Angeles', 2100);
CALL insYearlyCeremony('SAG', 2021, '2021-04-04','2021-04-04','Los Angeles', 1800);
CALL insYearlyCeremony('SAG', 2022, '2022-02-27','2022-02-27','Santa Monica', 2200);
CALL insYearlyCeremony('SAG', 2023, '2023-02-26','2023-02-26','Los Angeles', 2300);
CALL insYearlyCeremony('SAG', 2024, '2024-02-24','2024-02-24','Los Angeles', 2350);
CALL insYearlyCeremony('SAN', 2019, '2019-09-20','2019-09-28','San Sebastián', 5000);
CALL insYearlyCeremony('SAN', 2020, '2020-09-18','2020-09-26','San Sebastián', 4500);
CALL insYearlyCeremony('SAN', 2021, '2021-09-17','2021-09-25','San Sebastián', 5200);
CALL insYearlyCeremony('SAN', 2022, '2022-09-16','2022-09-24','San Sebastián', 5400);
CALL insYearlyCeremony('SAN', 2023, '2023-09-22','2023-09-30','San Sebastián', 5500);
CALL insYearlyCeremony('SAN', 2024, '2024-09-20','2024-09-28','San Sebastián', 5550);
CALL insYearlyCeremony('BAF', 2025, '2025-02-16','2025-02-16','London', 2760);
CALL insYearlyCeremony('CAN', 2025, '2025-05-13','2025-05-24','Cannes', 12700);
CALL insYearlyCeremony('VEN', 2025, '2025-08-27','2025-09-06','Venice', 8400);
CALL insYearlyCeremony('BER', 2024, '2024-02-15','2024-02-25','Berlin', 7300);
CALL insYearlyCeremony('BER', 2025, '2025-02-14','2025-02-24','Berlin', 7350);
CALL insYearlyCeremony('OSC', 2024, '2024-03-10','2024-03-10','Los Angeles', 3400);
CALL insYearlyCeremony('OSC', 2020, '2020-02-09','2020-02-09','Los Angeles', 3200);
CALL insYearlyCeremony('BAF', 2020, '2020-02-02','2020-02-02','London', 2400);
CALL insYearlyCeremony('VEN', 2024, '2024-08-28', '2024-09-07', 'Venice', 8350);


-- insert values for Film table using stored procedure
CALL insFilm('tt0018455','Sunrise',1927,'Drama',95);
CALL insFilm('tt0018578','Wings',1927,'War/Drama',139);
CALL insFilm('tt0020629','All Quiet on the Western Front',1930,'War/Drama',152);
CALL insFilm('tt0062622','2001: A Space Odyssey',1968,'Sci-Fi',149);
CALL insFilm('tt0071562','The Godfather Part II',1974,'Crime/Drama',202);
CALL insFilm('tt0105236','Reservoir Dogs',1992,'Crime',99);
CALL insFilm('tt0110912','Pulp Fiction',1994,'Crime/Drama',154);
CALL insFilm('tt0114814','The Usual Suspects',1995,'Crime/Thriller',106);
CALL insFilm('tt0169547','American Beauty',1999,'Drama',122);
CALL insFilm('tt0468569','The Dark Knight',2008,'Action/Drama',152);
CALL insFilm('tt2582802','Whiplash',2014,'Drama',106);
CALL insFilm('tt2543164','Arrival',2016,'Sci-Fi/Drama',116);
CALL insFilm('tt6751668','Parasite',2019,'Thriller/Drama',132);
CALL insFilm('tt8579674','1917',2019,'War/Drama',119);
CALL insFilm('tt10618286','The French Dispatch',2021,'Comedy/Drama',108);
CALL insFilm('tt1160419','Dune',2021,'Sci-Fi',155);
CALL insFilm('tt6710474','Everything Everywhere All at Once',2022,'Comedy/Drama',139);
CALL insFilm('tt14230458','The Whale',2022,'Drama',117);
CALL insFilm('tt15398776','Oppenheimer',2023,'Biography/Drama',180);
CALL insFilm('tt15354916','Poor Things',2023,'Comedy/Drama',141);
CALL insFilm('tt90000001','Nomadland',2020,'Drama',108);
CALL insFilm('tt90000002','Sound of Metal',2019,'Drama/Music',120);
CALL insFilm('tt90000003','Minari',2020,'Drama',115);
CALL insFilm('tt90000004','The Father',2020,'Drama',97);
CALL insFilm('tt90000005','Promising Young Woman',2020,'Thriller/Drama',113);
CALL insFilm('tt90000006','Another Round',2020,'Comedy/Drama',117);
CALL insFilm('tt90000007','Tenet',2020,'Action/Sci-Fi',150);
CALL insFilm('tt90000008','Soul',2020,'Animation/Family',100);
CALL insFilm('tt90000009','The Power of the Dog',2021,'Drama/Western',126);
CALL insFilm('tt90000010','Licorice Pizza',2021,'Comedy/Drama',133);
CALL insFilm('tt90000011','CODA',2021,'Drama',112);
CALL insFilm('tt90000012','Belfast',2021,'Drama',98);
CALL insFilm('tt90000013','The Tragedy of Macbeth',2021,'Drama',105);
CALL insFilm('tt90000014','Triangle of Sadness',2022,'Comedy/Drama',147);
CALL insFilm('tt90000015','Aftersun',2022,'Drama',102);
CALL insFilm('tt90000016','Tár',2022,'Drama',158);
CALL insFilm('tt90000017','All of Us Strangers',2023,'Drama/Romance',105);
CALL insFilm('tt90000018','Saltburn',2023,'Thriller/Drama',131);
CALL insFilm('tt90000019','May December',2023,'Drama',117);
CALL insFilm('tt90000020','Society of the Snow',2023,'Drama',144);
CALL insFilm('tt90000021','Furiosa: A Mad Max Saga',2024,'Action/Adventure',148);
CALL insFilm('tt90000022','Civil War',2024,'Action/Drama',109);
CALL insFilm('tt90000023','Kinds of Kindness',2024,'Drama',164);
CALL insFilm('tt90000024','Hit Man',2024,'Comedy/Romance',115);
CALL insFilm('tt90000025','The Apprentice',2024,'Drama',120);
CALL insFilm('tt90000026','The Brutalist',2024,'Drama',165);
CALL insFilm('tt90000027','SNL: The Movie',2025,'Comedy',101);  
CALL insFilm('tt90000028','The Shōgun Returns',2025,'Historical/Drama',158);
CALL insFilm('tt90000029','The Peasants',2023,'Animation/Drama',114);
CALL insFilm('tt90000030','The Taste of Things',2023,'Romance/Drama',135);
CALL insFilm('tt7167630','The Zone of Interest',2023,'Drama/War',105);
CALL insFilm('tt22022452','The Substance',2024,'Drama/Horror',141);
CALL insFilm('tt6155172','Roma',2018,'Drama',135); 

-- insert values for Person table using stored procedure
CALL insPerson('nm0310980','Janet Gaynor','1906-10-06','Philadelphia, USA','Female','ACTRESS');
CALL insPerson('nm0417837','Emil Jannings','1884-07-23','Rorschach, Switzerland','Male','ACTOR');
CALL insPerson('nm0634240','Stanley Kubrick','1928-07-26','New York, USA','Male','DIRECTOR');
CALL insPerson('nm0000338','Al Pacino','1940-04-25','New York, USA','Male','ACTOR');
CALL insPerson('nm0000233','Robert De Niro','1943-08-17','New York, USA','Male','ACTOR');
CALL insPerson('nm0000237','Quentin Tarantino','1963-03-27','Knoxville, USA','Male','DIRECTOR');
CALL insPerson('nm0000235','Kevin Spacey','1959-07-26','South Orange, USA','Male','ACTOR');
CALL insPerson('nm0000229','Bryan Singer','1965-09-17','New York, USA','Male','DIRECTOR');
CALL insPerson('nm0000093','Sam Mendes','1965-08-01','Reading, UK','Male','DIRECTOR');
CALL insPerson('nm0000288','Christopher Nolan','1970-07-30','London, UK','Male','DIRECTOR');
CALL insPerson('nm1889973','Damien Chazelle','1985-01-19','Providence, USA','Male','DIRECTOR');
CALL insPerson('nm0821432','Denis Villeneuve','1967-10-03','Bécancour, Canada','Male','DIRECTOR');
CALL insPerson('nm0814280','Bong Joon-ho','1969-09-14','Daegu, South Korea','Male','DIRECTOR');
CALL insPerson('nm0000717','Sam Raimi','1959-10-23','Royal Oak, USA','Male','DIRECTOR');
CALL insPerson('nm0001401','Wes Anderson','1969-05-01','Houston, USA','Male','DIRECTOR');
CALL insPerson('nm0000108','Brendan Fraser','1968-12-03','Indianapolis, USA','Male','ACTOR');
CALL insPerson('nm8458660','Michelle Yeoh','1962-08-06','Ipoh, Malaysia','Female','ACTRESS');
CALL insPerson('nm0000399','Emma Stone','1988-11-06','Scottsdale, USA','Female','ACTRESS');
CALL insPerson('nm0634249','Cillian Murphy','1976-05-25','Cork, Ireland','Male','ACTOR');
CALL insPerson('nm0892273','Yorgos Lanthimos','1973-09-23','Athens, Greece','Male','DIRECTOR');
CALL insPerson('nmP00001','Chloé Zhao','1982-03-31','Beijing, China','Female','DIRECTOR');
CALL insPerson('nmP00002','Frances McDormand','1957-06-23','Chicago, USA','Female','ACTRESS');
CALL insPerson('nmP00003','Riz Ahmed','1982-12-01','London, UK','Male','ACTOR');
CALL insPerson('nmP00004','Anthony Hopkins','1937-12-31','Port Talbot, UK','Male','ACTOR');
CALL insPerson('nmP00005','Emerald Fennell','1985-10-01','London, UK','Female','DIRECTOR');
CALL insPerson('nmP00006','Thomas Vinterberg','1969-05-19','Copenhagen, Denmark','Male','DIRECTOR');
CALL insPerson('nmP00007','Jane Campion','1954-04-30','Wellington, New Zealand','Female','DIRECTOR');
CALL insPerson('nmP00008','Benedict Cumberbatch','1976-07-19','London, UK','Male','ACTOR');
CALL insPerson('nmP00009','Kenneth Branagh','1960-12-10','Belfast, UK','Male','DIRECTOR');
CALL insPerson('nmP00010','Sian Heder','1977-06-23','Cambridge, USA','Female','DIRECTOR');
CALL insPerson('nmP00011','Olivia Colman','1974-01-30','Norwich, UK','Female','ACTRESS');
CALL insPerson('nmP00012','Cate Blanchett','1969-05-14','Melbourne, Australia','Female','ACTRESS');
CALL insPerson('nmP00013','Paul Thomas Anderson','1970-06-26','Los Angeles, USA','Male','DIRECTOR');
CALL insPerson('nmP00014','Ruben Östlund','1974-04-13','Styrsö, Sweden','Male','DIRECTOR');
CALL insPerson('nmP00015','Charlotte Wells','1987-06-13','Edinburgh, UK','Female','DIRECTOR');
CALL insPerson('nmP00016','Andrew Haigh','1973-03-07','Harrogate, UK','Male','DIRECTOR');
CALL insPerson('nmP00017','Todd Haynes','1961-01-02','Los Angeles, USA','Male','DIRECTOR');
CALL insPerson('nmP00018','J.A. Bayona','1975-05-09','Barcelona, Spain','Male','DIRECTOR');
CALL insPerson('nmP00019','George Miller','1945-03-03','Brisbane, Australia','Male','DIRECTOR');
CALL insPerson('nmP00020','Alex Garland','1970-05-26','London, UK','Male','DIRECTOR');
CALL insPerson('nmP00021','Yorgos Lanthimos','1973-09-23','Athens, Greece','Male','DIRECTOR');
CALL insPerson('nmP00022','Glen Powell','1988-10-21','Austin, USA','Male','ACTOR');
CALL insPerson('nmP00023','Sebastian Stan','1982-08-13','Constanța, Romania','Male','ACTOR');
CALL insPerson('nmP00024','Brady Corbet','1988-08-17','Scottsdale, USA','Male','DIRECTOR');
CALL insPerson('nmP00025','Scarlett Johansson','1984-11-22','New York, USA','Female','ACTRESS');
CALL insPerson('nmP00026','Ke Huy Quan','1971-08-20','Saigon, Vietnam','Male','ACTOR');
CALL insPerson('nmP00027','Carey Mulligan','1985-05-28','London, UK','Female','ACTRESS');
CALL insPerson('nmP00028','Greta Lee','1983-03-07','Los Angeles, USA','Female','ACTRESS');
CALL insPerson('nmP00029','Cillian Murphy','1976-05-25','Cork, Ireland','Male','ACTOR');  
CALL insPerson('nmP00030','Sandra Hüller','1978-04-30','Suhl, Germany','Female','ACTRESS');
CALL insPerson('nm20250007','Jonathan Glazer','1965-03-26','London, UK','Male','DIRECTOR');
CALL insPerson('nm20250008','Coralie Fargeat','1974-04-19','Paris, France','Female','DIRECTOR');

-- insert values for AwardCategory table
INSERT INTO AwardCategory(categoryID, categoryName, awardClass, festivalID) VALUES
('OC01','BEST PICTURE','Title','OSC'),
('OC02','DIRECTING','Directing','OSC'),
('OC03','ACTOR','Acting','OSC'),
('OC04','ACTRESS','Acting','OSC'),
('BF01','BEST FILM','Title','BAF'),
('BF02','DIRECTOR','Directing','BAF'),
('BF03','LEADING ACTOR','Acting','BAF'),
('BF04','LEADING ACTRESS','Acting','BAF'),
('CA01','PALME DOR','Title','CAN'),
('CA02','GRAND PRIX','Title','CAN'),
('CA03','BEST DIRECTOR','Directing','CAN'),
('CA04','BEST ACTOR','Acting','CAN'),
('VE01','GOLDEN LION','Title','VEN'),
('VE02','SILVER LION','Title','VEN'),
('VE03','BEST DIRECTOR','Directing','VEN'),
('VE04','COPPA VOLPI (ACTOR)','Acting','VEN'),
('BR01','GOLDEN BEAR','Title','BER'),
('BR02','SILVER BEAR (JURY PRIZE)','Title','BER'),
('BR03','SILVER BEAR (DIRECTOR)','Directing','BER'),
('BR04','SILVER BEAR (LEAD)','Acting','BER'),
('OC06','ORIGINAL SCREENPLAY','Writing','OSC'),
('OC07','ADAPTED SCREENPLAY','Writing','OSC'),
('OC08','CINEMATOGRAPHY','Production','OSC'),
('OC09','FILM EDITING','Production','OSC'),
('OC10','ORIGINAL SCORE','Music','OSC'),
('OC11','INTERNATIONAL FEATURE','Title','OSC'),
('BF06','ORIGINAL SCREENPLAY','Writing','BAF'),
('BF07','ADAPTED SCREENPLAY','Writing','BAF'),
('BF08','CINEMATOGRAPHY','Production','BAF'),
('BF09','EDITING','Production','BAF'),
('BF10','ORIGINAL SCORE','Music','BAF'),
('BF11','FILM NOT IN ENGLISH','Title','BAF'),
('CA06','BEST SCREENPLAY','Writing','CAN'),
('CA07','BEST ACTRESS','Acting','CAN'),
('CA08','BEST ACTOR','Acting','CAN'),
('CA09','CINEMATOGRAPHY PRIZE','Production','CAN'),
('CA10','SHORT FILM PALME','Shorts','CAN'),
('CA11','UN CERTAIN REGARD (FILM)','Title','CAN'),
('VE06','SPECIAL JURY PRIZE','Title','VEN'),
('VE07','BEST SCREENPLAY','Writing','VEN'),
('VE08','BEST ACTRESS','Acting','VEN'),
('VE09','BEST ACTOR','Acting','VEN'),
('VE10','CINEMATOGRAPHY','Production','VEN'),
('VE11','ORIZZONTI (DIRECTOR)','Directing','VEN'),
('BR06','BEST SCREENPLAY','Writing','BER'),
('BR07','BEST ACTRESS','Acting','BER'),
('BR08','BEST ACTOR','Acting','BER'),
('BR09','OUTSTANDING ARTISTIC CONTRIBUTION','Production','BER'),
('BR10','DOCUMENTARY AWARD','Documentary','BER'),
('BR11','BEST FIRST FEATURE','Title','BER');


-- insert values for Nomination table
INSERT INTO Nomination(nomID, nominationDate, detail, isWinner, festivalID, ceremonyYear, categoryID) VALUES
('an1001','1929-05-16','Best Actress for Sunrise', TRUE,  'OSC', 1929, 'OC04'), 
('an1002','1994-03-21','Best Director nominee', FALSE, 'OSC', 1994, 'OC02'),
('an1003','2019-02-24','Best Picture nominee', FALSE, 'OSC', 2019, 'OC01'),
('an1004','2023-03-12','Best Actor winner', TRUE,  'OSC', 2023, 'OC03'),
('an1011','2019-02-10','Best Film winner', TRUE,  'BAF', 2019, 'BF01'),
('an1012','2021-04-10','Best Director nominee', FALSE, 'BAF', 2021, 'BF02'),
('an1013','2023-02-19','Leading Actress winner', TRUE,  'BAF', 2023, 'BF04'),
('an1014','2024-02-18','Leading Actor nominee', FALSE, 'BAF', 2024, 'BF03'),
('an1021','2019-05-25','Palme dOr nominee', FALSE, 'CAN', 2019, 'CA01'),
('an1022','2021-07-17','Best Director winner', TRUE,  'CAN', 2021, 'CA03'),
('an1023','2023-05-27','Grand Prix nominee', FALSE, 'CAN', 2023, 'CA02'),
('an1024','2024-05-25','Best Actor winner', TRUE,  'CAN', 2024, 'CA04'),
('an1031','2019-09-07','Golden Lion nominee', FALSE, 'VEN', 2019, 'VE01'),
('an1032','2020-09-12','Silver Lion winner', TRUE,  'VEN', 2020, 'VE02'),
('an1033','2022-09-10','Best Director nominee', FALSE, 'VEN', 2022, 'VE03'),
('an1034','2023-09-09','Coppa Volpi (Actor) winner', TRUE,  'VEN', 2023, 'VE04'),
('an1041','2019-02-17','Golden Bear nominee', FALSE, 'BER', 2019, 'BR01'),
('an1042','2020-03-01','Silver Bear (Jury) winner', TRUE,  'BER', 2020, 'BR02'),
('an1043','2022-02-20','Silver Bear (Director) nom', FALSE, 'BER', 2022, 'BR03'),
('an1044','2023-02-26','Silver Bear (Lead) winner', TRUE,  'BER', 2023, 'BR04'),
('an3001','2021-04-25','Best Picture nominee: Nomadland', TRUE,'OSC',2021,'OC01'),
('an3002','2021-04-25','Best Director: Chloé Zhao', TRUE,'OSC',2021,'OC02'),
('an3003','2021-04-25','Best Actor nominee: Riz Ahmed', FALSE,'OSC',2021,'OC03'),
('an3004','2021-04-25','Best Actress: Frances McDormand', TRUE,'OSC',2021,'OC04'),
('an3005','2022-03-27','Cinematography nominee: The Tragedy of Macbeth', FALSE,'OSC',2022,'OC08'),
('an3006','2022-03-27','Best Picture nominee: CODA', TRUE,'OSC',2022,'OC01'),
('an3007','2024-03-10','Original Score nominee: Oppenheimer', TRUE,'OSC',2024,'OC10'),
('an3008','2018-02-18','Best Film nominee: Three Billboards (ref year set)', FALSE,'BAF',2018,'BF01'),
('an3009','2022-03-13','Original Screenplay nominee: Licorice Pizza', FALSE,'BAF',2022,'BF06'),
('an3010','2025-02-16','Film Not in English nominee: The Zone of Interest', TRUE,'BAF',2025,'BF11'),
('an3011','2020-02-02','Leading Actress winner: Renée Zellweger (example slot)', TRUE,'BAF',2020,'BF04'),
('an3012','2016-02-14','Cinematography nominee: The Revenant (slot)', TRUE,'BAF',2016,'BF08'),
('an3013','2018-05-19','Palme dOr nominee: Shoplifters', TRUE,'CAN',2018,'CA01'),
('an3014','2022-05-28','Best Screenplay: Triangle of Sadness', TRUE,'CAN',2022,'CA06'),
('an3015','2024-05-25','Best Actress: The Substance', TRUE,'CAN',2024,'CA07'),
('an3016','2025-05-24','Un Certain Regard Film: (example) The Apprentice', FALSE,'CAN',2025,'CA11'),
('an3018','2021-09-11','Best Actress winner: (slot)', TRUE,'VEN',2021,'VE08'),
('an3019','2024-09-07','Best Screenplay nominee: Kinds of Kindness', FALSE,'VEN',2024,'VE07'),
('an3020','2017-09-09','Special Jury Prize nominee', FALSE,'VEN',2017,'VE06'),
('an3021','2025-09-06','Horizons Director nominee', FALSE,'VEN',2025,'VE11'),
('an3022','2018-02-25','Golden Bear nominee', FALSE,'BER',2018,'BR01'),
('an3023','2021-03-05','Best Actor nominee', FALSE,'BER',2021,'BR08'),
('an3024','2024-02-25','Best Screenplay nominee: The Zone of Interest', TRUE,'BER',2024,'BR06'),
('an3025','2025-02-23','Best First Feature nominee', FALSE,'BER',2025,'BR11'),
('an3026','2023-02-26','Documentary Award nominee', FALSE,'BER',2023,'BR10'),
('an3027','2023-02-19','Adapted Screenplay nominee: All Quiet on the Western Front (BAFTA)', TRUE,'BAF',2023,'BF07'),
('an3028','2024-03-10','International Feature nominee: The Zone of Interest', TRUE,'OSC',2024,'OC11'),
('an3029','2022-03-27','Original Screenplay nominee: Belfast', FALSE,'OSC',2022,'OC06'),
('an3030','2020-02-09','Original Screenplay nominee: Parasite', TRUE,'OSC',2020,'OC06');


-- insert values for Studio table using stored procedure
CALL insStudio('co0028775','Fox Film Corporation','USA',1915,'Studio');
CALL insStudio('co0023400','Paramount Famous Lasky','USA',1916,'Studio');
CALL insStudio('co0007143','Metro-Goldwyn-Mayer','USA',1924,'Studio');
CALL insStudio('co0005073','Universal Pictures','USA',1912,'Studio');
CALL insStudio('co0080422','Warner Bros.','USA',1923,'Studio');
CALL insStudio('co0073404','Cosmopolitan Productions','USA',1918,'Studio');
CALL insStudio('co0032190','RKO Radio Pictures','USA',1928,'Studio');
CALL insStudio('co0050868','Columbia Pictures','USA',1924,'Studio');
CALL insStudio('co0017902','United Artists','USA',1919,'Studio');
CALL insStudio('co0056699','Samuel Goldwyn Prod.','USA',1923,'Studio');
CALL insStudio('co0041234','United States Pictures','USA',1945,'Studio');
CALL insStudio('co0099999','20th Century Fox','USA',1935,'Studio');
CALL insStudio('co0012345','Selznick Int. Pictures','USA',1935,'Studio');
CALL insStudio('co0077777','Hal Roach Studios','USA',1914,'Studio');
CALL insStudio('co0033333','Monogram Pictures','USA',1931,'Studio');
CALL insStudio('co0044444','Republic Pictures','USA',1935,'Studio');
CALL insStudio('co0066666','Pathé Exchange','USA',1914,'Studio');
CALL insStudio('co0022222','First National Pictures','USA',1917,'Studio');
CALL insStudio('co0088888','Gaumont','France',1895,'Studio');
CALL insStudio('co0001111','Ealing Studios','UK',1902,'Studio');
CALL insStudio('coA2400002','A24 Intl.','USA',2012,'Indie Studio');
CALL insStudio('coA2400003','A24 Europe','UK',2019,'Indie Studio');
CALL insStudio('coNEON0002','NEON Europe','USA',2019,'Indie Studio');
CALL insStudio('coFOCUS002','Focus UK','UK',2005,'Studio');
CALL insStudio('coNETFLX01','Netflix Film','USA',2007,'Studio');
CALL insStudio('coAMZN0001','Amazon MGM','USA',2010,'Studio');
CALL insStudio('coANNAP001','Annapurna','USA',2011,'Indie Studio');
CALL insStudio('coPLANB001','Plan B','USA',2001,'Production');
CALL insStudio('coAPPLE001','Apple Original Films','USA',2019,'Studio');
CALL insStudio('coUNIUK001','Universal UK','UK',1930,'Studio');
CALL insStudio('coWBROS002','Warner Alt','USA',1923,'Studio');
CALL insStudio('coSONY0002','Sony Pictures Classics','USA',1992,'Studio');
CALL insStudio('coSEARCH02','Searchlight Int.','USA',1994,'Studio');
CALL insStudio('coHBO00001','HBO Films','USA',1983,'Studio');
CALL insStudio('coBBCF001','BBC Films','UK',1990,'Studio');
CALL insStudio('coLIONS001','Lionsgate','USA',1997,'Studio');
CALL insStudio('coMUBI0001','MUBI','UK',2007,'Studio');
CALL insStudio('coPATHE001','Pathé','France',1896,'Studio');
CALL insStudio('coSTUDIOC1','StudioCanal','France',1988,'Studio');
CALL insStudio('coTOHO0002','Toho Int.','Japan',1932,'Studio');
CALL insStudio('coGKIDS002','GKIDS Europe','USA',2015,'Animation');
CALL insStudio('coCJENM001','CJ ENM','South Korea',1995,'Studio');
CALL insStudio('coBONA0001','Bona Film Group','China',1999,'Studio');
CALL insStudio('coWILDS001','Wildside','Italy',2009,'Studio');
CALL insStudio('coFREM001','Fremantle','UK',2001,'Studio');
CALL insStudio('coATT00222','Attitude Films','USA',2018,'Indie');
CALL insStudio('coSPHERE01','Sphere Films','Canada',2014,'Studio');
CALL insStudio('coMK2PAR01','mk2','France',1974,'Studio');
CALL insStudio('coALT00001','Altitude Film','UK',2011,'Studio');
CALL insStudio('coBEND0001','BenderSpink','USA',1998,'Production');

-- insert values for PersonNominated
INSERT INTO PersonNominated(nomID, personID, personRole, characterName) VALUES
('an1001','nm0310980','ACTRESS','The Wife'),
('an1002','nm0000237','DIRECTOR','N/A (Director)'),
('an1003','nm0814280','DIRECTOR','N/A (Director)'),
('an1004','nm0634249','ACTOR','J. Donovan'),
('an1011','nm0000093','DIRECTOR','N/A (Director)'),
('an1012','nm0821432','DIRECTOR','N/A (Director)'),
('an1013','nm8458660','ACTRESS','Evelyn Quan'),
('an1014','nm0634249','ACTOR','Patrick OShea'),
('an1021','nm0001401','DIRECTOR','N/A (Director)'),
('an1022','nm0001401','DIRECTOR','N/A (Director)'),
('an1023','nm0000288','DIRECTOR','N/A (Director)'),
('an1024','nm0000108','ACTOR','Charlie Blake'),
('an1031','nm0821432','DIRECTOR','N/A (Director)'),
('an1032','nm0821432','DIRECTOR','N/A (Director)'),
('an1033','nm0892273','DIRECTOR','N/A (Director)'),
('an1034','nm0634249','ACTOR','Cormac Doyle'),
('an1041','nm0000288','DIRECTOR','N/A (Director)'),
('an1042','nm1889973','DIRECTOR','N/A (Director)'),
('an1043','nm0634240','DIRECTOR','N/A (Director)'),
('an1044','nm0000399','ACTRESS','Bella Baxter'),
('an3002','nmP00001','DIRECTOR','N/A (Director)'),
('an3003','nmP00003','ACTOR','Ruben'),
('an3004','nmP00002','ACTRESS','Fern'),
('an3005','nmP00013','DIRECTOR','N/A (Director)'),
('an3006','nmP00010','DIRECTOR','N/A (Director)'),
('an3007','nm0000288','DIRECTOR','N/A (Director)'),
('an3009','nmP00013','DIRECTOR','N/A (Director)'),
('an3010','nm20250007','DIRECTOR','N/A (Director)'),
('an3011','nm0000399','ACTRESS','Judy Garland'),  
('an3012','nm0000338','ACTOR','Hugh Glass'),
('an3013','nm0814280','DIRECTOR','N/A (Director)'),
('an3014','nmP00014','DIRECTOR','N/A (Director)'),
('an3015','nm20250008','DIRECTOR','N/A (Director)'),
('an3016','nmP00024','DIRECTOR','N/A (Director)'),
('an3018','nmP00012','ACTRESS','Leda'),                
('an3019','nmP00021','DIRECTOR','N/A (Director)'),
('an3020','nmP00024','DIRECTOR','N/A (Director)'),
('an3021','nmP00021','DIRECTOR','N/A (Director)'),    
('an3023','nmP00008','ACTOR','Berlin Role'),
('an3024','nmP00007','DIRECTOR','N/A (Director)'),
('an3025','nmP00015','DIRECTOR','N/A (Director)'),
('an3026','nmP00018','DIRECTOR','N/A (Director)'),
('an3027','nm0821432','DIRECTOR','N/A (Director)'),
('an3028','nm20250007','DIRECTOR','N/A (Director)'),
('an3029','nmP00009','DIRECTOR','N/A (Director)'),
('an3030','nm0814280','DIRECTOR','N/A (Director)'),
('an3001','nmP00001','DIRECTOR','N/A (Director)'),
('an3008','nmP00011','ACTRESS','Mildred Hayes');

-- insert values for FilmNominated
INSERT INTO FilmNominated(nomID, filmID, specialNote) VALUES
('an1001','tt0018455','Lead performance'),
('an1002','tt0110912','Director nod'),
('an1003','tt6751668','Picture slot'),
('an1004','tt15398776','Lead actor win'),
('an1011','tt8579674','BAFTA Best Film'),
('an1012','tt0468569','Director nom'),
('an1013','tt6710474','Leading actress win'),
('an1014','tt15398776','Leading actor nom'),
('an1021','tt10618286','Palme nominee'),
('an1022','tt10618286','Director win'),
('an1023','tt15354916','Grand Prix nom'),
('an1024','tt2543164','Actor win'),
('an1031','tt1160419','Golden Lion nom'),
('an1032','tt2543164','Silver Lion win'),
('an1033','tt14230458','Director nom'),
('an1034','tt15398776','Coppa Volpi win'),
('an1041','tt0468569','Golden Bear nom'),
('an1042','tt2582802','Silver Bear (Jury) win'),
('an1044','tt0114814','Silver Bear (Lead) win'),
('an3001','tt90000001','Best Picture winner (Oscars 2021)'),
('an3002','tt90000001','Director win'),
('an3003','tt90000002','Actor nomination'),
('an3004','tt90000001','Actress win'),
('an3005','tt90000013','Cinematography nom'),
('an3006','tt90000011','Best Picture winner'),
('an3007','tt15398776','Original Score win'),
('an3008','tt0169547','BAFTA Best Film slate'),
('an3009','tt90000010','Original Screenplay BAFTA nom'),
('an3010','tt7167630','Best Film not in English (win)'),
('an3011','tt8579674','Leading Actress BAFTA win'),
('an3012','tt0468569','BAFTA Cinematography win'),
('an3013','tt6751668','Palme slate'),
('an3014','tt90000014','Best Screenplay (Cannes)'),
('an3015','tt22022452','Best Actress (Cannes)'),
('an3016','tt90000025','Un Certain Regard selection'),
('an3018','tt90000030','Best Actress winner (slot)'),
('an3019','tt90000023','Screenplay nominee (Venice)'),
('an3020','tt90000026','Special Jury Prize slate'),
('an3021','tt90000023','Horizons Director slate'),
('an3022','tt2543164','Golden Bear competition'),
('an3023','tt90000008','Best Actor slate'),
('an3024','tt7167630','Best Screenplay (Berlinale)'),
('an3025','tt90000015','Best First Feature nominee'),
('an3026','tt2582802','Documentary Award slate'),
('an3027','tt0020629','BAFTA Adapted Screenplay win'),
('an3028','tt7167630','International Feature (Oscars)'),
('an3029','tt90000012','Original Screenplay nominee'),
('an3030','tt6751668','Original Screenplay win (Oscars 2020)');


-- insert values for Produce table using stored procedure
CALL insProduce('tt0018455','co0028775', 200000);
CALL insProduce('tt0018578','co0023400', 2200000);
CALL insProduce('tt0020629','co0005073', 1200000);
CALL insProduce('tt0062622','co0023400', 11000000);
CALL insProduce('tt0071562','co0017902', 13000000);
CALL insProduce('tt0105236','co0050868', 1200000);
CALL insProduce('tt0110912','co0032190', 8000000);
CALL insProduce('tt0114814','co0050868', 6000000);
CALL insProduce('tt0169547','co0012345', 15000000);
CALL insProduce('tt0468569','co0005073', 185000000);
CALL insProduce('tt2582802','co0056699', 3300000);
CALL insProduce('tt2543164','co0005073', 47000000);
CALL insProduce('tt6751668','co0088888', 11400000);
CALL insProduce('tt8579674','co0007143', 95000000);
CALL insProduce('tt10618286','co0007143', 25000000);
CALL insProduce('tt1160419','co0005073', 165000000);
CALL insProduce('tt6710474','co0007143', 25000000);
CALL insProduce('tt14230458','co0005073', 30000000);
CALL insProduce('tt15398776','co0007143', 100000000);
CALL insProduce('tt15354916','co0001111', 35000000);
CALL insProduce('tt90000001','coSEARCH02', 5000000);
CALL insProduce('tt90000002','coA2400002', 7000000);
CALL insProduce('tt90000003','coA2400003', 2000000);
CALL insProduce('tt90000004','coAMZN0001', 2500000);
CALL insProduce('tt90000005','coFOCUS002', 6000000);
CALL insProduce('tt90000006','coNEON0002', 4500000);
CALL insProduce('tt90000007','coWBROS002', 200000000);
CALL insProduce('tt90000008','coSONY0002', 120000000);
CALL insProduce('tt90000009','coNETFLX01', 30000000);
CALL insProduce('tt90000010','coANNAP001', 40000000);
CALL insProduce('tt90000011','coAPPLE001', 10000000);
CALL insProduce('tt90000012','coUNIUK001', 12000000);
CALL insProduce('tt90000013','coA2400002', 15000000);
CALL insProduce('tt90000014','coNEON0002', 15000000);
CALL insProduce('tt90000015','coMUBI0001', 5000000);
CALL insProduce('tt90000016','coLIONS001', 35000000);
CALL insProduce('tt90000017','coSEARCH02', 12000000);
CALL insProduce('tt90000018','coAMZN0001', 25000000);
CALL insProduce('tt90000019','coNETFLX01', 25000000);
CALL insProduce('tt90000020','coSPHERE01', 35000000);
CALL insProduce('tt90000021','coWBROS002', 168000000);
CALL insProduce('tt90000022','coA2400003', 50000000);
CALL insProduce('tt90000023','coSEARCH02', 20000000);
CALL insProduce('tt90000024','coNETFLX01', 20000000);
CALL insProduce('tt90000025','coNEON0002', 16000000);
CALL insProduce('tt90000026','coFREM001', 25000000);
CALL insProduce('tt90000027','coHBO00001', 15000000);
CALL insProduce('tt90000028','coTOHO0002', 18000000);
CALL insProduce('tt90000029','coGKIDS002', 8000000);
CALL insProduce('tt90000030','coPATHE001', 12000000);