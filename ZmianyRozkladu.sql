CREATE OR REPLACE PROCEDURE WstawNumerOdjazdu (Rodzaj varchar)
LANGUAGE sql
BEGIN ATOMIC
    CASE Rodzaj WHEN 'Tramwaj' THEN
        DECLARE
            zmienianyPrzystanek VARCHAR := (
                SELECT przystanek FROM RozkladTramwaje WHERE idKursu = 0);
            max INT := (
                SELECT MAX(idKursu) FROM RozkladTramwaje WHERE przystanek = zmienianyPrzystanek);
        BEGIN
            SELECT * FROM NEW.RozkladTramwaje;
            UPDATE RozkladTramwaje AS R SET R.idKursu = max + 1
            WHERE R.przystanek = zmienianyPrzystanek AND R.idKursu = 0
        END;
    WHEN 'Autobus' THEN
        DECLARE
            zmienianyPrzystanek VARCHAR := (
                SELECT przystanek FROM RozkladAutobusy WHERE idKursu = 0);
            zmienianaLinia varchar := (
                SELECT linia FROM RozkladAutobusy WHERE idKursu = 0);
            max INT := (
                SELECT MAX(idKursu) FROM RozkladAutobusy
                WHERE przystanek = zmienianyPrzystanek AND linia = zmienianaLinia);
        BEGIN
            UPDATE RozkladAutobusy AS R SET R.idKursu = max + 1
            WHERE R.przystanek = zmienianyPrzystanek AND R.idKursu = 0;
        END;
    END CASE;
END;

--przerobic na funkcje triggeru
