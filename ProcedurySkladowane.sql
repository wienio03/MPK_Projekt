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


--sprawdza czy kierowca nie jest na urlopie, czy nie jest przypisany do innego przejazdu w tym samym czasie,
--czy pojazd jest czynny oraz czy pojazd nie jest przypisany do kursu w tym samym czasie




CREATE OR REPLACE FUNCTION sprawdzDostepnoscKierowcyIPojazdu()
RETURNS TRIGGER AS $$
DECLARE
    urlop bool = CASE tg_table_name
        WHEN 'PrzejazdyAutobusowe' THEN EXISTS (SELECT Z.idzwolnienia FROM zwolnienia Z JOIN kierowcyautobusow K ON K.idpracownika = Z.idpracownika
            WHERE NEW.kierowca = K.idlicencji AND CURRENT_DATE BETWEEN Z.datarozpoczecia AND Z.datazakonczenia)
        ELSE EXISTS (SELECT Z.idzwolnienia FROM zwolnienia Z JOIN KierowcyTramwajow K ON K.idpracownika = Z.idpracownika
            WHERE NEW.kierowca = K.idlicencji AND CURRENT_DATE BETWEEN Z.datarozpoczecia AND Z.datazakonczenia)
        END;
    stan stanpojazdu = CASE tg_table_name
        WHEN 'PrzejazdyAutobusowe' THEN (SELECT stan FROM autobusy WHERE numerpojazdu = NEW.pojazd)
        ELSE (SELECT stan FROM tramwaje WHERE numerpojazdu = NEW.pojazd)
        END;
    czyKierowcaDostepny = (

BEGIN
    IF urlop = TRUE THEN
        RAISE WARNING 'Kierowca przypisany do kursu % % % jest na urlopie.', NEW.linia, NEW.data, NEW.godzina;
        RETURN NULL;
    ELSEIF stan <> 'czynny' THEN
        RAISE WARNING 'Autobus przypisany do kursu % % % nie jest gotowy do użytku.', NEW.linia, NEW.data, NEW.godzina;
        RETURN NULL;
end if;

END
$$
