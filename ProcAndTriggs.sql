---------------------------------------------------------------------------------------------------------------
--procedury--
---------------------------------------------------------------------------------------------------------------

--procedury odpowiadajace za doladowanie salda karty lub pobrania adekwatnej kwoty przy kupnie biletu
CREATE OR REPLACE FUNCTION doladujKarte()
    RETURNS TRIGGER AS $$
        DECLARE obecneSaldo INT;
    BEGIN
        obecneSaldo = (
                       SELECT KM.saldo FROM KartyMiejskie KM
                        WHERE KM.idKarty = NEW.idKarty);
        IF NEW.rodzaj = 'doladowanie' THEN
            UPDATE KartyMiejskie
            SET saldo = obecneSaldo + NEW.kwota
            WHERE KartyMiejskie.idKarty = NEW.idKarty;
        END IF;
    END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION kupBilet()
    RETURNS TRIGGER AS $$
        DECLARE obecneSaldo INT;
    BEGIN
        IF NEW.platnosc = 'karta miejska' THEN
            obecneSaldo = (SELECT KM.saldo FROM KartyMiejskie KM
                           WHERE KM.idKlienta = NEW.idKlienta);

            IF obecneSaldo < NEW.cena THEN
                RAISE EXCEPTION 'Zbyt mało na koncie! Wybierz inną metode płatności';
            END IF;

            UPDATE KartyMiejskie
            SET saldo = obecneSaldo - NEW.cena
            WHERE KartyMiejskie.idKlienta = NEW.idKlienta;

        ELSE
            RAISE WARNING 'Płatność dokonana poprzez kasownik';
        END IF;
    END;
$$ LANGUAGE plpgsql;


--sprawdza czy zajezdnia jest czynna i czy są w niej dostępne miejsca
CREATE OR REPLACE FUNCTION sprawdzStanZajezdni()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
    DECLARE rodzaj text = tg_table_name;
                miejsca int;
                stanZajezdni varchar;
                obecne int;
    BEGIN
        CASE rodzaj WHEN 'Tramwaje' THEN
            miejsca := (SELECT maxPojazdow FROM ZajezdnieTramwajowe
                    WHERE nazwa = NEW.zajezdnia);
            stanZajezdni := (SELECT stan FROM ZajezdnieTramwajowe
                    WHERE nazwa = NEW.zajezdnia);
            obecne := (SELECT COUNT(*) FROM Tramwaje
                    WHERE zajezdnia = NEW.zajezdnia);
        ELSE
            miejsca := (SELECT maxPojazdow FROM ZajezdnieAutobusowe
                    WHERE nazwa = NEW.zajezdnia);
            stanZajezdni := (SELECT stan FROM zajezdnieautobusowe
                    WHERE nazwa = NEW.zajezdnia);
            obecne := (SELECT COUNT(*) FROM Autobusy
                    WHERE zajezdnia = NEW.zajezdnia);
        END CASE;
            IF stanZajezdni <> 'czynny' THEN
                RAISE WARNING 'Nie można dodać pojazdu % do zajezdni %, ponieważ jest nieczynna', NEW.numerpojazdu, NEW.zajezdnia;
                RETURN NULL;
            ELSEIF obecne >= miejsca THEN
                RAISE WARNING 'Nie można dodać pojazdu % ,ponieważ w zajezdni % znajduje się już maksymalna dozwolona liczba pojazdów', NEW.numerpojazdu, NEW.zajezdnia;
                RETURN NULL;
            ELSE
                RETURN NEW;
            END IF;
    END
$$;

CREATE OR REPLACE PROCEDURE UsunPrzejazdySprzed90Dni()
LANGUAGE plpgsql AS
$$
BEGIN
    START TRANSACTION;
        DELETE FROM PrzejazdyTramwajowe
        WHERE CURRENT_DATE - przejazdytramwajowe.data > 90;
    COMMIT;

    START TRANSACTION;
        DELETE FROM przejazdyautobusowe
        WHERE CURRENT_DATE - przejazdyautobusowe.data > 90;
    COMMIT;
END;
$$;



--sprawdza czy pojazd jest czynny oraz czy pojazd nie jest przypisany do kursu w tym samym czasie
CREATE OR REPLACE FUNCTION sprawdzDostepnoscPojazdu()
RETURNS TRIGGER
LANGUAGE plpgsql AS
$$
DECLARE
    czynnosc BOOL;
    dostepnosc BOOL;
BEGIN
    czynnosc =  CASE tg_table_name
                    WHEN 'PrzejazdyAutobusowe'
                        THEN New.numerPojazdu IN (SELECT autobusy.numerpojazdu FROM autobusy WHERE stan ='czynny')
                    ELSE
                        New.numerPojazdu IN (SELECT tramwaje.numerpojazdu FROM tramwaje WHERE stan ='czynny')
                END;
    dostepnosc = CASE tg_table_name
                    WHEN 'PrzejazdyAutobusowe' THEN
                        CASE
                            WHEN NOT EXISTS (SELECT kurs FROM przejazdyautobusowe P WHERE data = NEW.data AND pojazd = NEW.pojazd AND
                                    45 <= (SELECT MIN(godzina) FROM rozkladautobusy R WHERE R.idkursu = P.kurs AND R.idlinii = P.linia )
                                             - (SELECT MAX(godzina) FROM rozkladautobusy R WHERE R.idkursu = NEW.kurs AND R.idlinii = NEW.linia))
                                THEN TRUE
                            WHEN NOT EXISTS (SELECT kurs FROM przejazdyautobusowe P WHERE data = NEW.data AND pojazd = NEW.pojazd AND
                                (SELECT koniec FROM linieautobusowe WHERE idlinii = P.linia) <> (SELECT poczatek FROM linieautobusowe WHERE idlinii = NEW.idLinii) AND
                                    (SELECT MIN(godzina) FROM rozkladautobusy R WHERE R.idkursu = P.kurs AND R.idlinii = P.linia )
                                             - (SELECT MAX(godzina) FROM rozkladautobusy R WHERE R.idkursu = NEW.kurs AND R.idlinii = NEW.linia) BETWEEN 10 AND 45)
                                THEN TRUE
                            WHEN NOT EXISTS (SELECT kurs FROM przejazdyautobusowe P WHERE data = NEW.data AND pojazd = NEW.pojazd AND
                                    10 <= (SELECT MIN(godzina) FROM rozkladautobusy R WHERE R.idkursu = P.kurs AND R.idlinii = P.linia )
                                             - (SELECT MAX(godzina) FROM rozkladautobusy R WHERE R.idkursu = NEW.kurs AND R.idlinii = NEW.linia))
                                THEN TRUE
                            ELSE
                                FALSE
                        END
                    ELSE
                        CASE
                            WHEN NOT EXISTS (SELECT kurs FROM przejazdytramwajowe P WHERE data = NEW.data AND pojazd = NEW.pojazd AND
                                    45 <= (SELECT MIN(godzina) FROM rozkladtramwaje R WHERE R.idkursu = P.kurs AND R.idlinii = P.linia )
                                             - (SELECT MAX(godzina) FROM rozkladtramwaje R WHERE R.idkursu = NEW.kurs AND R.idlinii = NEW.linia))
                                THEN TRUE
                            WHEN NOT EXISTS (SELECT kurs FROM przejazdytramwajowe P WHERE data = NEW.data AND pojazd = NEW.pojazd AND
                                (SELECT koniec FROM linietramwajowe WHERE idlinii = P.linia) <> (SELECT poczatek FROM linietramwajowe WHERE idlinii = NEW.idLinii) AND
                                    (SELECT MIN(godzina) FROM rozkladtramwaje R WHERE R.idkursu = P.kurs AND R.idlinii = P.linia )
                                             - (SELECT MAX(godzina) FROM rozkladtramwaje R WHERE R.idkursu = NEW.kurs AND R.idlinii = NEW.linia) BETWEEN 10 AND 45)
                                THEN TRUE
                            WHEN NOT EXISTS (SELECT kurs FROM przejazdytramwajowe P WHERE data = NEW.data AND pojazd = NEW.pojazd AND
                                    10 <= (SELECT MIN(godzina) FROM rozkladtramwaje R WHERE R.idkursu = P.kurs AND R.idlinii = P.linia )
                                             - (SELECT MAX(godzina) FROM rozkladtramwaje R WHERE R.idkursu = NEW.kurs AND R.idlinii = NEW.linia))
                                THEN TRUE
                            ELSE
                                FALSE
                        END
                    END;
    CASE
        WHEN czynnosc = FALSE
            THEN
                RAISE WARNING 'Pojazd % nie jest czynny', NEW.pojazd;
                RETURN NULL;
        WHEN dostepnosc = FALSE
            THEN
                RAISE WARNING 'Pojazd % ma przypisany inny kurs, z którego nie zdąży wrócić', NEW.pojazd;
                RETURN NULL;
        ELSE
            RETURN NEW;
    END CASE;
END
$$;

--sprawdza czy istnieje taki pojazd
CREATE OR REPLACE FUNCTION sprawdzPoprawnoscPojazdu()
RETURNS TRIGGER AS
$$
BEGIN
    IF EXISTS(SELECT numerpojazdu FROM Autobusy WHERE numerpojazdu = NEW.numerPojazdu AND stan = 'czynny')
           OR EXISTS (SELECT numerPojazdu FROM Tramwaje WHERE numerpojazdu = NEW.numerPojazdu AND stan = 'czynny') THEN
        RETURN NEW;
    ELSE
        RAISE WARNING 'Nie istnieje pojazd %, dla którego dodano bilet %', NEW.numerPojazdu, NEW.idBiletu;
        RETURN NULL;
    END IF;
END;
$$;
--sprawdza czy istnieje taka para (linia, kurs)
CREATE OR REPLACE FUNCTION sprawdzIstnienieLiniiIKursu()
RETURNS TRIGGER
LANGUAGE plpgsql AS
$$
DECLARE
    istnienie BOOL;
BEGIN
    istnienie = CASE tg_table_name
        WHEN 'PrzejazdyAutobusowe'
            THEN (NEW.linia, NEW.kurs) IN (SELECT idlinii, idKursu FROM rozkladautobusy)
        ELSE
            (NEW.linia, NEW.kurs) IN (SELECT idlinii, idKursu FROM rozkladautobusy)
        END;
    IF istnienie = TRUE
        THEN RETURN new;
    ELSE
        RAISE WARNING 'Nie istnieje kurs % obsługujący linię %.', NEW.kurs, NEW.linia;
        RETURN NULL;
    END IF;
END
$$;

---------------------------------------------------------------------------------------------------------------
--wyzwalacze--
---------------------------------------------------------------------------------------------------------------

--sprawdzają czy zajezdnia jest czynna i czy są w niej miejsca
CREATE OR REPLACE TRIGGER tr_before_tramwaje BEFORE INSERT ON Tramwaje
    FOR EACH ROW EXECUTE FUNCTION sprawdzStanZajezdni();

CREATE OR REPLACE TRIGGER tr_before_autobusy BEFORE INSERT ON Autobusy
    FOR EACH ROW EXECUTE FUNCTION sprawdzStanZajezdni();

--sprawdzają czy pojazd jest czynny, oraz czy nie ma innego kursu który kończy się mniej niż 10 minut wcześniej na tej samej pętli, lub mniej niż 45 minut wcześniej na innej
CREATE OR REPLACE TRIGGER tr_before_przejazdyTramwajowe BEFORE INSERT ON PrzejazdyTramwajowe
    EXECUTE FUNCTION sprawdzDostepnoscPojazdu();

CREATE OR REPLACE TRIGGER tr_before_przejazdyAutobusowe BEFORE INSERT ON PrzejazdyAutobusowe
    EXECUTE FUNCTION sprawdzDostepnoscPojazdu();

--sprawdzają czy kierowca nie jest na urlopie, oraz czy nie ma innego kursu, który kończy się mniej niż 10 minut wcześniej na tej samej pętli, lub mniej niż 45 minut wcześniej na innej
CREATE OR REPLACE TRIGGER tr_before_insert_przejazdyTramwajowe BEFORE INSERT ON PrzejazdyTramwajowe
    EXECUTE FUNCTION sprawdzDostepnoscKierowcy();

CREATE OR REPLACE TRIGGER tr_before_insert_przejazdyAutobusowe BEFORE INSERT ON PrzejazdyAutobusowe
    EXECUTE FUNCTION sprawdzDostepnoscKierowcy();

--sprawdzają czy istnieje taka para (linia, kurs)
CREATE OR REPLACE TRIGGER tr_before_insert_przejazdyTramwajowe2 BEFORE INSERT ON PrzejazdyTramwajowe
    EXECUTE FUNCTION sprawdzIstnienieLiniiIKursu();

CREATE OR REPLACE TRIGGER tr_before_insert_przejazdyAutobusowe2 BEFORE INSERT ON PrzejazdyAutobusowe
    EXECUTE FUNCTION sprawdzIstnienieLiniiIKursu();

