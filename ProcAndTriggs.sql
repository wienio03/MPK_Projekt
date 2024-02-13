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



--dwie nastepne procedury sprawdzaja czy kierowca lub pojazd sa dostepni
CREATE OR REPLACE FUNCTION sprawdzDostepnoscPojazdu()
RETURNS TRIGGER
AS $$
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
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sprawdzDostepnoscKierowcy()
RETURNS TRIGGER AS $$
DECLARE
    urlop BOOLEAN;
    innyKurs BOOLEAN;
    ktoraLinia INT;
    ktoryKurs INT;
    godzinaPoczatek TIME;
    godzinaKoniec TIME;
    przystanekPoczatek VARCHAR(256);
    przystanekKoniec VARCHAR(256);
BEGIN
    CASE tg_table_name
        WHEN 'PrzejazdyAutobusowe' THEN
            IF EXISTS (SELECT Z.idzwolnienia FROM zwolnienia Z JOIN kierowcyautobusow K ON K.idpracownika = Z.idpracownika
            WHERE NEW.kierowca = K.idlicencji AND NEW.data BETWEEN Z.datarozpoczecia AND Z.datazakonczenia) THEN
                urlop = TRUE;

            ELSE

            IF NOT EXISTS (SELECT PA.kierowca FROM PrzejazdyAutobusowe PA
                        WHERE PA.data = NEW.data AND PA.kierowca = NEW.kierowca) THEN
                innyKurs = false;
            ELSE
                ktoraLinia = (
                            SELECT PA.linia FROM PrzejazdyAutobusowe PA
                            WHERE PA.kierowca = NEW.kierowca
                            );
                ktoryKurs = (
                            SELECT PA.kurs FROM PrzejazdyAutobusowe PA
                            WHERE PA.kurs = NEW.kurs
                            );
                godzinaPoczatek = (
                            SELECT RA.godzina FROM RozkladAutobusy RA
                            WHERE RA.idKursu = ktoryKurs AND idLinii = ktoraLinia
                            HAVING RA.godzina = MIN(RA.godzina)
                            );
                godzinaKoniec = (
                    SELECT RA.godzina FROM RozkladAutobusy RA
                    WHERE RA.idKursu = ktoryKurs AND idLinii = ktoraLinia
                    HAVING RA.godzina = MAX(RA.godzina)
                );
                przystanekPoczatek = (
                                         SELECT RA.przystanek FROM RozkladAutobusy RA
                                         WHERE RA.idKursu = ktoryKurs AND idLinii = ktoraLinia
                                         HAVING RA.godzina = MAX(RA.godzina)
                );
                przystanekKoniec = (
                SELECT RA.godzina FROM RozkladAutobusy RA
                WHERE RA.idKursu = ktoryKurs AND idLinii = ktoraLinia
                HAVING RA.godzina = MAX(RA.godzina)
                );

                IF godzinaKoniec - godzinaPoczatek < INTERVAL '45 minutes' AND przystanekKoniec <> ( SELECT RA.przystanek FROM RozkladAutobusy RA
                                                                                                    WHERE RA.idKursu = NEW.idKursu AND RA.idLinii = NEW.idLinii
                                                                                                    HAVING RA.godzina = MAX(RA.godzina)
                                                                                                    )
                THEN
                    innyKurs = TRUE;

                ELSEIF NOT (SELECT RA.godzina FROM RozkladAutobusy RA
                                    WHERE RA.idKursu = NEW.idKursu AND RA.idLinii = NEW.idLinii
                                    HAVING RA.godzina = MAX(RA.godzina)) - godzinaKoniec < INTERVAL '10 minutes' AND przystanekKoniec = (
                                                                                                                                        SELECT RA.przystanek FROM RozkladAutobusy RA
                                                                                                                                        WHERE RA.idKursu = NEW.idKursu AND RA.idLinii = NEW.idLinii
                                                                                                                                        HAVING RA.godzina = MAX(RA.godzina)
                                                                                                                                        ) THEN
                innyKurs = TRUE;

                END IF;
            END IF;
        END IF;
        WHEN 'PrzejazdyTramwajowe' THEN
            IF EXISTS (SELECT Z.idzwolnienia FROM zwolnienia Z JOIN KierowcyTramwajow K ON K.idpracownika = Z.idpracownika
            WHERE NEW.kierowca = K.idlicencji AND NEW.data BETWEEN Z.datarozpoczecia AND Z.datazakonczenia) THEN
                urlop = TRUE;
            ELSE
                IF NOT EXISTS (SELECT PT.kierowca FROM PrzejazdyTramwajowe PT
                               WHERE PT.data = NEW.data AND PT.kierowca = NEW.kierowca) THEN
                    innyKurs = false;
                ELSE
                    ktoraLinia = (
                        SELECT PT.linia FROM PrzejazdyTramwajowe PT
                        WHERE PT.kierowca = NEW.kierowca
                    );
                    ktoryKurs = (
                        SELECT PT.kurs FROM PrzejazdyTramwajowe PT
                        WHERE PT.kurs = NEW.kurs
                    );
                    godzinaPoczatek = (
                        SELECT RT.godzina FROM RozkladTramwaje RT
                        WHERE RT.idKursu = ktoryKurs AND idLinii = ktoraLinia
                        HAVING RT.godzina = MIN(RT.godzina)
                    );
                    godzinaKoniec = (
                        SELECT RT.godzina FROM RozkladTramwaje RT
                        WHERE RT.idKursu = ktoryKurs AND idLinii = ktoraLinia
                        HAVING RT.godzina = MAX(RT.godzina)
                    );
                    przystanekPoczatek = (
                        SELECT RT.przystanek FROM RozkladTramwaje RT
                        WHERE RT.idKursu = ktoryKurs AND idLinii = ktoraLinia
                        HAVING RT.godzina = MAX(RT.godzina)
                    );
                    przystanekKoniec = (
                        SELECT RT.godzina FROM RozkladTramwaje RT
                        WHERE RT.idKursu = ktoryKurs AND idLinii = ktoraLinia
                        HAVING RT.godzina = MAX(RT.godzina)
                    );

                    IF godzinaKoniec - godzinaPoczatek < INTERVAL '45 minutes' AND przystanekKoniec <> ( SELECT RT.przystanek FROM RozkladTramwaje RT
                                                                                                         WHERE RT.idKursu = NEW.idKursu AND RT.idLinii = NEW.idLinii
                                                                                                         HAVING RT.godzina = MAX(RT.godzina)
                    )
                    THEN
                        innyKurs = TRUE;

                    ELSEIF NOT (SELECT RT.godzina FROM RozkladTramwaje RT
                                WHERE RT.idKursu = NEW.idKursu AND RT.idLinii = NEW.idLinii
                                HAVING RT.godzina = MAX(RT.godzina)) - godzinaKoniec < INTERVAL '10 minutes' AND przystanekKoniec = (
                        SELECT RT.przystanek FROM RozkladTramwaje RT
                        WHERE RT.idKursu = NEW.idKursu AND RT.idLinii = NEW.idLinii
                        HAVING RT.godzina = MAX(RT.godzina)
                    ) THEN
                        innyKurs = TRUE;

                    END IF;
                END IF;
            END IF;
    END CASE;
    IF urlop = TRUE THEN
        RAISE WARNING 'Kierowca % przypisany do kursu % % % jest na urlopie.', NEW.kierowca,NEW.linia, NEW.data, NEW.godzina;
        RETURN NULL;
    END IF;

    IF innyKurs = TRUE THEN
        RAISE WARNING 'Kierowca % ma przypisany inny kurs, z którego nie zdąży wrócić', NEW.kierowca;
        RETURN NULL;
    end if;

    RETURN NEW;
END
$$ LANGUAGE plpgsql;


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

---------------------------------------------------------------------------------------------------------------
--wyzwalacze--
---------------------------------------------------------------------------------------------------------------

--sprawdzają czy zajezdnia jest czynna i czy są w niej miejsca
CREATE OR REPLACE TRIGGER tr_before_tramwaje BEFORE INSERT ON Tramwaje
    FOR EACH ROW EXECUTE FUNCTION sprawdzStanZajezdni();

CREATE OR REPLACE TRIGGER tr_before_autobusy BEFORE INSERT ON Autobusy
    FOR EACH ROW EXECUTE FUNCTION sprawdzStanZajezdni();

CREATE OR REPLACE TRIGGER tr_before_przejazdyTramwajowe BEFORE INSERT ON PrzejazdyTramwajowe
    EXECUTE FUNCTION sprawdzDostepnoscKierowcyIPojazdu();

CREATE OR REPLACE TRIGGER tr_before_Przejazdy BEFORE INSERT ON PrzejazdyAutobusowe
    EXECUTE FUNCTION sprawdzDostepnoscKierowcyIPojazdu();

CREATE OR REPLACE TRIGGER tr_after_Bilety AFTER INSERT ON Bilety
    EXECUTE FUNCTION kupBilet();

CREATE OR REPLACE TRIGGER tr_after_Transakcje AFTER INSERT ON TransakcjeKartyMiejskie
    EXECUTE FUNCTION doladujKarte();

