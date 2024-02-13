
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

--wstawia id kursu, które są różne dla danej lini na danym przystanku
CREATE OR REPLACE FUNCTION wstawIdKursu()
    RETURNS TRIGGER AS $$
        DECLARE rodzaj text = tg_table_name;
    BEGIN
        CASE rodzaj WHEN 'RozkladTramwaje' THEN
            DECLARE max INT = (SELECT Max(RozkladTramwaje.idkursu) FROM RozkladTramwaje
                WHERE przystanek = NEW.przystanek AND idlinii = NEW.idlinii);
            BEGIN
                UPDATE NEW SET idKursu = max + 1
                WHERE TRUE;
            END;
        ELSE
            DECLARE max INT = (SELECT Max(RozkladAutobusy.idkursu) FROM RozkladAutobusy
                WHERE przystanek = NEW.przystanek AND idlinii = NEW.idlinii);
            BEGIN
                UPDATE NEW SET idKursu = max + 1
                WHERE  True;
            END;
        END CASE;
        RETURN NEW;
    END
$$ LANGUAGE plpgsql;

--sprawdza czy zajezdnia jest czynna i czy są w niej dostępne miejsca
CREATE OR REPLACE FUNCTION sprawdzStanZajezdni()
    RETURNS TRIGGER AS $$
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
$$ LANGUAGE plpgsql;

--sprawdza czy kierowca nie jest na urlopie, czy nie jest przypisany do innego przejazdu w tym samym czasie,
--czy pojazd jest czynny oraz czy pojazd nie jest przypisany do kursu w tym samym czasie
/*
CREATE OR REPLACE FUNCTION sprawdzDostepnoscKierowcyIPojazdu()
RETURNS TRIGGER AS $$

BEGIN

END
$$

 */
 
---------------------------------------------------------------------------------------------------------------
--wyzwalacze--
---------------------------------------------------------------------------------------------------------------

--wstawiają id kursu
CREATE OR REPLACE TRIGGER tr_before_rozkladTramwaje BEFORE INSERT ON RozkladTramwaje
    FOR EACH ROW EXECUTE FUNCTION wstawidkursu();

CREATE OR REPLACE TRIGGER tr_before_rozkladAutobusy BEFORE INSERT ON RozkladAutobusy
    FOR EACH ROW EXECUTE FUNCTION wstawidkursu();

--sprawdzają czy zajezdnia jest czynna i czy są w niej miejsca
CREATE OR REPLACE TRIGGER tr_before_tramwaje BEFORE INSERT ON Tramwaje
    FOR EACH ROW EXECUTE FUNCTION sprawdzStanZajezdni();

CREATE OR REPLACE TRIGGER tr_before_autobusy BEFORE INSERT ON Autobusy
    FOR EACH ROW EXECUTE FUNCTION sprawdzStanZajezdni();

CREATE OR REPLACE TRIGGER tr_before_przejazdyTramwajowe BEFORE INSERT ON PrzejazdyTramwajowe
    EXECUTE FUNCTION sprawdzDostepnoscKierowcyIPojazdu();

CREATE OR REPLACE TRIGGER tr_before_przejazdyAutobusowe BEFORE INSERT ON PrzejazdyAutobusowe
    EXECUTE FUNCTION sprawdzDostepnoscKierowcyIPojazdu();

CREATE OR REPLACE TRIGGER tr_after_Bilety AFTER INSERT ON Bilety
    EXECUTE FUNCTION dokonajTransakcji();