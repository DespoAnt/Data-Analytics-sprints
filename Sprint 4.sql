-- Crear la base de datos nueva

CREATE DATABASE IF NOT EXISTS new_db_transactions;

USE new_db_transactions;

-- crear la tabla companies  

CREATE TABLE IF NOT EXISTS companies (   
		company_id VARCHAR(20) PRIMARY KEY,
        company_name VARCHAR(255),
        phone VARCHAR(15),
        email VARCHAR(100),
        country VARCHAR(100),
        website VARCHAR(255)
);

/* -- cargar los datos del archivo conmpanies.csv en la tabla

LOAD DATA INFILE 'C:\Users\tinke\Desktop\SQL\sprint 4\companies.csv'
INTO TABLE companies
FIELDS TERMINATED BY ',' 
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;  */

SHOW VARIABLES LIKE "secure_file_priv";  -- revisar en que carpeta se tienen que guardar los archivos de datos para poder luego cargarlos

-- cargar los datos del archivo companies.csv en la tabla 

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/companies.csv'
INTO TABLE companies
FIELDS TERMINATED BY ',' 			-- cada campo se separa por coma
LINES TERMINATED BY '\r\n'			-- el salto de linea en windows(CRLF)
IGNORE 1 LINES;						

-- crear la siguiente tabla, crearé una sola tabla para agregar en ella los tres archivos que contienen la información de los usuarios
CREATE TABLE IF NOT EXISTS users (     
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

-- primero insertaré los datos del archivo users_usa.csv
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/users_usa.csv'
INTO TABLE users
FIELDS TERMINATED BY ',' 			-- cada campo se separa por coma
ENCLOSED BY '"'						-- los valores del campo 'birth_date' están entre comillas
LINES TERMINATED BY '\r\n'			-- el salto de linea en windows(CRLF)
IGNORE 1 LINES;

-- luego el segundo archivo users_uk.csv
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/users_uk.csv'
INTO TABLE users
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;

-- por último el tercer archivo users.ca.csv
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/users_ca.csv'
INTO TABLE users
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;

-- crear la tabla credit_cards
CREATE TABLE IF NOT EXISTS credit_cards (
        id VARCHAR(15) PRIMARY KEY,
        user_id INT,
        iban VARCHAR(34),
        pan VARCHAR(23),
        pin VARCHAR(4),
        cvv VARCHAR(4),
        track1 VARCHAR(255),
        track2 VARCHAR(255),
        expiring_date VARCHAR(10)
	);
 -- insertar los datos del archivo credit_cards.csv   
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/credit_cards.csv'
INTO TABLE credit_cards
FIELDS TERMINATED BY ',' 			-- cada campo se separa por coma					
LINES TERMINATED BY '\n'			-- el salto de linea de Unix(LF)
IGNORE 1 LINES;

-- crear transaction que es la última tabla
CREATE TABLE IF NOT EXISTS transactions (
        id VARCHAR(255) PRIMARY KEY,
        card_id VARCHAR(15),
        business_id VARCHAR(20), 
        timestamp TIMESTAMP,
        amount DECIMAL(10, 2),
        declined BOOLEAN,
        product_ids VARCHAR(100),
        user_id INT,
        lat FLOAT,
        longitude FLOAT
    );

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/transactions.csv'
INTO TABLE transactions
FIELDS TERMINATED BY ';' 			-- el separador de los campos en este archivo es punto y coma (;) 
LINES TERMINATED BY '\r\n'			-- el salto de linea en windows(CRLF)
IGNORE 1 LINES;

-- proximo paso es definir las FK en la tabla de hechos transactions para poder conectar las tablas de dimensiones con ella

ALTER TABLE transactions								-- crear FK para conectar la tabla transactions con la tabla companies
ADD CONSTRAINT fk_company_transaction
FOREIGN KEY (business_id) REFERENCES companies(company_id);

ALTER TABLE transactions								-- crear FK para conectar la tabla transactions con la tabla users
ADD CONSTRAINT fk_user_transaction
FOREIGN KEY (user_id) REFERENCES users(id);

ALTER TABLE transactions								-- crear FK para conectar la tabla transactions con la tabla credit_cards
ADD CONSTRAINT fk_creditcard_transaction
FOREIGN KEY (card_id) REFERENCES credit_cards(id);

-- Exercici 1: Realitza una subconsulta que mostri tots els usuaris amb més de 30 transaccions utilitzant almenys 2 taules.

SELECT name, surname
FROM users
WHERE id IN (
		SELECT (user_id)
        FROM transactions 
        GROUP BY user_id
        HAVING COUNT(id) > 30
);

-- Exercici 2 : Mostra la mitjana d'amount per IBAN de les targetes de crèdit a la companyia Donec Ltd, utilitza almenys 2 taules.
SELECT cc.iban AS card_iban, ROUND(AVG(tr.amount), 2) AS average_amount
FROM credit_cards cc
JOIN transactions tr 
ON cc.id = tr.card_id
JOIN companies c
ON tr.business_id = c.company_id
WHERE c.company_name = "Donec Ltd" AND tr.declined = 0
GROUP BY cc.iban; 

-- Nivell 2
-- Crea una nova taula que reflecteixi l'estat de les targetes de crèdit basat en si les últimes tres transaccions van ser declinades

CREATE TABLE IF NOT EXISTS credit_card_status AS
		SELECT card_id, 
        CASE 
			WHEN SUM(declined) >= 3 THEN 'INACTIVE'					-- declined: 1 = TRUE, 0 = FALSE
            ELSE 'ACTIVE'
		END AS card_status
        FROM (
			SELECT card_id, declined, ROW_NUMBER() OVER (PARTITION BY card_id ORDER BY timestamp DESC) AS line_number
            FROM transactions
            ) AS ordered_transactions
		WHERE line_number <= 3										
        GROUP BY card_id;
        
-- revisar la tabla credit_card_status

SELECT * FROM credit_card_status;
        
-- crear la PK y FK para poder relacionar la tabla correctamente con la credit_cards        
ALTER TABLE credit_card_status
ADD PRIMARY KEY (card_id);

ALTER TABLE credit_card_status
ADD FOREIGN KEY (card_id) REFERENCES credit_cards(id); 
        

-- Quantes targetes estan actives?

SELECT COUNT(card_id) AS total_active_cards
FROM credit_card_status
WHERE card_status = 'ACTIVE';

-- Nivell 3
-- Crea una taula amb la qual puguem unir les dades del nou arxiu products.csv amb la base de dades creada, tenint en compte que des de transaction tens product_ids. 

CREATE TABLE IF NOT EXISTS products (
        id VARCHAR(100) PRIMARY KEY,     
        product_name VARCHAR(255),
        price VARCHAR(30), 
        colour VARCHAR(30),
        weight FLOAT,
        warehouse_id VARCHAR(50)
    ); 

-- ingresar los datos del archivo products.csv a la tabla

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/products.csv'
INTO TABLE products
FIELDS TERMINATED BY ',' 					-- cada campo se separa por coma					
LINES TERMINATED BY '\n'					-- el salto de linea Unix(LF)
IGNORE 1 LINES;

-- mostrar la tabla products
SELECT * FROM products;

-- actualizar la columna price eliminando el simbolo $ y el tipo de los datos a decimal para poder realizar consultas
-- me da error por el safe update mode, para poder actualizar se tiene que desactivar y luego volver a activarse

SET SQL_SAFE_UPDATES=0;  					-- desactivar safe mode

UPDATE products                          
SET price = REPLACE(price, '$', '');        -- eliminar el simbolo $ que aparece antes de los digitos del precio

SET SQL_SAFE_UPDATES=1;   					-- volver a activar el safe mode 

-- actualizar el tipo de la columna a decimal, todos ahora son valores numéricos

ALTER TABLE products
MODIFY COLUMN price DECIMAL(10, 2);

-- para realizar la relación de la tabla productos con la tabla transactions hay que crear una tabla intermedia de union porque la relación entre ellas es de N:M 

CREATE TABLE IF NOT EXISTS transaction_products (                             
		transaction_id VARCHAR(255) NOT NULL,
        product_id VARCHAR(100) NOT NULL,
        PRIMARY KEY (transaction_id, product_id),
        FOREIGN KEY (transaction_id) REFERENCES transactions(id),
        FOREIGN KEY (product_id) REFERENCES products(id)
        ); 

-- cargar datos en la tabla transaction_products

INSERT INTO transaction_products (transaction_id, product_id)
SELECT tr.id, pr.id
FROM transactions tr
JOIN products pr 
	ON FIND_IN_SET(pr.id, REPLACE(tr.product_ids, ' ', '')) > 0;   -- cambiar el espacio después del separador de valores a sin espacio
    
-- revisar la tabla con valores

SELECT * FROM transaction_products;

-- Genera la següent consulta: Necessitem conèixer el nombre de vegades que s'ha venut cada producte.

SELECT 
    pr.product_name, COUNT(transaction_id) AS total_sold_items
FROM
    products pr
        JOIN
    transaction_products tp ON pr.id = tp.product_id
GROUP BY pr.id;									-- agrupar por id que es valor único por si existen productos con el mismo nombre


-- actualizar VARCHAR a DATE en users.birth_date y credit_cards.expiring_date
SET SQL_SAFE_UPDATES=0;

UPDATE users
SET birth_date = STR_TO_DATE(REPLACE(birth_date,',', ''), '%b %e %Y');   -- replace para el coma en el valor, %b nombre de mes abreviado, %e dia mes 0-31, %Y año 4 dígitos
ALTER TABLE users
MODIFY COLUMN birth_date DATE;											 -- y modificar el tipo de datos a DATE

UPDATE credit_cards
SET expiring_date = STR_TO_DATE(expiring_date,'%m/%d/%y');
ALTER TABLE credit_cards
MODIFY COLUMN expiring_date DATE;										-- %m mes con número 0-12, %d dia mes 01-31, %y año 2 dígitos

SET SQL_SAFE_UPDATES=1;

