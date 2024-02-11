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
    SELECT * From linietramwajowe;

--sprawdza czy bilet jest ważny
CREATE OR REPLACE FUNCTION czyWazny(idSprawdzane INT)
RETURNS BOOLEAN
AS
$$
DECLARE
    czasTrwania VARCHAR(256);
    obecnyCzas TIME;
    obecnaData DATE;
    dataZakupu DATE;
    czasZakupu TIME;
BEGIN
    obecnaData = CURRENT_DATE;
    obecnyCzas = CURRENT_TIME;
    czasTrwania = (
        SELECT B.okres FROM Bilety B
        WHERE B.idBiletu = idSprawdzane
        );
    dataZakupu = (
        SELECT B.dataWydania FROM Bilety B
        WHERE B.idBiletu = idSprawdzane
        );
    czasZakupu = (
        SELECT B.czasWydania FROM Bilety B
        WHERE B.idBiletu = idSprawdzane
        );
    CASE czasTrwania
        WHEN '20-minutowy' THEN
            IF obecnaData = dataZakupu THEN
                IF czasZakupu + INTERVAL '20 minutes' >= obecnyCzas THEN
                    RETURN TRUE;
                END IF;
            ELSEIF obecnaData = dataZakupu + INTERVAL '1 day' THEN
                IF czasZakupu + INTERVAL '20minutes' > obecnyCzas THEN
                    RETURN TRUE;
                END IF;
            END IF;
        WHEN '60-minutowy' THEN
            IF obecnaData = dataZakupu THEN
                IF czasZakupu + INTERVAL '60 minutes' >= obecnyCzas THEN
                    RETURN TRUE;
                END IF;
            ELSEIF obecnaData = dataZakupu + INTERVAL '1 day' THEN
                IF czasZakupu + INTERVAL '60minutes' > obecnyCzas THEN
                    RETURN TRUE;
                END IF;
            END IF;
        WHEN '90-minutowy' THEN
            IF obecnaData = dataZakupu THEN
                IF czasZakupu + INTERVAL '90 minutes' >= obecnyCzas THEN
                    RETURN TRUE;
                END IF;
            ELSEIF obecnaData = dataZakupu + INTERVAL '1 day' THEN
                IF czasZakupu + INTERVAL '90 minutes' > obecnyCzas THEN
                    RETURN TRUE;
                END IF;
            END IF;
        WHEN '24-godzinny' THEN
            IF obecnaData = dataZakupu THEN
                    RETURN TRUE;
            ELSEIF obecnaData = dataZakupu + INTERVAL '1 day' THEN
                IF czasZakupu + INTERVAL '24 hours' > obecnyCzas THEN
                    RETURN TRUE;
                END IF;
            END IF;
        WHEN '48-godzinny' THEN
        WHEN '72-godzinny' THEN
        WHEN '7-dniowy' THEN
        WHEN 'weekendowy' THEN
        WHEN 'miesięczny' OR 'miesięczny jedna linia' THEN
        WHEN 'półroczny'THEN
    END CASE;
END;
$$ LANGUAGE plpgsql;

