---------------------------------------------------------------------------------------------------------------
--tworzenie tabel--
---------------------------------------------------------------------------------------------------------------

--DROP DATABASE IF EXISTS MPK;

--CREATE DATABASE MPK;


DROP TABLE IF EXISTS UmowyPracownikow;

DROP TABLE IF EXISTS KierowcyAutobusow CASCADE;

DROP TABLE IF EXISTS KierowcyTramwajow CASCADE;

DROP TABLE IF EXISTS Zwolnienia;

DROP TABLE IF EXISTS Bilety CASCADE;

DROP TABLE IF EXISTS Klienci CASCADE;

DROP TABLE IF EXISTS Pracownicy CASCADE;

DROP TABLE IF EXISTS Transakcje;

DROP TABLE IF EXISTS Doladowania;

DROP TABLE IF EXISTS KartyMiejskie CASCADE;

DROP TABLE IF EXISTS ModeleAutobusow CASCADE;

DROP TABLE IF EXISTS ModeleTramwajow CASCADE;

DROP TABLE IF EXISTS TransakcjeKartyMiejskie;

DROP TABLE IF EXISTS Tramwaje CASCADE;

DROP TABLE IF EXISTS Autobusy CASCADE;

DROP TABLE IF EXISTS PrzystankiTramwajowe CASCADE;

DROP TABLE IF EXISTS PrzystankiAutobusowe CASCADE;

DROP TABLE IF EXISTS ZajezdnieTramwajowe;

DROP TABLE IF EXISTS ZajezdnieAutobusowe;

DROP TABLE IF EXISTS PetleTramwajowe CASCADE;

DROP TABLE IF EXISTS PetleAutobusowe CASCADE;

DROP SEQUENCE IF EXISTS sekwencjaLinie CASCADE;

DROP SEQUENCE IF EXISTS sekwencjaIDKursu CASCADE;

DROP TABLE IF EXISTS LinieTramwajowe CASCADE;

DROP TABLE IF EXISTS LinieAutobusowe CASCADE;

DROP TABLE IF EXISTS PrzejazdyTramwajowe;

DROP TABLE IF EXISTS PrzejazdyAutobusowe;

DROP TABLE IF EXISTS RozkladTramwaje;

DROP TABLE IF EXISTS RozkladAutobusy;

DROP TYPE IF EXISTS statusPracownika CASCADE;

DROP TYPE IF EXISTS statusKarty CASCADE;

DROP TYPE IF EXISTS statusKlienta CASCADE;

DROP TYPE IF EXISTS warunki CASCADE;

DROP TYPE IF EXISTS typBiletu CASCADE;

DROP TYPE IF EXISTS typKarty CASCADE;

DROP TYPE IF EXISTS typZwolnienia CASCADE;

DROP TYPE IF EXISTS okresBiletu CASCADE;

DROP TYPE IF EXISTS zasiegBiletu CASCADE;

DROP TYPE IF EXISTS statusZnizki CASCADE;

DROP TYPE IF EXISTS statusZwolnienia CASCADE;

DROP TYPE IF EXISTS metodaPlatnosci CASCADE;

DROP TYPE IF EXISTS miejsceKupna CASCADE;

DROP TYPE IF EXISTS typTransakcji CASCADE;

DROP TYPE IF EXISTS tryb CASCADE;

DROP TYPE IF EXISTS czyUlgowy CASCADE;

DROP TYPE IF EXISTS stanPojazdu CASCADE;

DROP TYPE IF EXISTS stanMiejsca CASCADE;

DROP TYPE IF EXISTS typLinii CASCADE;

DROP TYPE IF EXISTS kwotaMandatu CASCADE;

CREATE TYPE statusPracownika AS ENUM ('zwolnienie', 'aktywny', 'urlop');

CREATE TYPE tryb AS ENUM ( 'stacjonarnie', 'hybrydowe', 'zdalnie');

CREATE TYPE typZwolnienia AS ENUM ('chorobowe', 'urlop bezpłatny', 'urlop płatny');

CREATE TYPE statusZwolnienia AS ENUM ('zakończone', 'w trakcie');

CREATE TYPE typBiletu AS ENUM ('do kasowania', 'metropolitalny', 'mieszkanca',
    'socjalny', 'bezrobotny', 'firmowy');

CREATE TYPE czyUlgowy AS ENUM ('tak', 'nie');

CREATE TYPE zasiegBiletu AS ENUM ('I', 'II', 'III', 'I+II', 'II+III',
    'I+II+III');

CREATE TYPE okresBiletu AS ENUM ('20-minutowy', '60-minutowy',
    '90-minutowy', '24-godzinny', '48-godzinny', '72-godzinny',
        '7-dniowy', 'weekendowy', 'miesięczny', 'miesięczny 1 linia',
        'półroczny'
    );

CREATE TYPE metodaPlatnosci AS ENUM('karta', 'gotowka', 'przelew blik', 'aplikacja');


CREATE TYPE statusKlienta AS ENUM ('aktywny', 'nieaktywny', 'zablokowany');

CREATE TYPE statusZnizki AS ENUM ('obowiazuje', 'nieobowiazuje');

CREATE TYPE typKarty AS ENUM ('legitymacja studencka/doktorska',
    'standardowa', 'senior');

CREATE TYPE statusKarty AS ENUM ('aktywna', 'zawieszona', 'wygasla');

CREATE TYPE typTransakcji AS ENUM ('doładowanie', 'kupno');

CREATE TYPE stanPojazdu AS ENUM ('czynny', 'zepsuty', 'serwisowany' , 'wycofany');

CREATE TYPE stanMiejsca AS ENUM('czynny', 'remontowany', 'wycofany');

CREATE TYPE typLinii AS ENUM('zwykla', 'nocna', 'aglomeracyjna', 'zastepdza');

CREATE TYPE kwotaMandatu AS ENUM(150, 240, 510);

CREATE TYPE opisMandatu AS ENUM ('spowodowanie zatrzymania bez uzasadnionej przyczyny',
    'naruszenie przepisów o przewozie zwierząt', 'nieważny dokument uprawniający do ulgi',
    'niewazny dokument uprawniający do przejazdu darmowego');



CREATE SEQUENCE sekwencjaLinie AS INT
    INCREMENT 1
    START 1
    CACHE 1;

--do zmiany dodac trigger wywolujacy procedure zamiast inserta!!!
CREATE SEQUENCE sekwencjaIDKursu AS INT
    INCREMENT 1
    START 1
    CACHE 1;

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

CREATE TABLE UmowyPracownikow (
    idUmowy INT NOT NULL ,
    idPracownika INT REFERENCES Pracownicy(idPracownika) ON DELETE CASCADE,
    dataRozpoczecia DATE NOT NULL,
    typUmowy VARCHAR(20) NOT NULL,
    okresTrwania INT NOT NULL,
    wynagrodzenieBrutto MONEY NOT NULL,
    trybPracy tryb NOT NULL
);

CREATE TABLE KierowcyAutobusow (
    idLicencji VARCHAR(20) PRIMARY KEY,
    idPracownika INT REFERENCES Pracownicy(idPracownika) ON DELETE CASCADE,
    licencjaOd DATE NOT NULL,
    licencjaDo DATE NOT NULL
);

CREATE TABLE KierowcyTramwajow (
    idLicencji VARCHAR(10) PRIMARY KEY,
    idPracownika INT REFERENCES Pracownicy(idPracownika) ON DELETE CASCADE,
    licencjaOd DATE NOT NULL,
    licencjaDo DATE NOT NULL
);


CREATE TABLE Zwolnienia (
    idZwolnienia INT PRIMARY KEY,
    idPracownika INT REFERENCES Pracownicy(idPracownika) ON DELETE CASCADE,
    dataRozpoczecia DATE NOT NULL,
    dataZakonczenia DATE NOT NULL,
    typ typZwolnienia NOT NULL,
    stanZwolnienia statusZwolnienia NOT NULL
);

CREATE TABLE Pasażerowie (
    idPasażera INT PRIMARY KEY,
    Imie VARCHAR(50) NOT NULL,
    Nazwisko VARCHAR(50) NOT NULL,
    Adres VARCHAR(256) NOT NULL, -- DODAC WIDOK MANDATY
    SumaMandatów INT NOT NULL DEFAULT 0
);

CREATE TABLE Mandaty (
    idMandatu INT PRIMARY KEY,
    idPasażera INT REFERENCES Pasażerowie(idPasażera) ON DELETE CASCADE,
    kwota kwotaMandatu NOT NULL,
    dataWystawienia DATE NOT NULL,
    opis opisMandatu NOT NULL
);

CREATE TABLE Bilety (
    idBiletu INT PRIMARY KEY ,
    typ typBiletu NOT NULL,
    ulgowy czyUlgowy NOT NULL,
    zasieg zasiegBiletu NOT NULL,
    okres okresBiletu NOT NULL,
    platnosc metodaPlatnosci NOT NULL,
    dataWydania DATE NOT NULL,
    czasWydania TIME NOT NULL,
    cena MONEY NOT NULL,
    idPasażera INT REFERENCES Pasażerowie(idPasażera) ON DELETE CASCADE
);

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

CREATE TABLE ZajezdnieTramwajowe(
    nazwa VARCHAR(50) PRIMARY KEY,
    adres VARCHAR(50) NOT NULL UNIQUE,
    maxPojazdow INT NOT NULL,
    stan stanMiejsca NOT NULL
);

CREATE TABLE ZajezdnieAutobusowe(
    nazwa VARCHAR(50) PRIMARY KEY,
    adres VARCHAR(50) NOT NULL UNIQUE,
    maxPojazdow INT NOT NULL,
    stan stanMiejsca NOT NULL
);

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

CREATE TABLE TransakcjeKartyMiejskie (
    idTransakcji INT PRIMARY KEY,
    idKarty INT REFERENCES KartyMiejskie(idKarty),
    typ typBiletu DEFAULT NULL,
    ulgowy czyUlgowy DEFAULT NULL,
    zasieg zasiegBiletu DEFAULT NULL,
    okres okresBiletu DEFAULT NULL,
    rodzaj typTransakcji NOT NULL,
    kwota MONEY NOT NULL,
    dataTransakcji DATE NOT NULL,
    godzinaTransakcji TIME NOT NULL
);

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

CREATE TABLE Tramwaje(
    numerPojazdu VARCHAR(10) PRIMARY KEY,
    model VARCHAR(40) REFERENCES ModeleTramwajow(model) ON DELETE CASCADE,
    zajezdnia VARCHAR(50) REFERENCES ZajezdnieTramwajowe(nazwa) ON DELETE SET NULL ,
    stan stanPojazdu NOT NULL
);

CREATE TABLE Autobusy(
    numerPojazdu VARCHAR(10) PRIMARY KEY,
    model VARCHAR(40) REFERENCES ModeleAutobusow(model) ON DELETE CASCADE ,
    zajezdnia VARCHAR(50) REFERENCES ZajezdnieAutobusowe(nazwa) ON DELETE SET NULL,
    stan stanPojazdu NOT NULL

);

CREATE TABLE PrzystankiTramwajowe(
    nazwa VARCHAR(50) PRIMARY KEY,
    podwojny BOOLEAN NOT NULL,
    stan stanMiejsca NOT NULL
);

CREATE TABLE PrzystankiAutobusowe(
    nazwa VARCHAR(50) PRIMARY KEY,
    podwojny BOOLEAN NOT NULL,
    stan stanMiejsca NOT NULL
);

CREATE TABLE PetleTramwajowe(
    nazwa VARCHAR(50) PRIMARY KEY,
    adres VARCHAR(50) NOT NULL UNIQUE,
    iloscTorow INT,
    stan stanMiejsca NOT NULL
);

CREATE TABLE PetleAutobusowe(
    nazwa VARCHAR(50) PRIMARY KEY,
    adres VARCHAR(50) NOT NULL UNIQUE,
    stan stanMiejsca NOT NULL
);

CREATE TABLE LinieTramwajowe(
    idLinii INT PRIMARY KEY DEFAULT nextval('sekwencjaLinie'),
    numer INT UNIQUE,
    poczatek VARCHAR(50) REFERENCES PetleTramwajowe,
    koniec VARCHAR(50) REFERENCES PetleTramwajowe,
    typ typLinii NOT NULL
);

CREATE TABLE LinieAutobusowe(
    idLinii INT PRIMARY KEY DEFAULT nextval('sekwencjaLinie'),
    numer INT UNIQUE,
    poczatek VARCHAR(50) REFERENCES PetleAutobusowe,
    koniec VARCHAR(50) REFERENCES PetleAutobusowe,
    typ typLinii NOT NULL
);

CREATE TABLE RozkladTramwaje(
    przystanek VARCHAR(50) REFERENCES PrzystankiTramwajowe,
    linia INT REFERENCES LinieTramwajowe(numer),
    idKursu INT UNIQUE DEFAULT nextval('sekwencjaIDKursu'), --do zmiany!!
    godzina TIME,
    PRIMARY KEY (przystanek, linia, idKursu)
);

CREATE TABLE RozkladAutobusy(
    przystanek VARCHAR(50) REFERENCES PrzystankiAutobusowe,
    linia INT REFERENCES LinieAutobusowe(numer),
    idKursu INT UNIQUE DEFAULT nextval('sekwencjaIDKursu'), --do zmiany!!
    godzina TIME,
    PRIMARY KEY (przystanek, linia, idKursu)
);


CREATE TABLE PrzejazdyTramwajowe(
    idPrzejazdu INT PRIMARY KEY,
    pojazd VARCHAR(10) REFERENCES Tramwaje(numerPojazdu) ON DELETE SET NULL,
    idKursu INT REFERENCES RozkladTramwaje(idKursu) ON DELETE CASCADE,
    kierowca VARCHAR REFERENCES KierowcyTramwajow(idLicencji) ON DELETE SET NULL,
    data DATE NOT NULL
);

CREATE TABLE PrzejazdyAutobusowe(
    idPrzejazdu INT PRIMARY KEY,
    pojazd VARCHAR(10) REFERENCES Autobusy(numerPojazdu) ON DELETE SET NULL ,
    idKursu INT REFERENCES RozkladAutobusy(idKursu) ON DELETE CASCADE,
    kierowca VARCHAR REFERENCES KierowcyAutobusow(idLicencji) ON DELETE SET NULL ,
    data DATE NOT NULL
);


---------------------------------------------------------------------------------------------------------------
--wypełnianie bazy danych--
---------------------------------------------------------------------------------------------------------------

INSERT INTO Pracownicy (idPracownika, imie, nazwisko, dataUrodzenia, stanowisko, dataZatrudnienia, statusZatrudnienia, numerTelefonu, numerPESEL, adresZamieszkania, idPrzelozonego) VALUES
(1, 'Michał', 'Kowalczyk', '1980-03-24', 'Dyrektor', '2022-02-07', 'urlop', '48630258764', '8003246842', 'ul. Sławkowska 71, Kraków', NULL),
(2, 'Tomasz', 'Miszczyński', '1964-03-05', 'Kierowca autobusu', '2012-12-17', 'aktywny', '48681669290', '6403055598', 'ul. Sławkowska 29, Kraków', 6),
(3, 'Anna', 'Kowalczyk', '1999-06-19', 'Kierowca tramwaju', '2016-10-25', 'aktywny', '48500403573', '9906192976', 'ul. Grodzka 18, Kraków', 6),
(4, 'Katarzyna', 'Michalczyk', '1992-06-22', 'Kierowca autobusu', '2006-05-02', 'aktywny', '48251117920', '9206223137', 'ul. Szewska 43, Kraków', 6),
(5, 'Tomasz', 'Nowak', '1966-02-28', 'Kierownik', '2023-05-04', 'zwolnienie', '48225147603', '6602287501', 'ul. Bracka 79, Kraków', 1),
(6, 'Jan', 'Wiśniewski', '1998-10-18', 'Menedźer', '2022-11-07', 'urlop', '48520712546', '9810181026', 'ul. Floriańska 68, Kraków', 1),
(7, 'Jan', 'Nowak', '1980-07-02', 'Księgowy', '2019-12-18', 'urlop', '48768472372', '8007025401', 'ul. Floriańska 39, Kraków', 5),
(8, 'Katarzyna', 'Piwowarska', '2005-07-28', 'Programista', '2004-02-23', 'aktywny', '48516546026', '0507288892', 'ul. Floriańska 34, Kraków', 5),
(9, 'Oskar', 'Kuliński', '2002-05-08', 'Programista', '2022-01-19', 'urlop', '48361396865', '0204163667', 'ul. Sławkowska 51, Kraków', 10),
(10, 'Maria', 'Kamiński', '1987-07-20', 'Kierownik', '2013-04-09', 'aktywny', '48568018933', '8707205477', 'ul. Bracka 85, Kraków', 1),
(11, 'Wieńczysław', 'Włodyga', '2003-03-29', 'Programista', '2022-11-16', 'urlop', '48402779304', '8505084207', 'ul. Szewska 83, Kraków', 10),
(12, 'Dobromir', 'Tomczyk', '1992-10-20', 'Programista', '2023-12-01', 'urlop', '48460571256', '9210209575', 'ul. Bracka 10, Kraków', 10),
(13, 'Michalina', 'Nowak', '1987-08-22', 'Kierowca tramwaju', '2005-11-18', 'aktywny', '48940310047', '8708226901', 'ul. Grodzka 54, Kraków', 6),
(14, 'Maria', 'Kamiński', '2002-04-23', 'Kierowca autobusu', '2014-11-03', 'aktywny', '48967268669', '0204237105', 'ul. Bracka 4, Kraków', 6),
(15, 'Tomasz', 'Kowalczyk', '1967-12-09', 'Księgowy', '2018-09-16', 'urlop', '48875945206', '6712097629', 'ul. Sławkowska 57, Kraków', 5),
(16, 'Katarzyna', 'Lewandowski', '1981-07-13', 'Kierownik', '2003-05-17', 'aktywny', '48103952727', '8107134349', 'ul. Floriańska 71, Kraków', 1),
(17, 'Maria', 'Kowalski', '1964-07-13', 'Kierowca tramwaju', '2008-04-14', 'aktywny', '48917963969', '6407136463', 'ul. Bracka 61, Kraków', 6),
(18, 'Piotr', 'Kowalski', '1991-05-05', 'Pracownik administracyjny', '2013-03-09', 'aktywny', '48189362153', '9105054131', 'ul. Szewska 77, Kraków', 16),
(19, 'Tomasz', 'Kamiński', '1971-11-24', 'Kierowca tramwaju', '2020-06-29', 'aktywny', '48985064195', '7111245421', 'ul. Floriańska 63, Kraków', 6),
(20, 'Katarzyna', 'Kowalski', '1987-09-16', 'Kierowca autobusu', '2003-03-30', 'aktywny', '48322707565', '8709162177', 'ul. Floriańska 41, Kraków', 6);

INSERT INTO UmowyPracownikow (idUmowy, idPracownika, dataRozpoczecia, typUmowy, okresTrwania, wynagrodzenieBrutto, trybPracy) VALUES
(1, 1, '2019-02-13', 'umowa o pracę', 13, 6815.78, 'zdalnie'),
(2, 2, '2013-11-27', 'umowa zlecenie', 40, 4956.5, 'stacjonarnie'),
(3, 3, '2019-07-28', 'umowa zlecenie', 24, 6011.53, 'stacjonarnie'),
(4, 4, '2017-12-12', 'umowa zlecenie', 33, 4671.75, 'zdalnie'),
(5, 5, '2020-02-23', 'umowa zlecenie', 46, 3890.77, 'stacjonarnie'),
(6, 6, '2019-07-26', 'umowa o pracę', 34, 3109.86, 'hybrydowe'),
(7, 7, '2014-12-19', 'umowa zlecenie', 27, 4272.54, 'stacjonarnie'),
(8, 8, '2020-08-14', 'umowa zlecenie', 44, 6960.95, 'stacjonarnie'),
(9, 9, '2014-05-13', 'umowa o pracę', 33, 6533.13, 'stacjonarnie'),
(10, 10, '2022-09-04', 'umowa zlecenie', 37, 7238.56, 'hybrydowe'),
(11, 11, '2014-05-05', 'umowa o pracę', 36, 3268.63, 'stacjonarnie'),
(12, 12, '2016-02-17', 'umowa o pracę', 12, 4094.05, 'hybrydowe'),
(13, 13, '2014-05-20', 'umowa o pracę', 21, 6336.53, 'stacjonarnie'),
(14, 14, '2019-09-22', 'umowa o pracę', 48, 6547.07, 'stacjonarnie'),
(15, 15, '2014-06-22', 'umowa zlecenie', 13, 5011.28, 'stacjonarnie'),
(16, 16, '2014-10-17', 'umowa o pracę', 42, 4097.52, 'stacjonarnie'),
(17, 17, '2015-02-16', 'umowa o pracę', 28, 3065.45, 'stacjonarnie'),
(18, 18, '2017-09-06', 'umowa o pracę', 16, 4663.61, 'stacjonarnie'),
(19, 19, '2017-12-24', 'umowa zlecenie', 47, 3206.13, 'stacjonarnie'),
(20, 20, '2016-05-25', 'umowa zlecenie', 7, 3060.03, 'hybrydowe');

INSERT INTO KierowcyAutobusow (idLicencji, idPracownika, licencjaOd, licencjaDo) VALUES  
  ('BUS0044456', 1, '2017-01-08', '2018-12-24'),
  ('BUS1255678', 4, '2019-03-05', '2020-05-18'),
  ('BUS1123678', 14, '2018-02-27', '2020-12-11'),
  ('BUS4389900', 20, '2018-03-12', '2019-05-22');

INSERT INTO KierowcyTramwajow (idLicencji, idPracownika, licencjaOd, licencjaDo) VALUES
  ('TRA1231570', 3, '2018-05-09', '2021-11-20'),
  ('TRA9910200', 19, '2015-12-16', '2019-09-26'),
  ('TRA9904890', 13, '2015-06-20', '2019-02-01'),
  ('TRA0008999', 17, '2018-04-09', '2022-02-03');

INSERT INTO Zwolnienia (idZwolnienia, idPracownika, dataRozpoczecia, dataZakonczenia, typ, stanZwolnienia) VALUES
  (1, 5, '2019-04-10', '2019-06-22', 'chorobowe', 'w trakcie'),
  (2, 17, '2021-10-11', '2021-12-28', 'urlop płatny', 'w trakcie'),
  (3, 19, '2019-01-19', '2019-02-28', 'urlop bezpłatny', 'w trakcie'),
  (4, 20, '2018-05-12', '2018-06-18', 'urlop płatny', 'w trakcie'),
  (5, 15, '2021-09-23', '2021-10-22', 'urlop płatny', 'w trakcie'),
  (6, 14, '2020-06-20', '2020-09-15', 'chorobowe', 'w trakcie'),
  (7, 16, '2019-06-07', '2019-08-20', 'urlop bezpłatny', 'w trakcie'),
  (8, 1, '2020-01-16', '2020-02-14', 'urlop płatny', 'zakończone'),
  (9, 3, '2022-10-07', '2022-12-22', 'chorobowe', 'zakończone'),
  (10, 2, '2020-11-28', '2021-01-26', 'urlop płatny', 'zakończone'),
  (11, 3, '2019-01-09', '2019-01-26', 'urlop płatny', 'zakończone'),
  (12, 4, '2019-03-19', '2019-05-18', 'chorobowe', 'zakończone'),
  (13, 4, '2020-02-13', '2020-04-18', 'urlop bezpłatny', 'zakończone'),
  (14, 2, '2019-12-14', '2020-02-04', 'urlop bezpłatny', 'zakończone'),
  (15, 12, '2019-01-23', '2019-02-24', 'urlop bezpłatny', 'zakończone'),
  (16, 11, '2019-09-18', '2019-11-30', 'urlop bezpłatny', 'zakończone'),
  (17, 9, '2022-11-07', '2022-12-03', 'chorobowe', 'zakończone'),
  (18, 8, '2022-01-26', '2022-03-10', 'urlop płatny', 'zakończone'),
  (19, 7, '2020-08-08', '2020-09-16', 'urlop bezpłatny', 'zakończone'),
  (20, 6, '2022-09-11', '2022-10-23', 'urlop bezpłatny', 'zakończone');

INSERT INTO Pasażerowie (idPasażera, Imie, Nazwisko, Adres) VALUES
(1, 'Jan', 'Nowak', 'ul. Floriańska 17, Kraków'),
(2, 'Anna', 'Kowalska', 'ul. Grodzka 15, Kraków'),
(3, 'Piotr', 'Wiśniewski', 'ul. Szeroka 2, Kraków'),
(4, 'Katarzyna', 'Wójcik', 'ul. Długa 1, Kraków'),
(5, 'Marcin', 'Kowalczyk', 'ul. Krótka 45, Kraków'),
(6, 'Agnieszka', 'Kamińska', 'ul. Lubicz 56, Kraków'),
(7, 'Tomasz', 'Lewandowski', 'ul. Basztowa 22, Kraków'),
(8, 'Barbara', 'Zielińska', 'ul. Garbarska 15, Kraków'),
(9, 'Krzysztof', 'Szymański', 'ul. Szewska 34, Kraków'),
(10, 'Małgorzata', 'Woźniak', 'ul. Bracka 15, Kraków'),
(11, 'Andrzej', 'Dąbrowski', 'ul. Poselska 22, Kraków'),
(12, 'Alicja', 'Kozłowska', 'ul. Kanonicza 2, Kraków'),
(13, 'Michał', 'Jankowski', 'ul. Św. Anny 87, Kraków'),
(14, 'Dorota', 'Mazur', 'ul. Piłsudskiego 66, Kraków'),
(15, 'Jakub', 'Wojciechowski', 'ul. Dietla 60, Kraków'),
(16, 'Ewa', 'Kwiatkowska', 'ul. Starowiślna 24, Kraków'),
(17, 'Robert', 'Kaczmarek', 'ul. Dunajewskiego 13, Kraków'),
(18, 'Marta', 'Piotrowska', 'ul. Rakowicka 11, Kraków'),
(19, 'Paweł', 'Grabowski', 'ul. Podwale 14, Kraków'),
(20, 'Magdalena', 'Nowakowska', 'ul. Stolarska 28, Kraków');

INSERT INTO Mandaty (idMandatu, idPasażera, kwota, dataWystawienia, opis) VALUES
    (1, 1, 150, '24-01-2024', 'nieważny dokument uprawniający do ulgi'),
    (1, 2, 510, '24-01-2024', 'spowodowanie zatrzymania bez uzasadnionej przyczyny'),
    (1, 4, 240, '24-01-2024', 'niewazny dokument uprawniający do przejazdu darmowego'),
    (1, 15, 150, '24-01-2024', 'nieważny dokument uprawniający do ulgi'),
    (1, 11, 150, '24-01-2024', 'niewazny dokument uprawniający do ulgi'),
    (1, 12, 240, '24-01-2024', 'nieważny dokument uprawniający do przejazdu darmowego'),
    (1, 11, 240, '24-01-2024', 'niewazny dokument uprawniający do przejazdu darmowego'),
    (1, 11, 150, '24-01-2024', 'nieważny dokument uprawniający do ulgi'),
    (1, 5, 510, '24-01-2024', 'spowodowanie zatrzymania bez uzasadnionej przyczyny'),
    (1, 6, 150, '24-01-2024', 'nieważny dokument uprawniający do ulgi');

INSERT INTO Bilety (idbiletu, typ, ulgowy, zasieg, okres, platnosc, datawydania, czaswydania, cena, idPasażera) VALUES
(1, 'firmowy', 'nie', 'I+II+III', 'miesięczny', 'przelew blik', '2023-06-23', '17:33:44', 169.00, 1),
(2, 'firmowy', 'nie', 'I+II', 'miesięczny', 'aplikacja', '2023-04-30', '04:06:44', 144.00, 2),
(3, 'metropolitalny', 'tak', 'II+III', 'miesięczny', 'karta', '2023-06-08', '10:04:37', 84.50, 3),
(4, 'mieszkanca', 'nie', 'I', 'miesięczny', 'przelew blik', '2023-09-13', '04:34:58', 80.00, 4),
(5, 'firmowy', 'nie', 'I+II+III', 'miesięczny', 'aplikacja', '2023-09-20', '04:39:26', 169.00, 5),
(6, 'do kasowania', 'tak', 'I+II+III', '48-godzinny', 'aplikacja', '2023-12-19', '04:51:13', 17.50, 6),
(7, 'do kasowania', 'tak', 'I+II+III', '48-godzinny', 'aplikacja', '2023-08-26', '19:27:03', 17.50, 7),
(8, 'bezrobotny', 'nie', 'I+II', 'miesięczny', 'karta', '2023-04-16', '05:09:04', 50.00, 8),
(9, 'bezrobotny', 'nie', 'I+II+III', 'miesięczny', 'aplikacja', '2023-02-02', '02:38:55', 70.00, 9),
(10, 'socjalny', 'nie', 'I', 'miesięczny', 'karta', '2023-03-08', '14:34:17', 30.00, 10),
(11, 'bezrobotny', 'nie', 'I+II+III', 'miesięczny', 'aplikacja', '2023-03-13', '08:11:36', 70.00, 11),
(12, 'socjalny', 'nie', 'I+II+III', 'miesięczny', 'karta', '2023-08-07', '01:53:11', 70.00, 12),
(13, 'mieszkanca', 'nie', 'I', 'miesięczny 1 linia', 'aplikacja', '2023-05-23', '16:48:42', 80.00, 13),
(14, 'mieszkanca', 'tak', 'I', 'miesięczny', 'gotowka', '2023-03-20', '02:26:25', 40.00, 14),
(15, 'socjalny', 'nie', 'I+II', 'miesięczny', 'gotowka', '2023-12-27', '05:30:36', 50.00, 15);

INSERT INTO Klienci (idKlienta, imie, nazwisko, dataUrodzenia, email, numerTelefonu, adresZamieszkania, dataRejestracji, stanKlienta, znizka) VALUES
(1, 'Piotr', 'Wiśniewski', '1997-03-28', 'piotr.wiśniewski@example.com', '702375572', 'ul. Słoneczna 98, Kraków', '2023-08-16', 'aktywny', 'obowiazuje'),
(2, 'Tomasz', 'Kamiński', '1990-03-29', 'tomasz.kamiński@inbox.com', '699141193', 'ul. Leśna 12, Kraków', '2023-09-14', 'zablokowany', 'obowiazuje'),
(3, 'Marek', 'Wójcik', '1955-08-17', 'marek.wójcik@mail.com', '285271704', 'ul. Klonowa 46, Kraków', '2023-12-29', 'aktywny', 'obowiazuje'),
(4, 'Agnieszka', 'Kowalski', '2000-01-31', 'agnieszka.kowalski@inbox.com', '641448310', 'ul. Słoneczna 72, Kraków', '2023-02-17', 'aktywny', 'obowiazuje'),
(5, 'Agnieszka', 'Zieliński', '1999-11-06', 'agnieszka.zieliński@inbox.com', '350526558', 'ul. Długa 37, Kraków', '2023-01-02', 'aktywny', 'nieobowiazuje'),
(6, 'Tomasz', 'Wójcik', '1998-05-30', 'tomasz.wójcik@mail.com', '766260575', 'ul. Krótka 10, Kraków', '2023-05-17', 'nieaktywny', 'obowiazuje'),
(7, 'Agnieszka', 'Kamiński', '1995-02-08', 'agnieszka.kamiński@mail.com', '236710344', 'ul. Długa 27, Kraków', '2023-09-24', 'zablokowany', 'obowiazuje'),
(8, 'Piotr', 'Lewandowski', '1950-11-10', 'piotr.lewandowski@example.com', '330114129', 'ul. Leśna 92, Kraków', '2023-04-10', 'nieaktywny', 'obowiazuje'),
(9, 'Agnieszka', 'Nowak', '2003-12-29', 'agnieszka.nowak@example.com', '997510367', 'ul. Krótka 73, Kraków', '2023-02-22', 'zablokowany', 'nieobowiazuje'),
(10, 'Monika', 'Dąbrowski', '2002-05-16', 'monika.dąbrowski@mail.com', '258540683', 'ul. Krótka 88, Kraków', '2023-10-27', 'aktywny', 'obowiazuje'),
(11, 'Jan', 'Nowak', '2023-06-24', 'jan.nowak@example.com', '902379093', 'ul. Słoneczna 18, Kraków', '2023-06-24', 'zablokowany', 'nieobowiazuje'),
(12, 'Monika', 'Wiśniewski', '2023-09-17', 'monika.wiśniewski@mail.com', '661229926', 'ul. Długa 17, Kraków', '2023-10-19', 'aktywny', 'obowiazuje'),
(13, 'Agnieszka', 'Wójcik', '1955-11-03', 'agnieszka.wójcik@mail.com', '894493301', 'ul. Krótka 11, Kraków', '2023-07-13', 'nieaktywny', 'nieobowiazuje'),
(14, 'Monika', 'Kowalski', '2001-10-11', 'monika.kowalski@mail.com', '323359304', 'ul. Słoneczna 92, Kraków', '2023-11-05', 'zablokowany', 'nieobowiazuje'),
(15, 'Agnieszka', 'Nowak', '2000-01-05', 'agnieszka.nowak@mail.com', '320861912', 'ul. Klonowa 38, Kraków', '2023-10-07', 'nieaktywny', 'obowiazuje');

INSERT INTO KartyMiejskie (idKarty, idKlienta, numerKarty, typ, dataWydania, waznaOd, waznaDo, stanKarty, saldo) VALUES
(1, 15, 474541, 'legitymacja studencka/doktorska', '2023-12-19', '2023-12-19', '2024-12-18', 'wygasla', 0.00),
(2, 10, 973590, 'legitymacja studencka/doktorska', '2023-05-03', '2023-05-03', '2024-05-02', 'zawieszona', 0.00),
(3, 3, 561385, 'senior', '2023-06-07', '2023-06-07', '2024-06-06', 'aktywna', 0.00),
(4, 14, 124824, 'standardowa', '2023-06-18', '2023-06-18', '2024-06-17', 'zawieszona', 0.00),
(5, 8, 771793, 'senior', '2023-10-23', '2023-10-23', '2024-10-22', 'aktywna', 0.00),
(6, 1, 328949, 'standardowa', '2023-04-07', '2023-04-07', '2024-04-06', 'aktywna', 100.00),
(7, 13, 534194, 'senior', '2023-05-15', '2023-05-15', '2024-05-14', 'wygasla', 0.00),
(8, 7, 379240, 'standardowa', '2024-09-02', '2023-09-02', '2024-09-01', 'aktywna', 0.00),
(9, 5, 190893, 'legitymacja studencka/doktorska', '2023-07-15', '2023-07-15', '2024-07-14', 'aktywna', 0.00),
(10, 7, 547017, 'legitymacja studencka/doktorska', '2023-08-23', '2023-08-23', '2024-08-22', 'wygasla', 0.00),
(11, 8, 272555, 'legitymacja studencka/doktorska', '2023-06-17', '2023-06-17', '2024-06-16', 'wygasla', 0.00),
(12, 1, 217437, 'standardowa', '2023-10-29', '2023-10-29', '2024-10-28', 'zawieszona', 96.50),
(13, 1, 758550, 'standardowa', '2023-08-18', '2023-08-18', '2024-08-17', 'aktywna', 150.55),
(14, 12, 782074, 'standardowa', '2023-09-22', '2023-09-22', '2024-09-21', 'wygasla', 50.55),
(15, 3, 641817, 'standardowa', '2023-04-24', '2023-04-24', '2024-04-23', 'zawieszona', 2.00);


INSERT INTO TransakcjeKartyMiejskie (idTransakcji, idKarty, typ, ulgowy, zasieg, okres, rodzaj, kwota, dataTransakcji, godzinaTransakcji) VALUES
(1, 5, NULL, NULL, NULL, NULL, 'doładowanie', 50.00, '2023-01-02', '09:23:11'),
(2, 7, 'do kasowania', 'tak','I', '20-minutowy', 'kupno', 2.00, '2023-01-02', '09:23:11'),
(3, 11, 'do kasowania', 'nie','I', '60-minutowy', 'kupno', 6.00, '2023-01-02', '09:23:11'),
(4, 12, 'do kasowania', 'nie','I', '60-minutowy', 'kupno', 6.00, '2023-01-02', '09:23:11'),
(5, 15, 'do kasowania','nie','I', '20-minutowy', 'kupno', 4.00, '2023-01-02', '09:23:11'),
(6, 2, 'do kasowania', 'tak','I', '20-minutowy', 'kupno', 2.00, '2023-01-02', '09:23:11'),
(7, 3, 'do kasowania', 'nie','I', '20-minutowy', 'kupno', 6.00, '2023-01-02', '09:23:11'),
(8, 1, NULL, NULL, NULL, NULL, 'doładowanie', 20.00, '2023-01-02', '09:23:11'),
(9, 2, NULL, NULL, NULL, NULL, 'doładowanie', 12.50, '2023-01-02', '09:23:11'),
(10, 4, NULL, NULL, NULL, NULL, 'doładowanie', 10.00, '2023-01-02', '09:23:11');
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
    ('Płaszów', 'Biskupińska 2', 160, 'czynny'),
    ('Bieńczyce', 'Makuszyńskiego 34', 200, 'czynny'),
    ('Czyżyny', 'Osiedle 2 Pułku Lotniczego 26', 100, 'wycofany');

INSERT INTO Autobusy(numerPojazdu, model, zajezdnia, stan)
VALUES
    ('DR541', 'Citaro Solo', 'Wola Duchacka', 'czynny'),
    ('HY537', 'Urbino 12', 'Płaszów', 'czynny'),
    ('RY217', '7900A Hybrid', 'Płaszów', 'serwisowany'),
    ('RY223', 'Urbino 18 Electric', 'Bieńczyce', 'czynny'),
    ('DR501', 'Urbino 12.9 Hybrid', 'Wola Duchacka', 'serwisowany'),
    ('DR506', 'Urbino 18 Hybrid', 'Płaszów', 'czynny'),
    ('DY116', 'Sancity', 'Czyżyny', 'serwisowany'),
    ('RH255', 'Urbino 12', 'Czyżyny', 'czynny'),
    ('RY201', 'Urbino 18 Hybrid', 'Wola Duchacka', 'czynny'),
    ('RY200', 'Urbino 12', 'Płaszów', 'zepsuty');

INSERT INTO Tramwaje(numerPojazdu, model, zajezdnia, stan)
VALUES
    ('KJ502', 'GT8S', 'Podgórze', 'czynny'),
    ('EK403', 'EU8N', 'Podgórze', 'czynny'),
    ('ER503', 'EU8N', 'Św. Wawrzyńca', 'czynny'),
    ('EK523', 'EU8N', 'Św. Wawrzyńca', 'serwisowany'),
    ('HK543', 'EU8N', 'Nowa Huta', 'czynny'),
    ('RK423', 'EU8N', 'Św. Wawrzyńca', 'czynny'),
    ('ER213', 'EU8N', 'Nowa Huta', 'serwisowany'),
    ('EL113', 'EU8N', 'Podgórze', 'czynny'),
    ('KJ423', 'EU8N', 'Podgórze', 'wycofany'),
    ('ER455', 'EU8N', 'Św. Wawrzyńca', 'zepsuty');

INSERT INTO PetleTramwajowe(nazwa, adres, iloscTorow, stan)
VALUES
    ('Czerwone Maki P+R', 'Czerwone Maki 77', 2, 'czynny'),
    ('Mały Płaszów P+R', 'Mały Płaszów 7', 2, 'czynny'),
    ('Dworzec Towarowy', 'Kamienna 17', 2, 'czynny'),
    ('Górka Narodowa P+R', 'Belwederczyków 7', 1, 'remontowany'),
    ('Osiedle Piastów', 'Osiedle Bohaterów Września 68C', 2, 'czynny');

INSERT INTO PetleAutobusowe(nazwa, adres, stan)
VALUES
    ('Czerwone Maki P+R', 'Czerwone Maki 77', 'czynny'),
    ('Pod Fortem', 'Profesora Wojciecha Marii Bartla', 'czynny'),
    ('Krowodrza Górka P+R', 'Krowoderskich Zuchów 13', 'czynny'),
    ('Mistrzejowice', 'Ks. Kazimierza Jancarza 74', 'czynny'),
    ('Azory', 'Wojciecha Weissa 16', 'czynny'),
    ('Plac Centralny im. R.Reagana', 'Plac Centralny im. R.Reagana', 'czynny');

INSERT INTO LinieTramwajowe (numer, poczatek, koniec, typ)
VALUES
    (11, 'Czerwone Maki P+R', 'Mały Płaszów P+R', 'zwykla'),
    (17, 'Czerwone Maki P+R', 'Dworzec Towarowy', 'zwykla'),
    (18, 'Czerwone Maki P+R', 'Górka Narodowa P+R', 'zwykla'),
    (52, 'Czerwone Maki P+R', 'Osiedle Piastów', 'zwykla');

INSERT INTO LinieAutobusowe(numer, poczatek, koniec, typ)
VALUES
    (194, 'Pod Fortem', 'Krowodrza Górka P+R', 'zwykla'),
    (578, 'Czerwone Maki P+R', 'Mistrzejowice', 'zwykla'),
    (494, 'Pod Fortem', 'Azory', 'zwykla'),
    (662, 'Czerwone Maki P+R', 'Plac Centralny im. R.Reagana', 'nocna');

INSERT INTO PrzystankiTramwajowe(nazwa, podwojny, stan)
VALUES
    ('Czerwone Maki P+R 01', FALSE, 'czynny'),
    ('Norymberska 02', False, 'czynny'),
    ('Rondo Grunwaldzkie 02', True, 'czynny'),
    ('Norymberska 01', False, 'czynny'),
    ('Rondo Grunwaldzkie 01', True, 'czynny');

INSERT INTO PrzystankiAutobusowe(nazwa, podwojny, stan)
VALUES
    ('Makowskiego 01', False, 'czynny'),
    ('Rondo Grunwaldzkie 02', True, 'czynny'),
    ('Lipińskiego 03', False, 'czynny'),
    ('Makowskiego 04', False, 'czynny'),
    ('Rondo Grunwaldzkie 01', True, 'czynny'),
    ('Lipińskiego 04', False, 'czynny');

INSERT INTO RozkladTramwaje(przystanek, linia, godzina)
VALUES
    ('Czerwone Maki P+R 01', 11, '10:10'),
    ('Czerwone Maki P+R 01', 11, '10:25'),
    ('Czerwone Maki P+R 01', 18, '11:11'),
    ('Czerwone Maki P+R 01', 18, '11:19'),
    ('Czerwone Maki P+R 01', 17, '12:16'),
    ('Czerwone Maki P+R 01', 17, '12:31'),
    ('Czerwone Maki P+R 01', 52, '13:07'),
    ('Czerwone Maki P+R 01', 52, '13:14'),
    ('Rondo Grunwaldzkie 01', 52, '13:04'),
    ('Rondo Grunwaldzkie 01', 52, '13:12'),
    ('Rondo Grunwaldzkie 01', 18, '15:07'),
    ('Rondo Grunwaldzkie 01', 18, '15:14');

INSERT INTO RozkladAutobusy(przystanek, linia, godzina)
VALUES
    ('Lipińskiego 04', 578, '11:04'),
    ('Lipińskiego 04', 578, '11:24'),
    ('Lipińskiego 04', 662, '00:18'),
    ('Lipińskiego 04', 662, '01:18'),
    ('Lipińskiego 03', 662, '00:38'),
    ('Lipińskiego 03', 662, '01:38'),
    ('Makowskiego 01', 194, '09:10'),
    ('Makowskiego 01', 194, '09:25'),
    ('Makowskiego 04', 194, '08:05'),
    ('Makowskiego 04', 194, '08:20'),
    ('Rondo Grunwaldzkie 01', 494, '11:06'),
    ('Rondo Grunwaldzkie 01', 494, '11:26'),
    ('Rondo Grunwaldzkie 02', 494, '11:01'),
    ('Rondo Grunwaldzkie 02', 494, '11:21');

--dodac przejazdy


---------------------------------------------------------------------------------------------------------------
--wyzwalacze--
---------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER tr_after_rozkladTramwaje AFTER INSERT ON RozkladTramwaje
    FOR EACH ROW EXECUTE FUNCTION wstawidkursu('Tramwaj');

CREATE OR REPLACE TRIGGER tr_after_rozkladAutobusy AFTER INSERT ON RozkladAutobusy
    EXECUTE FUNCTION wstawidkursu('Autobus');

CREATE OR REPLACE TRIGGER tr_before_tramwaje BEFORE INSERT ON Tramwaje
    EXECUTE FUNCTION sprawdzStanZajezdni('Tramwaj');

CREATE OR REPLACE TRIGGER tr_before_autobusy BEFORE INSERT ON Autobusy
    EXECUTE FUNCTION sprawdzStanZajezdni('Autobus');

CREATE OR REPLACE TRIGGER tr_before_przejazdyTramwajowe BEFORE INSERT ON PrzejazdyTramwajowe
    EXECUTE FUNCTION sprawdzDostepnoscKierowcyIPojazdu();

CREATE OR REPLACE TRIGGER tr_before_przejazdyAutobusowe BEFORE INSERT ON PrzejazdyAutobusowe
    EXECUTE FUNCTION sprawdzDostepnoscKierowcyIPojazdu();

CREATE OR REPLACE TRIGGER tr_after_Mandaty AFTER INSERT ON Mandaty
    EXECUTE FUNCTION nalozMandat();

---------------------------------------------------------------------------------------------------------------















