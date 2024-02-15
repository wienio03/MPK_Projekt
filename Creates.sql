DROP DATABASE IF EXISTS MPK;
CREATE DATABASE MPK WITH
    locale='Polish_Poland';

---------------------------------------------------------------------------------------------------------------
--typy i sekwencje--
---------------------------------------------------------------------------------------------------------------

DROP TYPE IF EXISTS statusPracownika CASCADE;
CREATE TYPE statusPracownika AS ENUM ('zwolnienie', 'aktywny', 'urlop');

DROP TYPE IF EXISTS tryb CASCADE;
CREATE TYPE tryb AS ENUM ( 'stacjonarnie', 'hybrydowe', 'zdalnie');

DROP TYPE IF EXISTS typZwolnienia CASCADE;
CREATE TYPE typZwolnienia AS ENUM ('chorobowe', 'urlop bezpłatny', 'urlop płatny');

DROP TYPE IF EXISTS statusZwolnienia CASCADE;
CREATE TYPE statusZwolnienia AS ENUM ('zakończone', 'w trakcie');

DROP TYPE IF EXISTS typBiletu CASCADE;
CREATE TYPE typBiletu AS ENUM ('do kasowania', 'metropolitalny', 'mieszkanca',
    'socjalny', 'bezrobotny', 'firmowy');

DROP TYPE IF EXISTS czyUlgowy CASCADE;
CREATE TYPE czyUlgowy AS ENUM ('tak', 'nie');

DROP TYPE IF EXISTS zasiegBiletu CASCADE;
CREATE TYPE zasiegBiletu AS ENUM ('I', 'II', 'III', 'I+II', 'II+III',
    'I+II+III');

DROP TYPE IF EXISTS okresBiletu CASCADE;
CREATE TYPE okresBiletu AS ENUM ('20-minutowy', '60-minutowy',
    '90-minutowy', '24-godzinny', '48-godzinny', '72-godzinny',
    '7-dniowy', 'weekendowy', 'miesięczny', 'miesięczny 1 linia',
    'półroczny'
    );

DROP TYPE IF EXISTS metodaPlatnosci CASCADE;
CREATE TYPE metodaPlatnosci AS ENUM('karta', 'gotowka', 'przelew blik', 'karta miejska');

DROP TYPE IF EXISTS statusKlienta CASCADE;
CREATE TYPE statusKlienta AS ENUM ('aktywny', 'nieaktywny', 'zablokowany');

DROP TYPE IF EXISTS statusZnizki CASCADE;
CREATE TYPE statusZnizki AS ENUM ('obowiazuje', 'nieobowiazuje');

DROP TYPE IF EXISTS typKarty CASCADE;
CREATE TYPE typKarty AS ENUM ('legitymacja studencka/doktorska',
    'standardowa', 'senior');

DROP TYPE IF EXISTS statusKarty CASCADE;
CREATE TYPE statusKarty AS ENUM ('aktywna', 'zawieszona', 'wygasla');

DROP TYPE IF EXISTS typTransakcji CASCADE;
CREATE TYPE typTransakcji AS ENUM ('doładowanie', 'kupno');

DROP TYPE IF EXISTS stanPojazdu CASCADE;
CREATE TYPE stanPojazdu AS ENUM ('czynny', 'zepsuty', 'serwisowany' , 'wycofany');

DROP TYPE IF EXISTS stanMiejsca CASCADE;
CREATE TYPE stanMiejsca AS ENUM('czynny', 'remontowany', 'wycofany');

DROP TYPE IF EXISTS typLinii CASCADE;
CREATE TYPE typLinii AS ENUM('zwykla', 'nocna', 'aglomeracyjna', 'zastepdza');

DROP TYPE IF EXISTS kwotaMandatu CASCADE;
CREATE TYPE kwotaMandatu AS ENUM('150', '240', '510');

DROP TYPE IF EXISTS opisMandatu CASCADE;
CREATE TYPE opisMandatu AS ENUM ('spowodowanie zatrzymania bez uzasadnionej przyczyny',
    'naruszenie przepisów o przewozie zwierząt', 'nieważny dokument uprawniający do ulgi',
    'niewazny dokument uprawniający do przejazdu darmowego');


DROP SEQUENCE IF EXISTS sekwencjaLinie CASCADE;
CREATE SEQUENCE sekwencjaLinie AS INT
    INCREMENT 1
    START 1
    CACHE 1;

---------------------------------------------------------------------------------------------------------------
--tabele--
---------------------------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS Pracownicy CASCADE;
CREATE TABLE Pracownicy (
  idPracownika INT PRIMARY KEY,
  imie VARCHAR(40) NOT NULL,
  nazwisko VARCHAR(40) NOT NULL,
  dataUrodzenia date NOT NULL,
  stanowisko VARCHAR(40) NOT NULL,
  dataZatrudnienia DATE NOT NULL,
  statusZatrudnienia statusPracownika NOT NULL,
  numerTelefonu VARCHAR(12) NOT NULL,
  numerPESEL VARCHAR(11) NOT NULL,
  adresZamieszkania VARCHAR(80) NOT NULL,
  idPrzelozonego INT DEFAULT NULL
);

DROP TABLE IF EXISTS UmowyPracownikow;
CREATE TABLE UmowyPracownikow (
 idUmowy INT NOT NULL ,
 idPracownika INT REFERENCES Pracownicy(idPracownika) ON DELETE CASCADE,
 dataRozpoczecia DATE NOT NULL,
 typUmowy VARCHAR(20) NOT NULL,
 okresTrwania INT NOT NULL,
 wynagrodzenieBrutto MONEY NOT NULL,
 trybPracy tryb NOT NULL
);

DROP TABLE IF EXISTS KierowcyAutobusow CASCADE;
CREATE TABLE KierowcyAutobusow (
 idLicencji VARCHAR(20) PRIMARY KEY,
 idPracownika INT REFERENCES Pracownicy(idPracownika) ON DELETE CASCADE,
 licencjaOd DATE NOT NULL,
 licencjaDo DATE NOT NULL
);

DROP TABLE IF EXISTS KierowcyTramwajow CASCADE;
CREATE TABLE KierowcyTramwajow (
 idLicencji VARCHAR(10) PRIMARY KEY,
 idPracownika INT REFERENCES Pracownicy(idPracownika) ON DELETE CASCADE,
 licencjaOd DATE NOT NULL,
 licencjaDo DATE NOT NULL
);

DROP TABLE IF EXISTS Zwolnienia;
CREATE TABLE Zwolnienia (
 idZwolnienia INT PRIMARY KEY,
 idPracownika INT REFERENCES Pracownicy(idPracownika) ON DELETE CASCADE,
 dataRozpoczecia DATE NOT NULL,
 dataZakonczenia DATE NOT NULL,
 typ typZwolnienia NOT NULL,
 stanZwolnienia statusZwolnienia NOT NULL
);

DROP TABLE IF EXISTS Klienci CASCADE;
CREATE TABLE Klienci (
 idKlienta INT PRIMARY KEY ,
 imie VARCHAR(40) NOT NULL,
 nazwisko VARCHAR(40) NOT NULL,
 dataUrodzenia DATE NOT NULL,
 email varChar(80) DEFAULT NULL,
 numerTelefonu varChar(12) NOT NULL,
 adresZamieszkania varChar(80) NOT NULL,
 dataRejestracji DATE NOT NULL,
 stanKlienta statusKlienta NOT NULL,
 znizka statusZnizki NOT NULL
);


DROP TABLE IF EXISTS KartyMiejskie CASCADE;
CREATE TABLE KartyMiejskie (
 idKarty INT PRIMARY KEY,
 idKlienta INT REFERENCES Klienci(idKlienta) ON DELETE CASCADE,
 numerKarty INT NOT NULL,
 typ typKarty NOT NULL,
 dataWydania DATE NOT NULL,
 waznaOd DATE NOT NULL,
 waznaDo DATE NOT NULL,
 stanKarty statusKarty NOT NULL,
 saldo MONEY DEFAULT 0.00
);


DROP TABLE IF EXISTS Bilety CASCADE;
CREATE TABLE Bilety (
 idBiletu INT PRIMARY KEY ,
 typ typBiletu NOT NULL,
 ulgowy czyUlgowy NOT NULL,
 zasieg zasiegBiletu NOT NULL,
 okres okresBiletu NOT NULL,
 idPojazdu VARCHAR(10) NOT NULL, --więzy integralności sprawdzane za pomocą wyzwalacza
 platnosc metodaPlatnosci NOT NULL,
 dataWydania DATE NOT NULL,
 czasWydania TIME NOT NULL,
 cena MONEY NOT NULL,
 idKlienta INT DEFAULT NULL REFERENCES Klienci(idKlienta) ON DELETE CASCADE
);

DROP TABLE IF EXISTS TransakcjeKartyMiejskie;
CREATE TABLE TransakcjeKartyMiejskie (
 idTransakcji INT PRIMARY KEY,
 idKarty INT REFERENCES KartyMiejskie(idKarty),
 typ typBiletu DEFAULT NULL,
 ulgowy czyUlgowy DEFAULT NULL,
 zasieg zasiegBiletu DEFAULT NULL,
 okres okresBiletu DEFAULT NULL,
 numerPojazdu VARCHAR(10) DEFAULT NULL, --więzy integralności sprawdzane za pomocą wyzwalacza
 rodzaj typTransakcji NOT NULL,
 kwota MONEY NOT NULL,
 dataTransakcji DATE NOT NULL,
 godzinaTransakcji TIME NOT NULL
);

DROP TABLE IF EXISTS ModeleTramwajow CASCADE;
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

DROP TABLE IF EXISTS ModeleAutobusow CASCADE;
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

DROP TABLE IF EXISTS ZajezdnieTramwajowe CASCADE;
CREATE TABLE ZajezdnieTramwajowe(
 nazwa VARCHAR(50) PRIMARY KEY,
 adres VARCHAR(50) NOT NULL UNIQUE,
 maxPojazdow INT NOT NULL,
 stan stanMiejsca NOT NULL
);

DROP TABLE IF EXISTS ZajezdnieAutobusowe CASCADE;
CREATE TABLE ZajezdnieAutobusowe(
 nazwa VARCHAR(50) PRIMARY KEY,
 adres VARCHAR(50) NOT NULL UNIQUE,
 maxPojazdow INT NOT NULL,
 stan stanMiejsca NOT NULL
);

DROP TABLE IF EXISTS Tramwaje CASCADE;
CREATE TABLE Tramwaje(
 numerPojazdu VARCHAR(10) PRIMARY KEY,
 model VARCHAR(40) REFERENCES ModeleTramwajow(model) ON DELETE CASCADE,
 zajezdnia VARCHAR(50) REFERENCES ZajezdnieTramwajowe(nazwa) ON DELETE SET NULL ,
 stan stanPojazdu NOT NULL
);

DROP TABLE IF EXISTS Autobusy CASCADE;
CREATE TABLE Autobusy(
 numerPojazdu VARCHAR(10) PRIMARY KEY,
 model VARCHAR(40) REFERENCES ModeleAutobusow(model) ON DELETE CASCADE ,
 zajezdnia VARCHAR(50) REFERENCES ZajezdnieAutobusowe(nazwa) ON DELETE SET NULL,
 stan stanPojazdu NOT NULL
);

DROP TABLE IF EXISTS PrzystankiTramwajowe CASCADE;
CREATE TABLE PrzystankiTramwajowe(
 nazwa VARCHAR(50) PRIMARY KEY,
 podwojny BOOLEAN NOT NULL,
 stan stanMiejsca NOT NULL
);

DROP TABLE IF EXISTS PrzystankiAutobusowe CASCADE;
CREATE TABLE PrzystankiAutobusowe(
 nazwa VARCHAR(50) PRIMARY KEY,
 podwojny BOOLEAN NOT NULL,
 stan stanMiejsca NOT NULL
);

DROP TABLE IF EXISTS PetleTramwajowe CASCADE;
CREATE TABLE PetleTramwajowe(
 nazwa VARCHAR(50) PRIMARY KEY,
 adres VARCHAR(50) NOT NULL UNIQUE,
 iloscTorow INT,
 stan stanMiejsca NOT NULL
);

DROP TABLE IF EXISTS PetleAutobusowe CASCADE;
CREATE TABLE PetleAutobusowe(
 nazwa VARCHAR(50) PRIMARY KEY,
 adres VARCHAR(50) NOT NULL UNIQUE,
 stan stanMiejsca NOT NULL
);

DROP TABLE IF EXISTS LinieTramwajowe CASCADE;
CREATE TABLE LinieTramwajowe(
 idLinii INT PRIMARY KEY DEFAULT nextval('sekwencjaLinie'),
 numer INT,
 poczatek VARCHAR(50) REFERENCES PetleTramwajowe,
 koniec VARCHAR(50) REFERENCES PetleTramwajowe,
 typ typLinii NOT NULL
);

DROP TABLE IF EXISTS LinieAutobusowe CASCADE;
CREATE TABLE LinieAutobusowe(
 idLinii INT PRIMARY KEY DEFAULT nextval('sekwencjaLinie'),
 numer INT,
 poczatek VARCHAR(50) REFERENCES PetleAutobusowe,
 koniec VARCHAR(50) REFERENCES PetleAutobusowe,
 typ typLinii NOT NULL
);


DROP TABLE IF EXISTS RozkladTramwaje CASCADE;
CREATE TABLE RozkladTramwaje(
    przystanek VARCHAR(50) REFERENCES PrzystankiTramwajowe,
    idLinii INT REFERENCES LinieTramwajowe(idLinii),
    idKursu INT,
    godzina TIME,
    PRIMARY KEY (przystanek, idLinii, idKursu)
);

DROP TABLE IF EXISTS RozkladAutobusy CASCADE;
CREATE TABLE RozkladAutobusy(
    przystanek VARCHAR(50) REFERENCES PrzystankiAutobusowe,
    idLinii INT REFERENCES LinieAutobusowe(idLinii),
    idKursu INT,
    godzina TIME,
    PRIMARY KEY (przystanek, idLinii, idKursu)
);

DROP TABLE IF EXISTS PrzejazdyTramwajowe CASCADE;
CREATE TABLE PrzejazdyTramwajowe(
    linia INT, --references rozkladTramwaje(idLinii)
    kurs INT, --wiezy integralności sprawdzane za pomocą wyzwalacza
    data DATE,
    pojazd VARCHAR(10) REFERENCES Tramwaje ON DELETE SET NULL,
    kierowca VARCHAR(10) REFERENCES KierowcyTramwajow ON DELETE SET NULL,
    PRIMARY KEY (linia,kurs, data)
);

DROP TABLE IF EXISTS PrzejazdyAutobusowe CASCADE;
CREATE TABLE PrzejazdyAutobusowe(
    linia INT,--references rozkladAutobusy(idLinii)
    kurs INT, --wiezy integralności sprawdzane za pomocą wyzwalacza
    data DATE,
    pojazd VARCHAR(10) REFERENCES Autobusy ON DELETE SET NULL,
    kierowca VARCHAR(10) REFERENCES KierowcyAutobusow ON DELETE SET NULL,
    PRIMARY KEY (linia,kurs, data)
);

DROP INDEX IF EXISTS index_zwolnienia_pracownik;
CREATE INDEX index_zwolnienia_pracownik ON Zwolnienia USING hash (idpracownika);

DROP INDEX IF EXISTS index_rozkladTramwaje_przystanek;
CREATE INDEX index_rozkladTramwaje_przystanek ON RozkladTramwaje USING hash (przystanek);

DROP INDEX IF EXISTS index_rozkladAutobusy_przystanek;
CREATE INDEX index_rozkladAutobusy_przystanek ON RozkladAutobusy USING hash (przystanek);

DROP INDEX IF EXISTS index_rozkladTramwaje_kursLinia;
CREATE INDEX index_rozkladTramwaje_kursLinia ON RozkladTramwaje USING btree (idkursu, idLinii);

DROP INDEX IF EXISTS index_rozkladAutobusy_kursLinia;
CREATE INDEX index_rozkladAutobusy_kursLinia ON RozkladAutobusy USING btree (idkursu, idLinii);

DROP INDEX IF EXISTS index_Tramwaje_model;
CREATE INDEX index_Tramwaje_model ON Tramwaje USING hash(model);

DROP INDEX IF EXISTS index_Autobusy_model;
CREATE INDEX index_Autobusy_model ON Autobusy USING hash(model);
