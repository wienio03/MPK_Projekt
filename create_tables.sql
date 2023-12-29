DROP TABLE IF EXISTS Pracownicy;

CREATE TABLE Pracownicy(
    idpracownika int PRIMARY KEY,
    imie char(40),
    nazwisko char(40),
    stanowisko char(40),
    datazatrudnienia date
)


