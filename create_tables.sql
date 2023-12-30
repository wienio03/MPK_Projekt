DROP TABLE IF EXISTS Pracownicy;
DROP TABLE IF EXISTS UmowyPracownikow;
DROP TABLE IF EXISTS KierowcyAutobusow;
DROP TABLE IF EXISTS KierowcyTramwajow;
DROP TABLE IF EXISTS Zwolnienia;
DROP TABLE IF EXISTS KartyMiejskie;
DROP TABLE IF EXISTS Bilety;
DROP TABLE IF EXISTS Klienci;


-- Tworzenie tabel
CREATE TYPE statusPracownika AS ENUM ('zwolnienie', 'aktywny', 'urlop');

CREATE TYPE warunki AS ENUM ('zdalnie', 'stacjonarnie', 'hybrydowe');

CREATE TABLE Pracownicy (
    idPracownika INT PRIMARY KEY,
    imie VARCHAR(40) NOT NULL,
    nazwisko VARCHAR(40) NOT NULL,
    dataUrodzenia date NOT NULL,
    stanowisko VARCHAR(40) NOT NULL,
    dataZatrudnienia DATE NOT NULL,
    statusZatrudnienia statusPracownika NOT NULL,
    numerTelefonu VARCHAR(12) NOT NULL
);

CREATE TABLE UmowyPracownikow (
    idUmowy INT NOT NULL,
    idPracownika INT REFERENCES Pracownicy(idPracownika),
    dataRozpoczecia date NOT NULL,
    typUmowy VARCHAR(20) NOT NULL,
    okresTrawania INT NOT NULL,
    wynagrodzenie MONEY NOT NULL,
    warunkiPracy warunki NOT NULL
);

CREATE TABLE KierowcyAutobusow (
    idKierowcy INT PRIMARY KEY,
    idPracownika INT REFERENCES Pracownicy(idPracownika),
    licencjaOd DATE NOT NULL,
    licencjaDo DATE NOT NULL
);

CREATE TABLE KierowcyTramwajow (
    idKierowcy INT PRIMARY KEY,
    idPracownika INT REFERENCES Pracownicy(idPracownika),
    licencjaOd DATE NOT NULL,
    licencjaDo DATE NOT NULL
);

CREATE TYPE typZwolnienia AS ENUM ('chorobowe', 'urlop');

CREATE TYPE statusZwolnienia AS ENUM ('zaakceptowany', 'oczekujacy');

CREATE TABLE Zwolnienia (
    idZwolnienia INT PRIMARY KEY,
    idPracownika INT REFERENCES Pracownicy(idPracownika),
    dataRozpoczecia DATE NOT NULL,
    dataZakonczenia DATE NOT NULL,
    typ typZwolnienia NOT NULL,
    status statusZwolnienia NOT NULL
);

CREATE TYPE typBiletu as ENUM ('normalny', 'ulgowy', 'metropolitalny', 'mieszkanca',
    'socjalny', 'bezrobotny', 'firmowy');

CREATE TYPE zasiegBiletu as ENUM ('I', 'II', 'III', 'I+II', 'II+III',
    'I+II+III');

CREATE TYPE okresBiletu as ENUM ('20-minutowy', '60-minutowy',
    '90-minutowy', '24-godzinny', '48-godzinny', '72-godzinny,'
    '7-dniowy', 'weekendowy'
);

CREATE TYPE metodaPlatnosci as ENUM('karta', 'gotowka', 'przelew', 'mobilna');

CREATE TYPE miejsceKupna as ENUM('kasownik', 'elektronicznie');

CREATE SEQUENCE id_seq
START WITH 1
INCREMENT BY 1
NO MINVALUE
NO MAXVALUE
CACHE 1; -- dla szybszego dostepu do nastepnej liczby z pamieci

CREATE TABLE Bilety (
    idBiletu INT PRIMARY KEY DEFAULT nextval(id_seq),
    typ typBiletu NOT NULL,
    zasieg zasiegBiletu NOT NULL,
    okres okresBiletu NOT NULL,
    platnosc metodaPlatnosci NOT NULL,
    kupno miejsceKupna NOT NULL,
    dataWydania DATE NOT NULL,
    czasWydania TIME NOT NULL,
    cena MONEY NOT NULL
);

CREATE TYPE statusKlienta AS ENUM ('aktywny', 'nieaktywny', 'zablokowany');

CREATE TYPE statusZnizki AS ENUM ('obowiazuje', 'nieobowiazuje');

CREATE TABLE Klienci (
    idKlienta INT PRIMARY KEY DEFAULT nextval(id_seq),
    imie VARCHAR(40) NOT NULL,
    nazwisko VARCHAR(40) NOT NULL,
    dataUrodzenia DATE NOT NULL,
    email varChar(80) DEFAULT NULL,
    numerTelefonu varChar(12) NOT NULL,
    adresZamieszkania varChar(80) NOT NULL,
    dataRejestracji DATE NOT NULL,
    status statusKlienta NOT NULL,
    znizka statusZnizki NOT NULL
);


CREATE TYPE typKarty AS ENUM ('legitymacja studencka/doktorska',
    'standardowa', 'senior');

CREATE TYPE statusKarty AS ENUM ('aktywna', 'zawieszona', 'wygasla');

CREATE TABLE KartyMiejskie (
    idKarty INT PRIMARY KEY DEFAULT nextval(id_seq),
    idKlienta INT REFERENCES Klienci(idKlienta),
    numerKarty INT NOT NULL,
    typ typKarty NOT NULL,
    dataWydania DATE NOT NULL,
    waznaOd DATE NOT NULL,
    waznaDo DATE NOT NULL,
    status statusKarty NOT NULL,
    saldo MONEY DEFAULT NULL
)












