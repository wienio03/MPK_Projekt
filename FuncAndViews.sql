---------------------------------------------------------------------------------------------------------------
--funkcje--
---------------------------------------------------------------------------------------------------------------
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

--funkcja wypisujaca laczna sume zarobkow z biletow i kart miejskich w ciagu roku (BRUTTO)
CREATE OR REPLACE FUNCTION PokazRocznyZarobek (rokParam INT)
RETURNS INT
LANGUAGE plpgsql
AS
$$
DECLARE
    zarobekRoczny MONEY;
BEGIN
    IF rokParam NOT IN (SELECT LZ.Rok FROM LaczneZarobki LZ) THEN
        RAISE WARNING 'Ten rok nie jest określony w bazie danych.';
        RETURN 0.00;
END IF;

SELECT INTO zarobekRoczny (SumaZBiletow + SumaZKartMiejskich)
FROM LaczneZarobki LZ
WHERE LZ.Rok = rokParam;

RETURN zarobekRoczny;
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

--funkcja sprawdza czy bilet jest ważny
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
                IF czasZakupu + INTERVAL '20minutes' < obecnyCzas THEN
                    RETURN TRUE;
                END IF;
                RETURN FALSE;
            END IF;
        WHEN '60-minutowy' THEN
            IF obecnaData = dataZakupu THEN
                IF czasZakupu + INTERVAL '60 minutes' >= obecnyCzas THEN
                    RETURN TRUE;
                END IF;
            ELSEIF obecnaData = dataZakupu + INTERVAL '1 day' THEN
                IF czasZakupu + INTERVAL '60minutes' < obecnyCzas THEN
                    RETURN TRUE;
                END IF;
                RETURN FALSE;
            END IF;
        WHEN '90-minutowy' THEN
            IF obecnaData = dataZakupu THEN
                IF czasZakupu + INTERVAL '90 minutes' >= obecnyCzas THEN
                RETURN TRUE;
                END IF;
            ELSEIF obecnaData = dataZakupu + INTERVAL '1 day' THEN
                IF czasZakupu + INTERVAL '90 minutes' < obecnyCzas THEN
                    RETURN TRUE;
                END IF;
                RETURN FALSE;
            END IF;
        WHEN '24-godzinny' THEN
            IF obecnaData = dataZakupu THEN
                RETURN TRUE;
            ELSEIF obecnaData = dataZakupu + INTERVAL '1 day' THEN
                IF obecnyCzas < czasZakupu THEN
                    RETURN TRUE;
                END IF;
                RETURN FALSE;
            END IF;
        WHEN '48-godzinny' THEN
            IF obecnaData = dataZakupu THEN
                RETURN TRUE;
            ELSEIF obecnaData = dataZakupu + INTERVAL '2 days' THEN
                IF obecnyCzas < czasZakupu THEN
                    RETURN TRUE;
                END IF;
                RETURN FALSE;
            END IF;
        WHEN '72-godzinny' THEN
            IF obecnaData = dataZakupu THEN
                RETURN TRUE;
            ELSEIF obecnaData = dataZakupu + INTERVAL '3 days' THEN
                IF obecnyCzas < czasZakupu THEN
                    RETURN TRUE;
                END IF;
                RETURN FALSE;
            END IF;
        WHEN '7-dniowy' THEN
            IF obecnaData = dataZakupu THEN
                RETURN TRUE;
            ELSEIF obecnaData = dataZakupu + INTERVAL '1 day' THEN
                IF obecnyCzas < czasZakupu THEN
                    RETURN TRUE;
                END IF;
                RETURN FALSE;
            END IF;
        WHEN 'weekendowy' THEN
            IF NOT (EXTRACT(DOW FROM dataZakupu) = 0 OR EXTRACT(DOW FROM dataZakupu) = 6) THEN
                RETURN FALSE;
            END IF;
        WHEN 'miesięczny' OR 'miesięczny jedna linia' THEN
            IF obecnaData = dataZakupu THEN
                RETURN TRUE;
            ELSEIF obecnaData = dataZakupu + INTERVAL '1 month' THEN
                IF obecnyCzas < czasZakupu THEN
                    RETURN TRUE;
                END IF;
                RETURN FALSE;
            END IF;
        WHEN 'półroczny'THEN
            IF obecnaData = dataZakupu THEN
                RETURN TRUE;
            ELSEIF obecnaData = dataZakupu + INTERVAL '6 months' THEN
                IF obecnyCzas < czasZakupu THEN
                    RETURN TRUE;
                END IF;
                RETURN FALSE;
            END IF;
    END CASE;
END
$$ LANGUAGE plpgsql;

--funkcja zwracająca pojazd, w którym zajęte jest najwięcej miejsc(pojazdy)
CREATE OR REPLACE FUNCTION najbardziejZapelnionyPojazd()
    RETURNS TABLE (nazwaPojazdu VARCHAR(256), numerPojazdu VARCHAR(256), modelPojazdu VARCHAR(256))
AS $$
BEGIN
    RETURN QUERY
    WITH NajbardziejZapelniony AS (
        SELECT B.idPojazdu, COUNT(*) AS liczbaBiletow
        FROM Bilety B
        GROUP BY B.idPojazdu
        ORDER BY liczbaBiletow DESC
            LIMIT 1
    ),
         SzczegolyPojazdu AS (
             SELECT 'Autobus' AS typPojazdu, A.numerPojazdu,  A.model
             FROM Autobusy A
                      JOIN NajbardziejZapelniony NZ ON A.numerPojazdu = NZ.idPojazdu
             UNION ALL
             SELECT 'Tramwaj' AS typPojazdu, T.numeRPojazdu, T.model
             FROM Tramwaje T
                      JOIN NajbardziejZapelniony NZ ON T.numerPojazdu = NZ.idPojazdu
         )
    SELECT * FROM SzczegolyPojazdu;
END
$$ LANGUAGE plpgsql;

--funkcja zwracajaca ile zostalo w pojezdzie miejsc siedzacych
CREATE OR REPLACE FUNCTION ileZostaloMiejsc(idParam VARCHAR(256))
    RETURNS TABLE (siedzace INT, ogolnie INT)
AS $$
DECLARE
    iloscZajetych INT;
    iloscDostepnychOgolnie INT;
    iloscDostepnychSiedzacych INT;
    modelPojazdu VARCHAR(256);
BEGIN
    iloscZajetych = (SELECT COUNT(*) FROM Bilety B
                     WHERE B.idPojazdu = idParam
                     GROUP BY B.idPojazdu);

    IF EXISTS(SELECT A.numerPojazdu FROM Autobusy A
              WHERE A.numerPojazdu = idParam) THEN
        modelPojazdu = (
            SELECT A.model FROM Autobusy A
             WHERE A.numerPojazdu = idParam);
        iloscDostepnychSiedzacych = (
            SELECT MA.miejscaSiedzace FROM ModeleAutobusow MA
            WHERE MA.model = modelPojazdu);
        iloscDostepnychOgolnie = (
            SELECT MA.miejsca FROM ModeleAutobusow MA
            WHERE MA.model = modelPojazdu
            );
    ELSEIF EXISTS(SELECT T.numerPojazdu FROM Tramwaje T
                  WHERE T.numerPojazdu = idParam) THEN
            modelPojazdu = (
                SELECT T.model FROM Tramwaje T
                WHERE T.numerPojazdu = idParam);
            iloscDostepnychSiedzacych = (
                SELECT MT.miejscaSiedzace FROM ModeleTramwajow MT
                WHERE MT.model = modelPojazdu);
            iloscDostepnychOgolnie = (
                SELECT MT.miejsca FROM ModeleTramwajow MT
                WHERE MT.model = modelPojazdu
            );
    ELSE
        RAISE WARNING 'podane ID nie jest przypisane do żadnego pojazdu!';
        RETURN QUERY (SELECT 0,0) ;
    END IF;

    IF iloscZajetych >= iloscDostepnychSiedzacych THEN
        iloscDostepnychSiedzacych = 0;
    ELSE
        iloscDostepnychSiedzacych = iloscDostepnychSiedzacych - iloscZajetych;
    END IF;

    iloscDostepnychOgolnie = iloscDostepnychOgolnie - iloscZajetych;

    RETURN QUERY (SELECT iloscDostepnychSiedzacych, iloscDostepnychOgolnie);
END
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION PrzystankiNaLinii(linia INT)
RETURNS TABLE(przystanek VARCHAR(50), kolejnosc INT)
LANGUAGE plpgsql
AS
$$
BEGIN
    IF linia IN (SELECT idlinii FROM linietramwajowe) THEN
        RETURN QUERY (SELECT przystanek, RANK() OVER(ORDER BY godzina ASC) as Kolejnosc FROM rozkladtramwaje R
            WHERE linia = R.idlinii AND idkursu = (SELECT  min(idkursu) FROM rozkladtramwaje WHERE linia = R.idlinii));
    ELSEIF linia IN (SELECT idlinii FROM linieautobusowe) THEN
        RETURN QUERY (SELECT przystanek, RANK() OVER(ORDER BY godzina ASC) as Kolejnosc FROM rozkladautobusy R
            WHERE linia = R.idlinii AND idkursu = (SELECT  min(idkursu) FROM rozkladautobusy WHERE linia = R.idlinii));
    ELSE
        RETURN QUERY (SELECT 'Nie ma takiej linii', 0);
    END IF;
END
$$;
[00:45]
CREATE OR REPLACE FUNCTION PojazdyZastepcze(numerZepsutegoPojazdu VARCHAR(10))
RETURNS TABLE (numerPojazdu VARCHAR(10), zajezdnia VARCHAR(50), czasPodrozy TEXT)
LANGUAGE plpgsql
AS
$$
DECLARE
    współrzędneMiejscaAwarii VARCHAR(50);
BEGIN
    współrzędneMiejscaAwarii = LokalizacjaPojazdu(numerZepsutegoPojazdu);
    RETURN QUERY SELECT A.numerPojazdu, A.zajezdnia, czasPodrozy(Z.adres, współrzędneMiejscaAwarii)
    FROM Autobusy A
        JOIN ZajezdnieAutobusowe Z ON A.zajezdnia = Z.nazwa
    WHERE A.stan = 'czynny';
END;
$$;
[00:46]
--zwraca lokalizację pojazdu, powinna zwracać dane z systemu geolokalizacji pojazdu,
-- ale w ramach placeholdera zwraca przystanek na którym powinien być pojazd w tym momencie
CREATE OR REPLACE FUNCTION LokalizacjaPojazdu(pojazdSzukany VARCHAR(10))
RETURNS TEXT
LANGUAGE plpgsql
AS
$$
BEGIN
    IF pojazdSzukany IN (SELECT numerpojazdu FROM tramwaje) THEN
        RETURN (SELECT R.przystanek FROM rozkladtramwaje R JOIN przejazdytramwajowe P ON P.linia = R.idlinii AND P.kurs = R.idKursu
        WHERE CURRENT_DATE = P.data AND pojazdSzukany = P.pojazd
        ORDER BY current_time - R.godzina ASC
        LIMIT 1);
    ELSEIF pojazdSzukany IN (SELECT numerPojazdu FROM autobusy) THEN
        RETURN (SELECT R.przystanek FROM RozkladAutobusy R JOIN PrzejazdyAutobusowe P ON P.linia = R.idlinii AND P.kurs = R.idKursu
        WHERE CURRENT_DATE = P.data AND pojazdSzukany = P.pojazd
        ORDER BY current_time - R.godzina ASC
        LIMIT 1);
    ELSE
        RETURN 'Nie ma takiego pojazdu';
    END IF;
END;
$$;

---------------------------------------------------------------------------------------------------------------
--widoki--
---------------------------------------------------------------------------------------------------------------
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

