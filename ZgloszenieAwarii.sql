DECLARE @przystanek VARCHAR(40)
CREATE VIEW PojazdyZastepcze AS
    SELECT A.numerPojazdu, A.zajezdnia, czasPodrozy(Z.adres, @przystanek)
    FROM Autobusy A
        JOIN ZajezdnieAutobusowe Z ON A.zajezdnia = Z.nazwa