--naklada mandat na danego pasazera jesli pasażer podlega pod mandat
CREATE OR REPLACE FUNCTION nalozMandat()
    RETURNS TRIGGER AS $$
        BEGIN
            UPDATE Pasażerowie
            SET SumaMandatów = SumaMandatów + NEW.kwota
            WHERE idPasażera = NEW.idPasażera;
        END
    $$
LANGUAGE plpgsql;


--robi to samo co nalozMandat, ale nie naklada tylko umozliwia aktualizacje kolumny SumaMandatów danego pasażera, który opłacił bilet
CREATE OR REPLACE FUNCTION zaplacMandat()
    RETURNS TRIGGER AS $$
        BEGIN
            UPDATE Pasażerowie
            SET SumaMandatów = SumaMandatów - OLD.kwota
            WHERE idPasażera = OLD.idPasażera;
        END
    $$
LANGUAGE plpgsql;

--wstawia id kursu, które są różne dla danej lini na danym przystanku
CREATE OR REPLACE FUNCTION wstawIdKursu()
    RETURNS TRIGGER AS $$
        DECLARE rodzaj text = TG_ARGV[0];
    BEGIN
        CASE rodzaj WHEN 'tramwaj' THEN
            DECLARE max INT = (SELECT Max(RozkladTramwaje.idkursu) FROM RozkladTramwaje
                WHERE przystanek = NEW.przystanek AND idlinii = NEW.idlinii);
            BEGIN
                UPDATE RozkladTramwaje SET idKursu = max + 1
                WHERE idkursu = NEW.idKursu AND przystanek = NEW.przystanek AND idlinii = NEW.idlinii;
            END;
        WHEN 'autobus' THEN
            DECLARE max INT = (SELECT Max(RozkladAutobusy.idkursu) FROM RozkladAutobusy
                WHERE przystanek = NEW.przystanek AND idlinii = NEW.idlinii);
            BEGIN
                UPDATE RozkladAutobusy SET idKursu = max + 1
                WHERE idkursu = NEW.idKursu AND przystanek = NEW.przystanek AND idlinii = NEW.idlinii;
            END;
        END CASE;
    END;
$$ LANGUAGE plpgsql;

--sprawdza czy zajezdnia jest czynna i czy są w niej dostępne miejsca
CREATE OR REPLACE FUNCTION sprawdzStanZajezdni()
    RETURNS TRIGGER AS $$
        DECLARE rodzaj text = TG_ARGV[0];
                miejsca int;
                STAN varchar;
                obecne int;
    BEGIN
        CASE rodzaj WHEN 'Tramwaj' THEN
            miejsca := (SELECT maxPojazdow FROM ZajezdnieTramwajowe
                    WHERE nazwa = NEW.zajezdnia);
            stan := (SELECT stan FROM ZajezdnieTramwajowe
                    WHERE nazwa = NEW.zajezdnia);
            obecne := (SELECT COUNT(*) FROM Tramwaje
                    WHERE zajezdnia = NEW.zajezdnia);
        WHEN 'Autobus' THEN
            miejsca := (SELECT maxPojazdow FROM ZajezdnieAutobusowe
                    WHERE nazwa = NEW.zajezdnia);
            stan := (SELECT stan FROM zajezdnieautobusowe
                    WHERE nazwa = NEW.zajezdnia);
            obecne := (SELECT COUNT(*) FROM Autobusy
                    WHERE zajezdnia = NEW.zajezdnia);
        END CASE;
            IF stan <> 'czynny' THEN
                RAISE EXCEPTION 'Nie można dodać pojazdu do zajezdni, ponieważ jest nieczynna';
            ELSEIF obecne >= miejsca THEN
                RAISE EXCEPTION 'W zajezdni znajduje się już maksymalna dozwolona liczba pojazdów';
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