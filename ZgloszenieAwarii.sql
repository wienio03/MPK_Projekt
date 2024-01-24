DECLARE miejsceAwarii VARCHAR;
CREATE VIEW PojazdyZastepcze AS
    SELECT A.numerPojazdu, A.zajezdnia, czasPodrozy(Z.adres, miejsceAwarii)
    FROM Autobusy A
        JOIN ZajezdnieAutobusowe Z ON A.zajezdnia = Z.nazwa