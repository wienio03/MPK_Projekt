CREATE TYPE stanPojazdu AS ENUM ('czynny', 'zepsuty', 'serwisowany' , 'wycofany');
CREATE TYPE stanMiejsca AS ENUM('czynny', 'remontowany', 'wycofany');

DROP TABLE IF EXISTS ModeleTramwajow;
CREATE TABLE ModeleTramwajow (
    model VARCHAR(40) PRIMARY KEY,
    producent VARCHAR(40) NOT NULL,
    dlugosc INT,
    szerokosc INT,
    wysokosc INT,
    rozstawOsi INT,
    masaWlasna INT,
    miejsca INT,
    miejscaSiedzace INT,
    niskopodlogowyProcent INT CHECK(niskopodlogowyProcent BETWEEN 0 AND 100),
    mocKM INT
);

DROP TABLE IF EXISTS ModeleAutobusow;
CREATE TABLE ModeleAutobusow (
    model VARCHAR(40) PRIMARY KEY,
    producent VARCHAR(40) NOT NULL,
    dlugosc INT,
    szerokosc INT,
    wysokosc INT,
    masaWlasna INT,
    miejsca INT,
    miejscaSiedzace INT,
    producentSilnika VARCHAR(40),
    pojemnoscSilnika INT,
    mocSilnikaKM INT,
    typNapedu VARCHAR(20)
);

DROP TABLE IF EXISTS Tramwaje;
CREATE TABLE Tramwaje(
    numerPojazdu VARCHAR(10) PRIMARY KEY,
    model VARCHAR(40) REFERENCES ModeleTramwajow(model) ON DELETE CASCADE,
    zajezdnia VARCHAR(50) REFERENCES ZajezdnieTramwajowe(nazwa) ON DELETE SET NULL ,
    stan stanPojazdu NOT NULL
);

DROP TABLE IF EXISTS Autobusy;
CREATE TABLE Autobusy(
    numerPojazdu VARCHAR(10) PRIMARY KEY,
    model VARCHAR(40) REFERENCES ModeleAutobusow(model) ON DELETE CASCADE ,
    zajezdnia VARCHAR(50) REFERENCES ZajezdnieAutobusowe(nazwa) ON DELETE SET NULL ,
    stan stanPojazdu NOT NULL

);

DROP TABLE IF EXISTS PrzystankiTramwajowe;
CREATE TABLE PrzystankiTramwajowe(
    nazwa VARCHAR(50) PRIMARY KEY,
    podwojny BOOLEAN NOT NULL,
    stan stanMiejsca NOT NULL
);

DROP TABLE IF EXISTS PrzystankiAutobusowe;
CREATE TABLE PrzystankiAutobusowe(
    nazwa VARCHAR(50) PRIMARY KEY,
    podwojny BOOLEAN NOT NULL,
    stan stanMiejsca NOT NULL
);

DROP TABLE IF EXISTS ZajezdnieTramwajowe;
CREATE TABLE ZajezdnieTramwajowe(
    nazwa VARCHAR(50) PRIMARY KEY,
    adres VARCHAR(50) NOT NULL UNIQUE,
    maxPojazdow INT NOT NULL,
    stan stanMiejsca NOT NULL
);

DROP TABLE IF EXISTS ZajezdnieAutobusowe;
CREATE TABLE ZajezdnieAutobusowe(
    nazwa VARCHAR(50) PRIMARY KEY,
    adres VARCHAR(50) NOT NULL UNIQUE,
    maxPojazdow INT NOT NULL,
    stan stanMiejsca NOT NULL
);

DROP TABLE IF EXISTS PetleTramwajowe;
CREATE TABLE PetleTramwajowe(
    nazwa VARCHAR(50) PRIMARY KEY,
    adres VARCHAR(50) NOT NULL UNIQUE,
    stan stanMiejsca NOT NULL
);

DROP TABLE IF EXISTS PetleAutobusowe;
CREATE TABLE PetleAutobusowe(
    nazwa VARCHAR(50) PRIMARY KEY,
    adres VARCHAR(50) NOT NULL UNIQUE,
    stan stanMiejsca NOT NULL
);

DROP SEQUENCE IF EXISTS sekwencjaLinie;
CREATE SEQUENCE sekwencjaLinie AS INT
    INCREMENT 1
    START 1
    CACHE 1;

DROP TABLE IF EXISTS LinieTramwajowe;
CREATE TABLE LinieTramwajowe(
    idLinii INT PRIMARY KEY DEFAULT nextval(sekwencjaLinie),
    numer INT,
    poczatek VARCHAR(50) REFERENCES PetleTramwajowe,
    koniec VARCHAR(50) REFERENCES PetleTramwajowe
);

DROP TABLE IF EXISTS LinieAutobusowe;
CREATE TABLE LinieAutobusowe(
    idLinii INT PRIMARY KEY DEFAULT nextval(sekwencjaLinie),
    numer INT,
    poczatek VARCHAR(50) REFERENCES PetleAutobusowe,
    koniec VARCHAR(50) REFERENCES PetleAutobusowe
);

DROP TABLE IF EXISTS PrzejazdyTramwajowe;
CREATE TABLE PrzejazdyTramwajowe(
    idPrzejazdu INT PRIMARY KEY,
    pojazd VARCHAR(10) REFERENCES Tramwaje ON DELETE SET NULL,
    idKursu INT REFERENCES RozkladTramwaje(idKursu),
    kierowca VARCHAR REFERENCES KierowcyTramwajow ON DELETE SET NULL,
    data DATE NOT NULL
);

DROP TABLE IF EXISTS PrzejazdyAutobusowe;
CREATE TABLE PrzejazdyAutobusowe(
    idPrzejazdu INT PRIMARY KEY,
    pojazd VARCHAR(10) REFERENCES Autobusy ON DELETE SET NULL ,
    idKursu INT REFERENCES RozkladAutobusy(idKursu) ON DELETE CASCADE,
    kierowca VARCHAR REFERENCES KierowcyAutobusow ON DELETE SET NULL ,
    data DATE NOT NULL
);

DROP SEQUENCE IF EXISTS sekwencjaKursy;
CREATE SEQUENCE sekwencjaKursy AS INT
    INCREMENT BY 1
    START WITH 1
    CACHE 1;

DROP TABLE IF EXISTS RozkladTramwaje;
CREATE TABLE RozkladTramwaje(
    przystanek VARCHAR(50) REFERENCES PrzystankiTramwajowe,
    linia INT REFERENCES LinieTramwajowe(numer),
    idKursu INT DEFAULT nextval(sekwencjaKursy),
    godzina TIME,
    PRIMARY KEY (przystanek, linia, idKursu)
);

DROP TABLE IF EXISTS RozkladAutobusy;
CREATE TABLE RozkladAutobusy(
    przystanek VARCHAR(50) REFERENCES PrzystankiAutobusowe,
    linia INT REFERENCES LinieAutobusowe(numer),
    idKursu INT DEFAULT nextval(sekwencjaKursy),
    godzina TIME,
    PRIMARY KEY (przystanek, linia, idKursu)
);



--dodawanie wartosci

INSERT INTO ModeleAutobusow(model, producent, dlugosc, szerokosc, wysokosc, masaWlasna, miejsca,miejscaSiedzace,
                            producentSilnika, pojemnoscSilnika, mocSilnikaKM, typNapedu)
VALUES
    ('Citaro Solo', 'Mercedes', 11950, 2550, 3076, 10860, 95, 25, 'Mercedes', 7201, 286, 'spalinowy'),
    ('Citaro', 'Mercedes', 17940, 2550, 3076, 16625, 165, 34, 'Mercedes', 11967, 354, 'spalinowy'),
    ('Urbino 18', 'Solaris', 18000, 2550, 2850, 17500, 174, 41, 'DAF', 9186 , 315, 'spalinowy'),
    ('Sancity', 'Autosan', 8550, 2420, 2630, 7200, 60, 15, 'Cummins', 4462, 205, 'spalinowy'),
    ('Urbino 12', 'Solaris', 12000, 2550,2850, 10800, 102, 29, 'DAF', 9186, 256, 'spalinowy'),
    ('Urbino 12.9 Hybrid', 'Solaris', 12900, 2550, 3100, 12100, 86, 36, 'Cummins', 6693, 338, 'hybrydowy'),
    ('Urbino 18 Hybrid', 'Solaris', 18000, 2550, 3300, 17850, 142, 43, 'Cummins', 6693,406, 'hybrydowy'),
    ('7900A Hybrid', 'Volvo', 18135, 2550, 3280, 18267, 136, 43, 'Volvo', 5132, 380, 'hybrydowy'),
    ('Urbino 18 Electric', 'Solaris', 18000, 2550, 3250, NULL, 135, 47, 'ZF', NULL, 326, 'elektryczny'),
    ('Urbino 12 Electric', 'Solaris', 12000, 2550, 3300, NULL, 99, 39, 'ZF', NULL, 340, 'elektryczny');


INSERT INTO ModeleTramwajow(model, producent, dlugosc, szerokosc, wysokosc, rozstawOsi, masaWlasna, miejsca,miejscaSiedzace,
                            niskopodlogowyProcent, mocKM)
VALUES
    ('105', 'Konstal', 13500, 2400, 3060, 1900, 16500, 120, 20, 0, 217),
    ('N8', 'MAN', 26080, 2300, 3646, 1800, 35300, 207, 46, 25, 340),
    ('NGT6', 'Bombardier', 26000, 2400, 3455, 1800, 30000, 182, 76, 65, 680),
    ('E1 + C3', 'Simmering-Graz-Pauker', 33811, 2200, 3200, 1800, 35580, 289, 61, 0, 408),
    ('GT8S', 'Duwag', 26200, 2420, 3460, 1800, 35000, 200, 51, 25, 408),
    ('EU8N', 'Rotax', 26615, 2305, 3239, 1800, 33410, 206, 48, 25, 530),
    ('NGT8', 'Bombardier', 32830, 2400, 3600, 1800, 42000, 225, 77, 68, 571),
    ('2041N Krakowiak', 'Pesa', 42830, 2400, 3600, 1800, 64036, 323, 93, 100, 845),
    ('Tango Lajkonik', 'Stadler', 33400, 2400, 3600, 1800, 46010, 221, 82, 100, 571);

INSERT INTO ZajezdnieTramwajowe(nazwa, adres, maxPojazdow, stan)
VALUES
    ('Podgórze', 'Jana Brożka 3' , 160, 'czynny'),
    ('Nowa Huta', 'Ujastek 12', 220, 'czynny'),
    ('św. Wawrzyńca', 'św. Wawrzyńca 12', 100, 'wycofany');

INSERT INTO ZajezdnieAutobusowe(nazwa, adres, maxPojazdow, stan)
VALUES
    ('Wola Duchacka', 'Walerego Sławka 10', 320, 'czynny'),
    ('Płasszów', 'Biskupińska 2', 160, 'czynny'),
    ('Bieńczyce', 'Makuszyńskiego 34', 200, 'czynny'),
    ('Czyżyny', 'Osiedle 2 Pułku Lotniczego 26', 100, 'wycofany');

--wyzwalacze
 -- jak usuwamy kierowce to przypisujemy jego przyszlym kursom nowych
