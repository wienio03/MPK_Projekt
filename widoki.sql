--widok pokazujacy łączną sume zarobków z biletów i kart miejskich osobno (BRUTTO)
CREATE VIEW LaczneZarobki AS
SELECT 
    A.Rok AS Rok,
    COALESCE(A.SumaBilety, 0) AS SumaZBiletow,
    COALESCE(B.SumaZKartMiejskich, 0) AS SumaZKartMiejskich
FROM (
    SELECT 
        EXTRACT(YEAR FROM dataWydania) AS Rok,
        SUM(cena) AS SumaBilety
    FROM BILETY
    GROUP BY EXTRACT(YEAR FROM dataWydania)
) AS A 
FULL OUTER JOIN (
    SELECT 
        EXTRACT(YEAR FROM dataTransakcji) AS Rok,
        SUM(kwota) AS SumaZKartMiejskich
    FROM TransakcjeKartyMiejskie
    GROUP BY EXTRACT(YEAR FROM dataTransakcji)
) AS B
ON A.Rok = B.Rok;


--funkcja wypisujaca laczna sume zarobkow z biletow i kart miejskich w ciagu roku (BRUTTO)
FUNCTION DisplayAnnualTotalIncome (year INT) 
RETURNS INT
LANGUAGE plpgsql
AS
$$
DECLARE 
    annual_income MONEY;
BEGIN
    IF year NOT IN (SELECT Rok FROM LaczneZarobki) THEN
        RETURN 0.00;
    END IF;

    SELECT INTO annual_income (SumaZBiletow + SumaZKartMiejskich)
    FROM LaczneZarobki
    WHERE Rok = year;

    RETURN annual_income;
END;
$$
