-- Part 3

-- Q1. List films which is >= 150 minutes long ORDER BY length descending
SELECT filmID, title, year, duration
FROM Film
WHERE duration >= 150
ORDER BY duration DESC;

-- Q2. Get all ceremonies which organized more than 2 days
SELECT festivalID, ceremonyYear, startDate, endDate, DATEDIFF(endDate, startDate) AS organizedDays
FROM YearlyCeremony
WHERE DATEDIFF(endDate, startDate) > 2
ORDER BY organizedDays DESC;

-- Q3. Query all movies which start by 'The'
SELECT filmID, title, year, genre
FROM Film
WHERE LOWER(title) LIKE 'the %'
ORDER BY year DESC;

-- Q4. Aggregate duration by average, min, max of each film genre
SELECT genre, round(avg(duration), 0) AS avgDuration, 
        min(duration) AS minDuration, max(duration) AS maxDuration
FROM Film
group by genre
ORDER BY avgDuration DESC;

-- Q5. Age of nominees at the time of attending the ceremony
SELECT p.name, p.gender, pn.personRole, n.ceremonyYear, f.name,
    TIMESTAMPDIFF(YEAR, p.birthday, n.nominationDate) AS ageAtCeremony
FROM PersonNominated pn
LEFT JOIN Person p ON pn.personID = p.personID
LEFT JOIN Nomination n ON n.nomID = pn.nomID
LEFT JOIN Festival f ON n.festivalID = f.festivalID
ORDER BY n.ceremonyYear DESC, ageAtCeremony DESC;


-- Q6. Aggregate the min, max, avg, sum of the cost of each film genre
SELECT genre, round(avg(cost), 0) AS avgCost, 
    min(cost) AS minCost, max(cost) AS maxCost
FROM Produce p
LEFT JOIN Film f ON p.filmID = f.filmID
group by genre
ORDER BY avgCost DESC;

-- Q7. Rank studio based ON the total cost of films they produced
SELECT s.studioName, sum(p.cost) AS totalCost
FROM Produce p 
LEFT JOIN Studio s ON p.studioID = s.studioID
group by s.studioID
ORDER BY totalCost DESC;

-- Q8. Studio with the most expensive film
SELECT s.studioName, f.title, p.cost
FROM Produce p
LEFT JOIN Studio s ON p.studioID = s.studioID
LEFT JOIN Film f ON p.filmID = f.filmID
WHERE (p.studioID, p.cost) in (
    SELECT p2.studioID, max(p2.cost)
    FROM Produce p2
    group by p2.studioID
)
ORDER BY p.cost DESC;


-- Q9. The film that have the duration higher than the average duration of all films
SELECT f.filmID, f.title, f.genre, f.duration
FROM Film f
WHERE f.duration > (SELECT avg(f2.duration) FROM Film f2)
ORDER BY f.duration DESC;



-- Q10. List out the Winner with all their details
SELECT n.festivalID, n.ceremonyYear, ac.categoryName, n.detail, 
    f.title AS filmTitle, p.name AS personName, pn.personRole
FROM Nomination n
LEFT JOIN AwardCategory ac ON ac.categoryID = n.categoryID
LEFT JOIN FilmNominated fn ON fn.nomID = n.nomID
LEFT JOIN Film f ON f.filmID = fn.filmID
LEFT JOIN PersonNominated pn ON pn.nomID = n.nomID
LEFT JOIN Person p ON p.personID = pn.personID
WHERE n.isWinner = true
ORDER BY n.ceremonyYear ASC;



-- Part 4
-- Triggers
SHOW TRIGGERS FROM pham_22317009;

-- 1. Auto fill characterName when inserting into PersonNominated table
DROP TRIGGER IF EXISTS trg_default_characterName_pn;
DELIMITER //
CREATE TRIGGER trg_default_characterName_pn
BEFORE INSERT ON PersonNominated
FOR EACH ROW
BEGIN 
    IF NEW.characterName IS NULL THEN
        IF UPPER(NEW.personRole) = 'DIRECTOR' THEN
            SET NEW.characterName = 'N/A Director';
        ELSEIF UPPER(NEW.personRole) IN ('ACTOR', 'ACTRESS') THEN
            SET NEW.characterName = 'Unknown Character Name';
        ELSE
            SET NEW.characterName = 'N/A';
        END IF;
    END IF;
END //
DELIMITER ;

-- Test the trigger
-- Testcase 1. Director
SELECT * FROM PersonNominated WHERE nomID='an1012' AND personID='nm0001401';
INSERT INTO PersonNominated(nomID, personID, personRole, characterName)
VALUES ('an1012','nm0001401','DIRECTOR',NULL); 
-- EXPECT: characterName = 'N/A Director'
SELECT * FROM PersonNominated WHERE nomID='an1012' AND personID='nm0001401';

-- Testcase 2. Actor
SELECT * FROM PersonNominated WHERE nomID='an1004' AND personID='nm0000108';
INSERT INTO PersonNominated(nomID, personID, personRole, characterName)
VALUES ('an1004','nm0000108','ACTOR',NULL);     
-- EXPECT: characterName = 'Unknown Character Name'
SELECT * FROM PersonNominated WHERE nomID='an1004' AND personID='nm0000108';

-- Testcase 3. With characterName provided
SELECT * FROM PersonNominated WHERE nomID='an1013' AND personID='nm0634249';
INSERT INTO PersonNominated(nomID, personID, personRole, characterName)
VALUES ('an1013','nm0634249','ACTOR','Supermannnnnnnnn');
-- EXPECT: characterName = 'Supermannnnnnnnn'
SELECT * FROM PersonNominated WHERE nomID='an1013' AND personID='nm0634249';



-- 2. Prevent duplicate nomination of the same film from the SAME festival/year/category
DROP TRIGGER IF EXISTS trg_prevent_duplicate_filmnominated;
DELIMITER //
CREATE TRIGGER trg_prevent_duplicate_filmnominated
BEFORE INSERT ON FilmNominated
FOR EACH ROW
BEGIN
    -- Slot defined by (festivalID, ceremonyYear, categoryID)
    IF EXISTS (
        SELECT 1
        FROM FilmNominated fn
        JOIN Nomination n1  ON n1.nomID  = fn.nomID
        JOIN Nomination n2 ON n2.nomID = NEW.nomID
        WHERE fn.filmID = NEW.filmID
            AND n1.festivalID   = n2.festivalID
            AND n1.ceremonyYear = n2.ceremonyYear
            AND n1.categoryID   = n2.categoryID
        ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Same film already nominated in the festival/year/category';
    END IF;
END//
DELIMITER ;

-- Test the trigger
-- Testcase 1. Fail case
SELECT fn.nomID, fn.filmID, n1.festivalID, n1.ceremonyYear, n1.categoryID, fn.specialNote, n1.isWinner
FROM FilmNominated fn
JOIN Nomination n1  ON n1.nomID  = fn.nomID
WHERE fn.filmID = 'tt15398776'
    AND n1.festivalID   = 'OSC'
    AND n1.ceremonyYear = 2023
    AND n1.categoryID   = 'OC03';

SELECT * FROM Nomination WHERE nomID='anT004';

INSERT INTO Nomination(nomID, nominationDate, detail, isWinner, festivalID, ceremonyYear, categoryID)
VALUES ('anT004','2023-03-12','Test duplicate slot', FALSE, 'OSC', 2023, 'OC03'); -- Can try to change the categoryID to OC02 to pass
-- After inserting the nomination, check again
SELECT * FROM Nomination WHERE nomID='anT004';

-- EXPECT: EROR 45000 'Same film already nominated in the festival/year/category'
-- ('an1004','tt15398776','Lead actor win'),
INSERT INTO FilmNominated(nomID, filmID, specialNote)
VALUES ('anT004','tt15398776','Should fail');


-- Testcase 2. Success case
SELECT fn.nomID, fn.filmID, n1.festivalID, n1.ceremonyYear, n1.categoryID, fn.specialNote, n1.isWinner
FROM FilmNominated fn
JOIN Nomination n1  ON n1.nomID  = fn.nomID
WHERE fn.filmID = 'tt15398776'
    AND n1.festivalID   = 'OSC'
    AND n1.ceremonyYear = 2023
    AND n1.categoryID   = 'OC01';

SELECT * FROM Nomination WHERE nomID='anT005';

INSERT INTO Nomination(nomID, nominationDate, detail, isWinner, festivalID, ceremonyYear, categoryID)
VALUES ('anT005','2023-03-12','Picture nom', FALSE, 'OSC', 2023, 'OC01');
-- After inserting the nomination, check again

SELECT * FROM Nomination WHERE nomID='anT005';

-- EXPECT: data inserted
INSERT INTO FilmNominated(nomID, filmID, specialNote)
VALUES ('anT005','tt15398776','Different category is OK');

SELECT * FROM FilmNominated WHERE nomID='anT005';

-- Stored Procedures
SHOW PROCEDURE STATUS WHERE Db = 'pham_22317009';

-- 1. Ensure a category exists (if missing thenINSERT, else UPDATE its name/class)
DROP PROCEDURE IF EXISTS ensure_category;
DELIMITER //
CREATE PROCEDURE ensure_category(
    IN inp_categoryID VARCHAR(10),
    IN inp_festivalID VARCHAR(10),
    IN inp_categoryName VARCHAR(50),
    IN inp_awardClass VARCHAR(50)
)
BEGIN
    IF EXISTS (SELECT 1 FROM AwardCategory WHERE categoryID=inp_categoryID) THEN
        UPDATE AwardCategory
        SET categoryName = inp_categoryName,
            awardClass = inp_awardClass,
            festivalID = inp_festivalID
        WHERE categoryID = inp_categoryID;
    ELSE
        INSERT INTO AwardCategory(categoryID, categoryName, awardClass, festivalID)
        VALUES(inp_categoryID, inp_categoryName, inp_awardClass, inp_festivalID);
    END IF;
END//
DELIMITER ;

-- Test the procedure
-- Testcase 1. Insert new category
SELECT * FROM AwardCategory WHERE categoryID='OC99';

CALL ensure_category('OC99','OSC','BEST CASTING','Casting');
SELECT * FROM AwardCategory WHERE categoryID='OC99';

-- Testcase 2. Update existing category

CALL ensure_category('OC99','OSC','CASTING ABC','Crafting');
SELECT * FROM AwardCategory WHERE categoryID='OC99';



-- 2. Search nominations by keyword and daterange
DROP PROCEDURE IF EXISTS search_nominations;
DELIMITER //
CREATE PROCEDURE search_nominations(
    IN inp_keyword VARCHAR(100),          -- NULL/'' -> skip
    IN inp_dateFrom DATE,                 -- NULL -> skip
    IN inp_dateTo DATE,                   -- NULL -> skip
    IN inp_festivalID VARCHAR(10),         -- NULL -> get all festivals
    IN inp_isWinner BOOLEAN               -- NULL -> get all, TRUE -> winners only, FALSE -> non-winners only
)
BEGIN
    SELECT n.nomID, n.nominationDate, n.detail, n.isWinner, n.festivalID, n.ceremonyYear
    FROM Nomination n
    WHERE (inp_keyword   IS NULL OR inp_keyword   = '' OR n.detail LIKE CONCAT('%',inp_keyword,'%'))
        AND (inp_dateFrom  IS NULL OR n.nominationDate >= inp_dateFrom)
        AND (inp_dateTo    IS NULL OR n.nominationDate <= inp_dateTo)
        AND (inp_festivalID IS NULL OR n.festivalID = inp_festivalID)
        AND (inp_isWinner IS NULL OR n.isWinner = inp_isWinner)
    ORDER BY n.nominationDate DESC, n.nomID;
END//
DELIMITER ;

-- Test the procedure
-- Testcase 1. Search by keyword only
-- EXPECT: rows contains 'Director' 
CALL search_nominations('Director', NULL, NULL, NULL, NULL);

-- Testcase 2. Search by date range only
-- EXPECT: Nomination in 2023 only
CALL search_nominations(NULL, '2023-01-01', '2023-12-31', NULL, NULL);

-- Testcase 3. Search by festivalID only
-- EXPECT: Nominations in Oscar from 2019–2024 and 'winner'
CALL search_nominations('best', '2019-01-01', '2024-12-31', 'OSC', FALSE);
CALL search_nominations(NULL, '2019-01-01', '2024-12-31', 'OSC', NULL);
CALL search_nominations(NULL, '2019-01-01', '2024-12-31', 'OSC', TRUE);
CALL search_nominations('best', '2019-01-01', '2024-12-31', 'OSC', FALSE);

-- Testcase 4. Search by all NULL parameters
-- EXPECT: All nominations
CALL search_nominations(NULL, NULL, NULL, NULL, NULL);

-- Testcase 5. Search all winners
CALL search_nominations(NULL, NULL, NULL, NULL, TRUE);