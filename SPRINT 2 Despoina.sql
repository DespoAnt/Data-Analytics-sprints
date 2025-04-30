		-- Exrecici 2 
-- Utilitzant JOIN realitzaràs les següents consultes:

-- Llistat dels països que estan fent compres.
SELECT DISTINCT(country) AS buyer_countries
FROM company c
JOIN transaction tr
ON c.id = tr.company_id
WHERE tr.declined = 0;

-- Des de quants països es realitzen les compres.
SELECT COUNT(DISTINCT(country)) AS total_buyer_countries
FROM company c
JOIN transaction tr
ON c.id = tr.company_id
WHERE tr.declined = 0;

-- Identifica la companyia amb la mitjana més gran de vendes.
SELECT c.company_name
FROM company c
JOIN transaction tr 
ON c.id = tr.company_id
WHERE declined = 0
GROUP BY c.company_name
ORDER BY AVG(tr.amount) DESC
LIMIT 1;

-- Utilitzant només subconsultes (sense utilitzar JOIN):
-- Mostra totes les transaccions realitzades per empreses d'Alemanya.
SELECT * 
FROM transaction
WHERE company_id IN (
SELECT id
FROM company 
WHERE country = "Germany"
); 
-- Llista les empreses que han realitzat transaccions per un amount superior a la mitjana de totes les transaccions.
SELECT *
FROM company
WHERE id IN (
SELECT company_id
FROM transaction 
WHERE declined = 0 AND amount > (
SELECT AVG(amount)
FROM transaction
WHERE declined = 0 
));					


-- Eliminaran del sistema les empreses que no tenen transaccions registrades, entrega el llistat d'aquestes empreses. 
SELECT company_name
FROM company
WHERE id NOT IN(
SELECT company_id
FROM transaction
);

## Nivel 2 ##

-- Identifica els cinc dies que es va generar la quantitat més gran d'ingressos a l'empresa per vendes. 
-- Mostra la data de cada transacció juntament amb el total de les vendes.

SELECT DATE(timestamp) AS transaction_date, SUM(amount) AS total_sales_amount
FROM transaction 
WHERE declined = 0
GROUP BY transaction_date
ORDER BY total_sales_amount DESC
LIMIT 5;

-- Quina és la mitjana de vendes per país? Presenta els resultats ordenats de major a menor mitjà.
SELECT c.country, ROUND(AVG(tr.amount), 2) AS sales_avg
FROM company c
JOIN transaction tr 
ON c.id = tr.company_id
WHERE tr.declined = 0
GROUP BY c.country
ORDER BY sales_avg DESC;

-- En la teva empresa, es planteja un nou projecte per a llançar algunes campanyes publicitàries per a fer competència a la companyia "Non Institute". 
-- Per a això, et demanen la llista de totes les transaccions realitzades per empreses que estan situades en el mateix país que aquesta companyia.
-- Mostra el llistat aplicant JOIN i subconsultes.
SELECT  *
FROM transaction tr 
JOIN company c
ON tr.company_id = c.id
WHERE country = (
SELECT country
FROM company 
WHERE company_name = "Non Institute"
) AND NOT company_name= "Non Institute";

-- Mostra el llistat aplicant solament subconsultes.
SELECT *
FROM transaction 
WHERE company_id IN (
SELECT id
FROM company 
WHERE country IN (
SELECT country
FROM company
WHERE company_name = "Non Institute") 
AND NOT company_name= "Non Institute");

## Nivel 3 ##
-- Presenta el nom, telèfon, país, data i amount, d'aquelles empreses que van realitzar transaccions amb un valor comprès entre 100 i 200 euros i 
-- en alguna d'aquestes dates: 29 d'abril del 2021, 20 de juliol del 2021 i 13 de març del 2022. Ordena els resultats de major a menor quantitat

SELECT c.company_name, c.phone, c.country, DATE(tr.timestamp) AS transaction_date, tr.amount
FROM company c 
JOIN transaction tr
ON c.id = tr.company_id
WHERE tr.amount BETWEEN 100 AND 200 AND 
DATE(tr.timestamp) IN ("2021-04-29", "2021-07-20", "2022-03-13")
ORDER BY tr.amount DESC;


-- Necessitem optimitzar l'assignació dels recursos i dependrà de la capacitat operativa que es requereixi, per la qual cosa et demanen la informació 
-- sobre la quantitat de transaccions que realitzen les empreses, però el departament de recursos humans és exigent i vol un llistat de les empreses 
-- on especifiquis si tenen més de 4 transaccions o menys.

SELECT c.company_name,
CASE 
WHEN COUNT(tr.id) > 4 THEN "MAS DE 4 TRANSACCIONES"
ELSE "IGUAL O MENOS DE 4 TRANSACCIONES"
END AS label_transactions
FROM company c
JOIN transaction tr 
ON c.id = tr.company_id
WHERE declined = 0
GROUP BY c.company_name;


