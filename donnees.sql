PREPARE eventsDans (text) AS SELECT id, titre FROM Evenements e NATURAL JOIN Lieux l WHERE l.code_postal = $1;

\prompt 'Evenements dans larrondissement : ' cp
EXECUTE eventsDans(:cp);
