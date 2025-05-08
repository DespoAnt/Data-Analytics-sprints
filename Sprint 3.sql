-- NIVEL 1

-- Crear la tabla credit_card
CREATE TABLE IF NOT EXISTS credit_card (
        id VARCHAR(15) PRIMARY KEY,
        iban VARCHAR(34),
        pan VARCHAR(23),
        pin VARCHAR(4),
        cvv VARCHAR(4),
        expiring_date VARCHAR(10)
	);
    
-- Insertar datos en la tabla credit_card del archivo "datos_introducir_credit.sql"

-- Crear FK en la tabla transaction de la PK de la tabla credit_card
ALTER TABLE transaction 
ADD FOREIGN KEY (credit_card_id) REFERENCES credit_card(id);

-- Actualizar el número de cuenta del usuario con ID CcU-2938 a R323456312213576817699999
UPDATE credit_card
SET iban = "R323456312213576817699999"
WHERE id = "CcU-2938";

-- Mostar el cambio realizado
SELECT *
FROM credit_card
WHERE id = "CcU-2938";

/*Añadir un nuevo usuario en la tabla transaction.
Para poder añadir los datos del nuevo usuario se tienen que actualizar las PK de las tablas company y credit_card (id) añadiendo los valores correspondientes. 
Este paso es necesario por la relación entre las tablas, insertar un nuevo valor en una FK cuando el mismo valor no existe en la PK de la tabla de referencia no es posible. 
Primero insertaré en la tabla company el nuevo valor b-9999 en id. 
Luego insertaré en la tabla credit_card el nuevo valor CcU-9999 en id 
Como paso final, añadiré los datos del nuevo usario en la tabla transaction */

INSERT INTO company (id) VALUE ("b-9999");
INSERT INTO  credit_card (id) VALUE ("CcU-9999"); 
INSERT INTO transaction (Id, credit_card_id, company_id, user_id, lat, longitude, amount, declined) 
VALUES ("108B1D1D-5B23-A76C-55EF-C568E49A99DD", "CcU-9999", "b-9999", "9999", "829.999", "-117.999", "111.11", "0");

SELECT *
FROM transaction
WHERE credit_card_id = "CcU-9999";

-- eliminar columna pan de la tabla credit_card
ALTER TABLE credit_card
DROP COLUMN pan;
-- mostrar el cambio en la tabla 
SHOW COLUMNS
FROM credit_card;

-- NIVEL 2 
-- eliminar de la tabla transaction el registro con ID 02C6201E-D90A-1859-B4EE-88D2986D3B02
DELETE FROM transaction
WHERE id = "02C6201E-D90A-1859-B4EE-88D2986D3B02";

-- revisar si el registro se eliminó correctamente
SELECT *
FROM transaction
WHERE id = "02C6201E-D90A-1859-B4EE-88D2986D3B02";

-- Crear VistaMarketing 
CREATE VIEW VistaMarketing AS 
SELECT c.company_name, c.phone, c.country, ROUND(AVG(tr.amount),2) AS avg_purchase
FROM company c
JOIN transaction tr 
ON c.id = tr.company_id
WHERE tr.declined = 0
GROUP BY c.id
ORDER BY avg_purchase DESC; 
-- Mostrar VistaMarketing
SELECT *
FROM VistaMarketing;

-- Mostrar de VistaMarketing solo las empresas de Alemania
SELECT *
FROM VistaMarketing
WHERE country = "Germany";

-- NIVEL 3
-- Actualizar la BBDD 

-- Eliminar la columna website de la tabla company
ALTER TABLE company
DROP COLUMN website;
-- Revisar el cambio 
DESCRIBE company;

-- modificar el max.de caracteres permitido a 20 en id de la tabla credit_card
ALTER TABLE credit_card
MODIFY COLUMN id VARCHAR(20);

-- modificar el iban de la tabla credit_card para permitir hasta 50 caracteres
ALTER TABLE credit_card
MODIFY COLUMN iban VARCHAR(50);

-- modificar el tipo de la variable cvv a INT en la tabla credit_card
ALTER TABLE credit_card
MODIFY COLUMN cvv INT;

-- modificar el máximo de caracteres en expiring_date de la tabla credit_card a 20
ALTER TABLE credit_card
MODIFY COLUMN expiring_date VARCHAR(20);

-- crear nueva columna (fecha_actual(DATE)) en la tabla credit_card
ALTER TABLE credit_card
ADD COLUMN fecha_actual DATE;

-- revisar los cambios en la tabla credit card
DESCRIBE credit_card;

 -- Crear tabla user ejecutando el archivo "estructura_dades_user"

CREATE INDEX idx_user_id ON transaction(user_id);
 
CREATE TABLE IF NOT EXISTS user (
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

-- Insertar los datos en la tabla user utilizando el archivo datos_introducir_user(1).sql
    
-- cambiar el nombre de la tabla user a data_user y de la columna email a personal_email
ALTER TABLE user
RENAME TO data_user,
RENAME COLUMN email TO personal_email;

-- revisar los cambios en la tabla data_user
DESCRIBE data_user;

-- al intentar crear la FK user_id en tabla transaction para conectar con tabla data_user por PK id tuve un error code 1452
-- para resolver el error 1452 hay que ver si existen registros en user_id de transaction que no existen en id de data_user
SELECT tr.user_id
FROM transaction tr 
LEFT JOIN data_user du
on tr.user_id = du.id
WHERE du.id IS NULL;

-- Añadir user_id 9999 en data_user para poder crear la FK en transaction
INSERT INTO data_user(id) VALUES ("9999");

-- crear la FK user_id en tabla transaction, conectar con tabla data_user por PK id
ALTER TABLE transaction
ADD FOREIGN KEY (user_id) REFERENCES data_user(id);

-- consultando el eschema de data_user aparece que el id es PK y FK, eliminar el FK de la tabla 
ALTER TABLE data_user
DROP FOREIGN KEY data_user_ibfk_1;

-- Crear vista "InformeTecnico"
CREATE VIEW InformeTecnico AS 
SELECT tr.id AS transaction_id, du.name AS user_name, du.surname AS user_surname, cc.iban, c.company_name
FROM transaction tr
JOIN data_user du
ON tr.user_id = du.id
JOIN credit_card cc
ON tr.credit_card_id = cc.id
JOIN company c
ON tr.company_id = c.id
ORDER BY transaction_id DESC; 

-- mostar la vista InformeTecnico
SELECT * 
FROM informetecnico;


