INSERT INTO "CUSTOMER" (id, name, minit, lname, country, points, phone, bdate, sex)
VALUES ('U00000555', 'Sezercan', NULL, 'Tanışman', 'RUS', 0, '11111111111', '1995-01-12', 'M');

UPDATE "CUSTOMER"
SET points = points + 100
WHERE EXTRACT(MONTH FROM bdate) = EXTRACT(MONTH FROM CURRENT_DATE)
AND EXTRACT(DAY FROM bdate) = EXTRACT(DAY FROM CURRENT_DATE);

DELETE FROM "CUSTOMER"
WHERE country = 'RUS';

