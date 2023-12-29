DROP TABLE IF EXISTS ModeleAutobusow;
CREATE TABLE ModeleAutobusow (
    model VARCHAR(40),
    producent VARCHAR(40),
    dlugosc INT,
    szerokosc INT,
    wysokosc INT,
    rozstawOsi INT,
    masaWlasna INT,
    miejsca INT,
    miejscaSiedzace INT,
    producentSilnika VARCHAR(40),
    pojemnoscSilnika INT,
    mocSilnikaKM INT,
    niskopodlogowy BOOLEAN

)