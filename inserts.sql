INSERT INTO Pracownicy (imie, nazwisko, idpracownika, stanowisko, dataZatrudnienia, statusZatrudnienia, numerTelefonu, numerPESEL, adresZamieszkania)
VALUES
('Jan', 'Kowalski', 1, '1980-05-20', 'Kierowca autobusu', '2020-01-10', 'aktywny', '+48123456789', '80052012345', 'ul. Floriańska 15, 31-019 Kraków'),
('Anna', 'Nowak', 2,'1990-07-15', 'Kierownik', '2018-05-12', 'aktywny', '+48111222333', '90071523456', 'ul. Grodzka 21, 31-006 Kraków'),
('Piotr', 'Wiśniewski',3, '1975-03-30', 'Mechanik', '2015-09-01', 'urlop', '+48123454321', '75033012345', 'ul. Wawelska 10, 30-102 Kraków'),
('Katarzyna', 'Jabłońska', 4, '1983-08-22', 'Dyspozytor', '2019-06-20', 'aktywny', '+48123456789', '83082212345', 'ul. Dietla 50, 31-070 Kraków'),
('Marcin', 'Lewandowski', 5, '1979-11-09', 'Kierowca tramwaju', '2021-02-15', 'aktywny', '+48123456789', '79110912345', 'ul. Podgórska 34, 31-035 Kraków');

INSERT INTO UmowyPracownikow (idumowy, idpracownika, datarozpoczecia, typumowy, okresTrwania, wynagrodzenie, warunkipracy)
VALUES
(1, 1, '2020-01-10', 'UoP', 2, 4000, 'stacjonarnie'),
(2, 2, '2020-01-10', 'UoP', 3, 4000, 'hybrydowo'),
(3, 3, '2020-01-10', 'UoP', 2, 4000, 'stacjonarnie'),
(4, 4, '2020-01-10', 'UoP', 4, 4000, 'stacjonarnie'),
(5, 5, '2020-01-10', 'UoP', 2, 4000, 'stacjonarnie');

INSERT INTO KierowcyAutobusow (idKierowcy, idPracownika, licencjaOd, licencjaDo)
VALUES
(1,1,'2019-01-01', '2024-01-01');

INSERT INTO KierowcyTramwajow (idkierowcy, idpracownika, licencjaod, licencjado)
VALUES
(1,5, '2015-01-01', '2015-01-01');




