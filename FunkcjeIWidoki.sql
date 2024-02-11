CREATE LANGUAGE plpython3u;
--zwraca zapis tesktowy przewidywanego czasu podróży
CREATE OR REPLACE FUNCTION czasPodrozy(adresZajezdni text, adresObecny text)
 RETURNS text
 AS $$
    import requests, json
    url = 'https://maps.googleapis.com/maps/api/distancematrix/json'
    parametry = {
        'destinations' : adresObecny',
        'origins': adresZajezdni,
        'units': 'metric',
        'key' : 'PLACEHOLDER '
    }
    wynik = requests.get(url, params=parametry)
    return(wynik.json()['rows'][0]['elements'][0]['duration']['text'])
$$
 LANGUAGE plpython3u;


--widok pokazujacy laczne roczne zarobki z danego roku z biletow i kart miejskich osobno
CREATE OR REPLACE VIEW LaczneZarobki AS

SELECT
    A.Rok AS Rok,
    A.SumaBilety AS SumaZBiletow,
    B.SumaZKartMiejskich AS SumaZKartMiejskich
FROM (
    SELECT
        EXTRACT(YEAR FROM dataWydania) AS Rok,
        SUM(cena) AS SumaBilety
    FROM Bilety
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

--widok pokazujacy wszystkich pracownikow podlegajacych danemu pracownikowi (swojemu przelozonemu)

CREATE OR REPLACE VIEW PodwladniPrzelozeni AS
    SELECT
        P1.idPracownika AS iddPrzelozonego,
        P1.imie AS imiePrzelozonego,
        P1.nazwisko AS nazwiskoPrzelozonego,
        P2.idPracownika AS idPodwladnego,
        P2.imie AS imiePodwladnego,
        P2.nazwisko AS nazwiskoPodwladnego
    FROM Pracownicy P1
    JOIN Pracownicy P2 ON P1.idPracownika = P2.idPracownika;


--funkcja wypisujaca laczna sume zarobkow z biletow i kart miejskich w ciagu roku (BRUTTO)
CREATE OR REPLACE FUNCTION DisplayAnnualTotalIncome (year INT)
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
$$;

--zwraca lokalizację pojazdu, powinna zwracać dane z systemu geolokalizacji pojazdu,
-- ale w ramach placeholdera zwraca przystanek na którym powinien być pojazd w tym momencie
CREATE OR REPLACE FUNCTION LokalizacjaPojazdu(numerPojazdu VARCHAR(10))
RETURNS TEXT
LANGUAGE plpgsql
AS
$$
BEGIN
    --RETURN (SELECT R.
END;
$$;

--wyświtla potencjalnie pojazdy zastępcze w wypadku awarii pojazdu na trasie
CREATE OR REPLACE FUNCTION PojazdyZastepcze(numerZepsutegoPojazdu VARCHAR(10))
RETURNS TABLE (numerPojazdu VARCHAR(10), zajezdnia VARCHAR(50), czasPodrozy TEXT)
LANGUAGE plpgsql
AS
$$
DECLARE
    współrzędneMiejscaAwarii VARCHAR(50);
BEGIN
    współrzędneMiejscaAwarii = LokalizacjaPojazdu(numerZepsutegoPojazdu);
    SELECT A.numerPojazdu, A.zajezdnia, czasPodrozy(Z.adres, współrzędneMiejscaAwarii)
    FROM Autobusy A
        JOIN ZajezdnieAutobusowe Z ON A.zajezdnia = Z.nazwa
    WHERE A.stan = 'czynny';
END;
$$;

--wyświetla serwisowane obecnie tramwaje i autobusy
CREATE OR REPLACE VIEW PojazdySerwisowane AS
    SELECT A.numerPojazdu, A.model, M.producent, MAX(P.data) as OstatnioUżytkowany FROM
        Autobusy A JOIN ModeleAutobusow M ON A.model = M.model JOIN PrzejazdyAutobusowe P ON A.numerpojazdu = P.pojazd
    WHERE A.stan = 'serwisowany'
    GROUP BY A.numerPojazdu, A.model, M.producent
    UNION
    SELECT T.numerPojazdu, T.model, M.producent, MAX(P.data) as OstatnioUżytkowany FROM
        Tramwaje T JOIN modeletramwajow M ON T.model = M.model JOIN PrzejazdyTramwajowe P ON T.numerpojazdu = P.pojazd
    WHERE T.stan = 'serwisowany'
    GROUP BY T.numerPojazdu, T.model, M.producent;


--wyświetla wszystkie linie, przydatne by uzyskać idLinii, które służy do rozróżnienia dwóch linii o tym samym numerze, ale mających inną pętlę końcową/startową
CREATE OR REPLACE VIEW WszystkieLinie AS
    SELECT * FROM LinieAutobusowe
    UNION
    SELECT * From linietramwajowe


