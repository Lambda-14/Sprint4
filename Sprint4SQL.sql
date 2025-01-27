CREATE DATABASE IF NOT EXISTS sprint4;
USE sprint4;

-- Comprovar i arreglar permisos
SET GLOBAL local_infile = TRUE;
SHOW GLOBAL VARIABLES LIKE 'local_infile';

SHOW GLOBAL VARIABLES LIKE 'secure_file_priv';


-- Creació de les taules i dades
CREATE TABLE company (
    company_id VARCHAR(20) PRIMARY KEY,
    company_name VARCHAR(255),
    phone VARCHAR(15),
    email VARCHAR(100),
    country VARCHAR(100),
    website VARCHAR(255)
);

LOAD DATA INFILE  
'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/companies.csv'
INTO TABLE company 
FIELDS TERMINATED BY ',' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(company_id, company_name, phone, email, country, website);


CREATE TABLE credit_card (
    id VARCHAR(20) PRIMARY KEY,
    user_id INT,
    iban VARCHAR(50),
    pan VARCHAR(50),
    pin VARCHAR(4),
    cvv INT,
    track1 VARCHAR(255),
    track2 VARCHAR(255),
    expiring_date VARCHAR(20)
);

LOAD DATA INFILE  
'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/credit_cards.csv'
INTO TABLE credit_card
FIELDS TERMINATED BY ',' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(id, user_id, iban, pan, pin, cvv, track1, track2, expiring_date);

ALTER TABLE credit_card
DROP user_id;


CREATE TABLE data_users (
    id INT PRIMARY KEY,
    name VARCHAR(100),
    surname VARCHAR(100),
    phone VARCHAR(150),
    email VARCHAR(150),
    birth_date VARCHAR(100),
    country VARCHAR(150),
    city VARCHAR(150),
    postal_code VARCHAR(100),
    address VARCHAR(255)
);

LOAD DATA INFILE  
'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/users_ca.csv'
INTO TABLE data_users
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(id, name, surname, phone, email, birth_date, country, city, postal_code, address);

LOAD DATA INFILE  
'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/users_uk.csv'
INTO TABLE data_users
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(id, name, surname, phone, email, birth_date, country, city, postal_code, address);

LOAD DATA INFILE  
'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/users_usa.csv'
INTO TABLE data_users
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(id, name, surname, phone, email, birth_date, country, city, postal_code, address);


CREATE TABLE products (
    id INT PRIMARY KEY,
    product_name VARCHAR(100),
    currency VARCHAR(1),
    price VARCHAR(100),
    colour VARCHAR(10),
    weight FLOAT,
    warehouse_id VARCHAR(100)
);

LOAD DATA INFILE  
'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/products.csv'
INTO TABLE products
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(id, product_name, price, colour, weight, warehouse_id);

UPDATE products
SET currency = LEFT(price, 1);
UPDATE products
SET price = substr(price, 2);
ALTER TABLE products
MODIFY price DECIMAL(10,2);


CREATE TABLE transaction (
    id VARCHAR(255) PRIMARY KEY,
    card_id VARCHAR(15),
    business_id VARCHAR(20),
    timestamp VARCHAR(30),
    amount DECIMAL(10,2),
    declined TINYINT,
    product_ids VARCHAR(255),
    user_id INT,
    lat VARCHAR(255),
    longitude VARCHAR(255)
);
LOAD DATA INFILE  
'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/transactions.csv'
INTO TABLE transaction
FIELDS TERMINATED BY ';'
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(id, card_id, business_id, timestamp, amount, declined, product_ids, user_id, lat, longitude);
CREATE TABLE transaction_product (
    transaction_id VARCHAR(255),
    product_id INT,
    PRIMARY KEY (transaction_id, product_id)
);
INSERT INTO transaction_product (transaction_id, product_id)
WITH RECURSIVE SplitValues AS (
        SELECT id, SUBSTRING_INDEX(product_ids, ',', 1) AS split_value, IF(LOCATE(',', product_ids) > 0, SUBSTRING(product_ids, LOCATE(',', product_ids) + 1), NULL) AS remaining_values
        FROM transaction
        UNION ALL
        SELECT id, SUBSTRING_INDEX(remaining_values, ',', 1) AS split_value, IF(LOCATE(',', remaining_values) > 0, SUBSTRING(remaining_values, LOCATE(',', remaining_values) + 1), NULL)
        FROM SplitValues
        WHERE remaining_values IS NOT NULL)
SELECT id, split_value
FROM SplitValues;
 /*ALTER TABLE transaction
DROP product_ids; */

-- NIVELL 1
-- Afegim les FK a les taules
ALTER TABLE transaction
ADD CONSTRAINT fk_card_id
FOREIGN KEY (card_id) REFERENCES credit_card(id),
ADD CONSTRAINT fk_business_id
FOREIGN KEY (business_id) REFERENCES company(company_id),
ADD CONSTRAINT fk_user_id
FOREIGN KEY (user_id) REFERENCES data_users(id);

ALTER TABLE transaction_product
ADD CONSTRAINT fk_transaction_id
FOREIGN KEY (transaction_id) REFERENCES transaction(id),
ADD CONSTRAINT fk_product_id
FOREIGN KEY (product_id) REFERENCES products(id);


-- Exercici 1
-- Realitza una subconsulta que mostri tots els usuaris amb més de 30 transaccions utilitzant almenys 2 taules.
SELECT data_users.id as User, count(transaction.id) as NumTrans
FROM data_users
JOIN transaction
ON (data_users.id = user_id)
GROUP BY data_users.id
HAVING count(transaction.id) > 30
ORDER BY NumTrans desc;

-- Exercici 2
-- Mostra la mitjana d'amount per IBAN de les targetes de crèdit a la companyia Donec Ltd, utilitza almenys 2 taules.
SELECT iban, round(avg(amount), 2) as Average
FROM credit_card
JOIN transaction
ON (credit_card.id = card_id)
JOIN company
ON (company_id = business_id)
WHERE company_name = "Donec Ltd"
GROUP BY iban;



-- NIVELL 2
-- Crea una nova taula que reflecteixi l'estat de les targetes de crèdit basat en si les últimes tres transaccions van ser declinades
UPDATE transaction
SET timestamp = str_to_date(timestamp, '%d/%m/%Y %H:%i');

ALTER TABLE transaction
MODIFY timestamp TIMESTAMP;


CREATE TABLE active_cards (
    card_id VARCHAR(15) PRIMARY KEY,
    active TINYINT
);

INSERT INTO active_cards (card_id, active)
SELECT card_id, IF(sum(declined)>= 3, 0, 1) as Active
FROM (SELECT card_id, timestamp, declined
	FROM (SELECT *, row_number() over (partition by card_id order by card_id, timestamp desc) as seqnum
	from transaction) as a
	WHERE seqnum <= 3
	order by card_id, timestamp desc, seqnum) as b
GROUP BY card_id;

ALTER TABLE active_cards
ADD CONSTRAINT fk_active_card
FOREIGN KEY (card_id) REFERENCES credit_card(id);


-- Exercici 1
-- Quantes targetes estan actives?
SELECT count(card_id) as ActiveCards
FROM active_cards
WHERE active = 1;

SELECT sum(active) as ActiveCards
FROM active_cards;


-- NIVELL 3
-- Exercici 1
-- Necessitem conèixer el nombre de vegades que s'ha venut cada producte.
SELECT products.id, count(transaction.id) as NumSales
FROM products
JOIN transaction_product AS tp
ON (products.id = tp.product_id)
JOIN transaction
ON (tp.transaction_id = transaction.id)
GROUP BY products.id
ORDER BY products.id;