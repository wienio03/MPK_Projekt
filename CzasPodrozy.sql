CREATE EXTENSION plpython3u;

CREATE OR REPLACE FUNCTION czasPodrozy(adresZajezdni text, adresObecny text)
 RETURNS text
 AS $$
    import requests, json
    url = 'https://maps.googleapis.com/maps/api/distancematrix/json'
    parametry = {
        'destinations' : adresObecny',
        'origins': adresZajezdni,
        'units': 'metric',
        'key' : 'TODO'
    }
    wynik = requests.get(url, params=parametry)
    return(wynik.json()['rows'][0]['elements'][0]['duration']['text'])
    // zwraca zapis tekstowy przewidywanego czasu podrozy
$$
 LANGUAGE plpython3u;
