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
            UPDATE RozkladTramwaje AS R SET R.idKursu = max + 1
            WHERE R.przystanek = zmienianyPrzystanek AND R.idKursu = 0
        END;
    WHEN 'Autobus' THEN
        DECLARE
            zmienianyPrzystanek VARCHAR := (
                SELECT przystanek FROM RozkladAutobusy WHERE idKursu = 0);
            max INT := (
                SELECT MAX(idKursu) FROM RozkladAutobusy WHERE przystanek = zmienianyPrzystanek);
        BEGIN
            UPDATE RozkladAutobusy AS R SET R.idKursu = max + 1
            WHERE R.przystanek = zmienianyPrzystanek AND R.idKursu = 0;
        END;
    END CASE;
END;


