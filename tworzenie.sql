---------------------------------------------------------------------------------------------------------------
--tworzenie tabel--
---------------------------------------------------------------------------------------------------------------

DROP DATABASE IF EXISTS MPK

DROP TABLE IF EXISTS UmowyPracownikow;

DROP TABLE IF EXISTS KierowcyAutobusow;

DROP TABLE IF EXISTS KierowcyTramwajow;

DROP TABLE IF EXISTS Zwolnienia;

DROP TABLE IF EXISTS Bilety;

DROP TABLE IF EXISTS Klienci;

DROP TABLE IF EXISTS Pracownicy;

DROP TABLE IF EXISTS Transakcje;

DROP TABLE IF EXISTS Doladowania;

DROP TABLE IF EXISTS Pracownicy;

DROP TABLE IF EXISTS KartyMiejskie;

DROP TYPE IF EXISTS statusPracownika;

DROP TYPE IF EXISTS statusKarty;

DROP TYPE IF EXISTS statusKlienta;

DROP TYPE IF EXISTS warunki;

DROP TYPE IF EXISTS typBiletu;

DROP TYPE IF EXISTS typKarty;

DROP TYPE IF EXISTS typZwolnienia;

DROP TYPE IF EXISTS okresBiletu;

DROP TYPE IF EXISTS zasiegBiletu;

DROP TYPE IF EXISTS statusZnizki;

DROP TYPE IF EXISTS statusZwolnienia;

DROP TYPE IF EXISTS metodaPlatnosci;

DROP TYPE IF EXISTS miejsceKupna;

DROP TYPE IF EXISTS typTransakcji;


DROP TRIGGER IF EXISTS aktualizuj_saldo_doladowanie ON KartyMiejskie;

DROP TRIGGER IF EXISTS aktualizuj_saldo_transakcja ON KartyMiejskie;

CREATE DATABASE MPK WITH
OWNER = MPK_Owners,
ENCODING = 'UTF8',
LC_COLLATE = 'pl_PL.UTF-8', --pozwala na polskie znaki
LC-CTYPE = 'pl_PL.UTF-8'; --definiuje zachowanie bazy danych przy sortowaniu (ORDER BY ... DESC/ASC)

CREATE TYPE statusPracownika AS ENUM ('zwolnienie', 'aktywny', 'urlop');

CREATE TYPE tryb AS ENUM ( 'stacjonarnie', 'hybrydowe');

CREATE TYPE typZwolnienia AS ENUM ('chorobowe', 'urlop bezpłatny', 'urlop płatny');

CREATE TYPE statusZwolnienia AS ENUM ('zakończone', 'w trakcie');

CREATE TYPE typBiletu AS ENUM ('do kasowania', 'metropolitalny', 'mieszkanca',
    'socjalny', 'bezrobotny');

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
    adresZamieszkania VARCHAR(80) NOT NULL
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


CREATE TABLE Bilety (
    idBiletu INT PRIMARY KEY ,
    typ typBiletu NOT NULL,
    ulgowy czyUlgowy NOT NULL,
    zasieg zasiegBiletu NOT NULL,
    okres okresBiletu NOT NULL,
    platnosc metodaPlatnosci NOT NULL,
    dataWydania DATE NOT NULL,
    czasWydania TIME NOT NULL,
    cena MONEY NOT NULL
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
    okresBiletu DEFAULT NULL,
    rodzaj typTransakcji NOT NULL,
    kwota MONEY NOT NULL,
    dataTransakcji DATE NOT NULL,
    godzinaTransakcji DATE NOT NULL
);

---------------------------------------------------------------------------------------------------------------
--wypełnianie bazy danych--
---------------------------------------------------------------------------------------------------------------

INSERT INTO Pracownicy (idPracownika, imie, nazwisko, dataUrodzenia, stanowisko, dataZatrudnienia, statusZatrudnienia, numerTelefonu, adresZamieszkania) VALUES
(1, 'Michał', 'Kowalczyk', '1980-03-24', 'Dyrektor', '2022-02-07', 'urlop', '48630258764', '8003246842', 'ul. Sławkowska 71, Kraków'),
(2, 'Tomasz', 'Miszczyński', '1964-03-05', 'Kierowca autobusu', '2012-12-17', 'urlop', '48681669290', '6403055598', 'ul. Sławkowska 29, Kraków'),
(3, 'Anna', 'Kowalczyk', '1999-06-19', 'Kierowca tramwaju', '2016-10-25', 'urlop', '48500403573', '9906192976', 'ul. Grodzka 18, Kraków'),
(4, 'Katarzyna', 'Michalczyk', '1992-06-22', 'Księgowy', '2006-05-02', 'urlop', '48251117920', '9206223137', 'ul. Szewska 43, Kraków'),
(5, 'Tomasz', 'Nowak', '1966-02-28', 'Kierownik', '2023-05-04', 'zwolnienie', '48225147603', '6602287501', 'ul. Bracka 79, Kraków'),
(6, 'Jan', 'Wiśniewski', '1998-10-18', 'Księgowy', '2022-11-07', 'urlop', '48520712546', '9810181026', 'ul. Floriańska 68, Kraków'),
(7, 'Jan', 'Nowak', '1980-07-02', 'Księgowy', '2019-12-18', 'urlop', '48768472372', '8007025401', 'ul. Floriańska 39, Kraków'),
(8, 'Katarzyna', 'Piwowarska', '2005-07-28', 'Programista', '2004-02-23', 'aktywny', '48516546026', '0507288892', 'ul. Floriańska 34, Kraków'),
(9, 'Oskar', 'Kuliński', '2002-05-08', 'Programista', '2022-01-19', 'urlop', '48361396865', '0204163667', 'ul. Sławkowska 51, Kraków'),
(10, 'Maria', 'Kamiński', '1987-07-20', 'Kierownik', '2013-04-09', 'aktywny', '48568018933', '8707205477', 'ul. Bracka 85, Kraków'),
(11, 'Wieńczysław', 'Włodyga', '2003-03-29', 'Programista', '2022-11-16', 'urlop', '48402779304', '8505084207', 'ul. Szewska 83, Kraków'),
(12, 'Dobromir', 'Tomczyk', '1992-10-20', 'Programista', '2023-12-01', 'urlop', '48460571256', '9210209575', 'ul. Bracka 10, Kraków'),
(13, 'Michalina', 'Nowak', '1987-08-22', 'Kierowca tramwaju', '2005-11-18', 'aktywny', '48940310047', '8708226901', 'ul. Grodzka 54, Kraków'),
(14, 'Maria', 'Kamiński', '2002-04-23', 'Kierowca autobusu', '2014-11-03', 'aktywny', '48967268669', '0204237105', 'ul. Bracka 4, Kraków'),
(15, 'Tomasz', 'Kowalczyk', '1967-12-09', 'Księgowy', '2018-09-16', 'urlop', '48875945206', '6712097629', 'ul. Sławkowska 57, Kraków'),
(16, 'Katarzyna', 'Lewandowski', '1981-07-13', 'Kierownik', '2003-05-17', 'aktywny', '48103952727', '8107134349', 'ul. Floriańska 71, Kraków'),
(17, 'Maria', 'Kowalski', '1964-07-13', 'Kierowca tramwaju', '2008-04-14', 'zwolnienie', '48917963969', '6407136463', 'ul. Bracka 61, Kraków'),
(18, 'Piotr', 'Kowalski', '1991-05-05', 'Pracownik administracyjny', '2013-03-09', 'aktywny', '48189362153', '9105054131', 'ul. Szewska 77, Kraków'),
(19, 'Tomasz', 'Kamiński', '1971-11-24', 'Kierowca tramwaju', '2020-06-29', 'zwolnienie', '48985064195', '7111245421', 'ul. Floriańska 63, Kraków'),
(20, 'Katarzyna', 'Kowalski', '1987-09-16', 'Księgowy', '2003-03-30', 'urlop', '48322707565', '8709162177', 'ul. Floriańska 41, Kraków'),

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
  ('BUS0044456', 2, '2017-01-08', '2018-12-24'),
  ('BUS1255678', 14, '2019-03-05', '2020-05-18'),
  ('BUS1123678', 24, '2018-02-27', '2020-12-11'),
  ('BUS4389900', 28, '2018-03-12', '2019-05-22')

INSERT INTO KierowcyTramwajow (idLicencji, idPracownika, licencjaOd, licencjaDo) 
  ('TRA1231570', 3, '2018-05-09', '2021-11-20');,
  ('TRA9910200', 9, '2015-12-16', '2019-09-26');,
  ('TRA9904890', 13, '2015-06-20', '2019-02-01');,
  ('TRA0008999', 17, '2018-04-09', '2022-02-03');,
  ('TRA4893090', 19, '2016-01-05', '2019-09-16');;

INSERT INTO Zwolnienia VALUES
  (1, 5, '2019-04-10', '2019-06-22', 'chorobowe', 'w trakcie');,
  (2, 17, '2021-10-11', '2021-12-28', 'urlop płatny', 'w trakcie');,
  (3, 19, '2019-01-19', '2019-02-28', 'urlop bezpłatny', 'w trakcie');,
  (4, 21, '2018-05-12', '2018-06-18', 'urlop płatny', 'w trakcie');,
  (5, 23, '2021-09-23', '2021-10-22', 'urlop płatny', 'w trakcie');,
  (6, 27, '2020-06-20', '2020-09-15', 'chorobowe', 'w trakcie');,
  (7, 28, '2019-06-07', '2019-08-20', 'urlop bezpłatny', 'w trakcie');,
  (8, 1, '2020-01-16', '2020-02-14', 'urlop płatny', 'zakończone');,
  (9, 25, '2022-10-07', '2022-12-22', 'chorobowe', 'zakończone');,
  (10, 2, '2020-11-28', '2021-01-26', 'urlop płatny', 'zakończone');,
  (11, 6, '2019-01-09', '2019-01-26', 'urlop płatny', 'zakończone');,
  (12, 11, '2019-03-19', '2019-05-18', 'chorobowe', 'zakończone');,
  (13, 16, '2020-02-13', '2020-04-18', 'urlop bezpłatny', 'zakończone');,
  (14, 7, '2019-12-14', '2020-02-04', 'urlop bezpłatny', 'zakończone');,
  (15, 15, '2019-01-23', '2019-02-24', 'urlop bezpłatny', 'zakończone');,
  (16, 30, '2019-09-18', '2019-11-30', 'urlop bezpłatny', 'zakończone');,
  (17, 22, '2022-11-07', '2022-12-03', 'chorobowe', 'zakończone');,
  (18, 24, '2022-01-26', '2022-03-10', 'urlop płatny', 'zakończone');,
  (19, 18, '2020-08-08', '2020-09-16', 'urlop bezpłatny', 'zakończone');,
  (20, 29, '2022-09-11', '2022-10-23', 'urlop bezpłatny', 'zakończone');;

INSERT INTO Bilety VALUES
(1, 'firmowy', 'nie', 'I+II+III', 'miesięczny', 'przelew blik', '2023-06-23', '17:33:44', 169.00),
(2, 'firmowy', 'nie', 'I+II', 'miesięczny', 'aplikacja', '2023-04-30', '04:06:44', 144.00),
(3, 'metropolitalny', 'tak', 'II+III', 'miesięczny', 'karta', '2023-06-08', '10:04:37', 84.50),
(4, 'mieszkanca', 'nie', 'I', 'miesięczny', 'przelew blik', '2023-09-13', '04:34:58', 80.00),
(5, 'firmowy', 'nie', 'I+II+III', 'miesięczny', 'aplikacja', '2023-09-20', '04:39:26', 169.00),
(6, 'do kasowania', 'tak', 'I+II+III', '48-godzinny', 'aplikacja', '2023-12-19', '04:51:13', 17.50),
(7, 'do kasowania', 'tak', 'I+II+III', '48-godzinny', 'aplikacja', '2023-08-26', '19:27:03', 17.50),
(8, 'bezrobotny', 'nie', 'I+II', 'miesięczny', 'karta', '2023-04-16', '05:09:04', 50.00),
(9, 'bezrobotny', 'nie', 'I+II+III', 'miesięczny', 'aplikacja', '2023-02-02', '02:38:55', 70.00),
(10, 'socjalny', 'nie', 'I', 'miesięczny', 'karta', '2023-03-08', '14:34:17', 30.00),
(11, 'bezrobotny', 'nie', 'I+II+III', 'miesięczny', 'aplikacja', '2023-03-13', '08:11:36', 70.00),
(12, 'socjalny', 'nie', 'I+II+III', 'miesięczny', 'karta', '2023-08-07', '01:53:11', 70.00),
(13, 'mieszkanca', 'nie', 'I', 'miesięczny 1 linia', 'aplikacja', '2023-05-23', '16:48:42', 80.00),
(14, 'mieszkanca', 'tak', 'I', 'miesięczny', 'gotowka', '2023-03-20', '02:26:25', 40.00),
(15, 'socjalny', 'nie', 'I+II', 'miesięczny', 'gotowka', '2023-12-27', '05:30:36', 50.00);

INSERT INTO Klienci VALUES
(1, 'Piotr', 'Wiśniewski', '2023-03-28', 'piotr.wiśniewski@example.com', '702375572', 'ul. Słoneczna 98, Kraków', '2023-08-16', 'aktywny', 'obowiazuje'),
(2, 'Tomasz', 'Kamiński', '2023-03-29', 'tomasz.kamiński@inbox.com', '699141193', 'ul. Leśna 12, Kraków', '2023-09-14', 'zablokowany', 'obowiazuje'),
(3, 'Marek', 'Wójcik', '2023-08-17', 'marek.wójcik@mail.com', '285271704', 'ul. Klonowa 46, Kraków', '2023-12-29', 'aktywny', 'obowiazuje'),
(4, 'Agnieszka', 'Kowalski', '2023-01-31', 'agnieszka.kowalski@inbox.com', '641448310', 'ul. Słoneczna 72, Kraków', '2023-02-17', 'aktywny', 'obowiazuje'),
(5, 'Agnieszka', 'Zieliński', '2023-11-06', 'agnieszka.zieliński@inbox.com', '350526558', 'ul. Długa 37, Kraków', '2023-01-02', 'aktywny', 'nieobowiazuje'),
(6, 'Tomasz', 'Wójcik', '2023-05-30', 'tomasz.wójcik@mail.com', '766260575', 'ul. Krótka 10, Kraków', '2023-05-17', 'nieaktywny', 'obowiazuje'),
(7, 'Agnieszka', 'Kamiński', '2023-02-08', 'agnieszka.kamiński@mail.com', '236710344', 'ul. Długa 27, Kraków', '2023-09-24', 'zablokowany', 'obowiazuje'),
(8, 'Piotr', 'Lewandowski', '2023-11-10', 'piotr.lewandowski@example.com', '330114129', 'ul. Leśna 92, Kraków', '2023-04-10', 'nieaktywny', 'obowiazuje'),
(9, 'Agnieszka', 'Nowak', '2023-12-29', 'agnieszka.nowak@example.com', '997510367', 'ul. Krótka 73, Kraków', '2023-02-22', 'zablokowany', 'nieobowiazuje'),
(10, 'Monika', 'Dąbrowski', '2023-05-16', 'monika.dąbrowski@mail.com', '258540683', 'ul. Krótka 88, Kraków', '2023-10-27', 'aktywny', 'obowiazuje'),
(11, 'Jan', 'Nowak', '2023-06-24', 'jan.nowak@example.com', '902379093', 'ul. Słoneczna 18, Kraków', '2023-06-24', 'zablokowany', 'nieobowiazuje'),
(12, 'Monika', 'Wiśniewski', '2023-09-17', 'monika.wiśniewski@mail.com', '661229926', 'ul. Długa 17, Kraków', '2023-10-19', 'aktywny', 'obowiazuje'),
(13, 'Agnieszka', 'Wójcik', '2023-11-03', 'agnieszka.wójcik@mail.com', '894493301', 'ul. Krótka 11, Kraków', '2023-07-13', 'nieaktywny', 'nieobowiazuje'),
(14, 'Monika', 'Kowalski', '2023-10-11', 'monika.kowalski@mail.com', '323359304', 'ul. Słoneczna 92, Kraków', '2023-11-05', 'zablokowany', 'nieobowiazuje'),
(15, 'Agnieszka', 'Nowak', '2023-01-05', 'agnieszka.nowak@mail.com', '320861912', 'ul. Klonowa 38, Kraków', '2023-10-07', 'nieaktywny', 'obowiazuje');

INSERT INTO KartyMiejskie  VALUES
(1, 15, 474541, 'aktywna', '2023-12-19', '2023-12-19', '2024-12-18', 'wygasla', 0.00),
(2, 10, 973590, 'aktywna', '2023-05-03', '2023-05-03', '2024-05-02', 'zawieszona', 0.00),
(3, 3, 561385, 'wygasla', '2023-06-07', '2023-06-07', '2024-06-06', 'aktywna', 0.00),
(4, 14, 124824, 'zawieszona', '2023-06-18', '2023-06-18', '2024-06-17', 'zawieszona', NULL),
(5, 8, 771793, 'aktywna', '2023-10-23', '2023-10-23', '2024-10-22', 'aktywna', 0.00),
(6, 1, 328949, 'zawieszona', '2023-04-07', '2023-04-07', '2024-04-06', 'aktywna', 100.00),
(7, 13, 534194, 'aktywna', '2023-05-15', '2023-05-15', '2024-05-14', 'wygasla', 0.00),
(8, 7, 379240, 'wygasla', '2023-09-02', '2023-09-02', '2024-09-01', 'aktywna', 0.00),
(9, 5, 190893, 'zawieszona', '2023-07-15', '2023-07-15', '2024-07-14', 'aktywna', 0.00),
(10, 7, 547017, 'zawieszona', '2023-08-23', '2023-08-23', '2024-08-22', 'wygasla', 0.00),
(11, 8, 272555, 'aktywna', '2023-06-17', '2023-06-17', '2024-06-16', 'wygasla', 0.00),
(12, 1, 217437, 'wygasla', '2023-10-29', '2023-10-29', '2024-10-28', 'zawieszona', 96.50),
(13, 1, 758550, 'aktywna', '2023-08-18', '2023-08-18', '2024-08-17', 'aktywna', 150.55),
(14, 12, 782074, 'wygasla', '2023-09-22', '2023-09-22', '2024-09-21', 'wygasla', 50.55),
(15, 3, 641817, 'wygasla', '2023-04-24', '2023-04-24', '2024-04-23', 'zawieszona', 2.00);


INSERT INTO TransakcjeKartyMiejskie VALUES
(1, 5, NULL, NULL, NULL, 'doladowanie', 50.00, '2023-01-02', "09:23:11")
(2, 7, NULL, '20-minutowy', 'I', 'kupno', 2.00, '2023-01-02', "09:23:11")
(3, 11, NULL, '60-minutowy', 'I', 'kupno', 6.00, '2023-01-02', "09:23:11")
(4, 12, NULL, '60-minutowy', 'I', 'kupno', 6.00, '2023-01-02', "09:23:11")
(5, 15, NULL, '20-minutowy', 'I', 'kupno', 4.00, '2023-01-02', "09:23:11")
(6, 2, NULL, '20-minutowy', 'I', 'kupno', 2.00, '2023-01-02', "09:23:11")
(7, 3, NULL, '60-minutowy', 'I', 'kupno', 6.00, '2023-01-02', "09:23:11")
(8, 1, NULL, NULL, NULL, 'doladowanie', 20.00, '2023-01-02', "09:23:11")
(9, 2, NULL, NULL, NULL, 'doladowanie', 12.50, '2023-01-02', "09:23:11")
(10, 4, NULL, NULL, NULL, 'doladowanie', 10.00, '2023-01-02', "09:23:11")

---------------------------------------------------------------------------------------------------------------
















