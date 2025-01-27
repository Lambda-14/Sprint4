-- NIVELL 1

-- Exercici 1
USE transactions;

    CREATE TABLE IF NOT EXISTS credit_card (
        id VARCHAR(20) PRIMARY KEY,
        iban VARCHAR(50),
        pan VARCHAR(255),
        pin VARCHAR(4),
        cvv INT,
        expiring_date VARCHAR(20)
    );
ALTER TABLE transaction 
ADD CONSTRAINT fk_credit_card_id FOREIGN KEY (credit_card_id) REFERENCES credit_card(id);


-- Exercici 2
-- El departament de Recursos Humans ha identificat un error en el número de compte de l'usuari amb ID CcU-2938. La informació que ha de mostrar-se per a aquest registre és: R323456312213576817699999. Recorda mostrar que el canvi es va realitzar.
UPDATE credit_card
SET iban = "R323456312213576817699999"
WHERE id = "CcU-2938";

SELECT iban FROM credit_card WHERE id = "CcU-2938";


-- Exercici 3
-- En la taula "transaction" ingressa un nou usuari
INSERT INTO credit_card (id) VALUES ("CcU-9999"); -- Placeholder credit_card id para que no dé error insertar en transaction
INSERT INTO company (id) VALUES ("b-9999"); -- Mismo placeholder
INSERT INTO transaction (id, credit_card_id, company_id, user_id, lat, longitude, amount, declined) VALUES ('108B1D1D-5B23-A76C-55EF-C568E49A99DD', 'CcU-9999', 'b-9999', '9999', '	829.999', '-117.999', '111.11', '0');
SELECT * FROM transaction WHERE credit_card_id = "CcU-9999";


-- Exercici 4
-- Des de recursos humans et sol·liciten eliminar la columna "pan" de la taula credit_*card. Recorda mostrar el canvi realitzat.
ALTER TABLE credit_card
DROP COLUMN pan;
SELECT * FROM credit_card WHERE id = "CcU-9999";


-- NIVELL 2

-- Exercici 1
-- Elimina de la taula transaction el registre amb ID 02C6201E-D90A-1859-B4EE-88D2986D3B02 de la base de dades.
DELETE FROM transaction
WHERE id = "02C6201E-D90A-1859-B4EE-88D2986D3B02";


-- Exercici 2
-- La secció de màrqueting desitja tenir accés a informació específica per a realitzar anàlisi i estratègies efectives. S'ha sol·licitat crear una vista que proporcioni detalls clau sobre les companyies i les seves transaccions. Serà necessària que creïs una vista anomenada VistaMarketing que contingui la següent informació: Nom de la companyia. Telèfon de contacte. País de residència. Mitjana de compra realitzat per cada companyia. Presenta la vista creada, ordenant les dades de major a menor mitjana de compra.
CREATE VIEW `VistaMarketing` AS 
SELECT company_name, phone, country, round(avg(amount), 2) AS Average
FROM company
JOIN transaction
ON (company.id = company_id)
GROUP BY company_name, phone, country
ORDER BY Average desc;

SELECT * FROM vistamarketing;

-- Exercici 3
-- Filtra la vista VistaMarketing per a mostrar només les companyies que tenen el seu país de residència en "Germany"
SELECT *
FROM vistamarketing
WHERE country = "Germany";


-- NIVELL 3

-- Exercici 1
CREATE INDEX idx_user_id ON transaction(user_id);
 
CREATE TABLE IF NOT EXISTS data_user (
        id INT PRIMARY KEY,
        name VARCHAR(100),
        surname VARCHAR(100),
        phone VARCHAR(150),
        email VARCHAR(150),
        birth_date VARCHAR(100),
        country VARCHAR(150),
        city VARCHAR(150),
        postal_code VARCHAR(100),
        address VARCHAR(255),
        FOREIGN KEY(id) REFERENCES transaction(user_id)        
    );
    
SELECT CONSTRAINT_NAME -- La fk esta mal creada en el código anterior, por lo que buscaremos el nombre de esa constraint mal hecha para poder eliminarla y crearla correctamente
FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
WHERE TABLE_NAME = "data_user";

ALTER TABLE data_user
DROP CONSTRAINT data_user_ibfk_1;

ALTER TABLE transaction 
ADD CONSTRAINT fk_user_id FOREIGN KEY (user_id) REFERENCES data_user(id);

-- Procedemos con los cambios a columas de las distintas tablas
ALTER TABLE data_user -- Cambiamos el nombre de la columna email
CHANGE email personal_email VARCHAR(150);

ALTER TABLE company -- Borramos la columna website
DROP COLUMN website;

ALTER TABLE credit_card -- Añadimos la columna fecha_actual
ADD fecha_actual DATE;


-- Exercici 2
CREATE VIEW `InformeTecnico` AS 
SELECT transaction.id as transaction, name, surname, iban, company_name
FROM transaction
JOIN company
ON (company_id = company.id)
JOIN credit_card
ON (credit_card_id = credit_card.id)
JOIN data_user
ON (user_id = data_user.id)
ORDER BY transaction desc;