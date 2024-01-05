CREATE extension plpythonu;

CREATE OR REPLACE FUNCTION czasPodrozy(zajezdnia text, przystanek text)
 RETURNS text
 LANGUAGE plpythonu
 AS $function$
    import requests, json
    try:
        url =https://maps.googleapis.com/maps/api/distancematrix/json
  ?destinations=New%20York%20City%2C%20NY
  &origins=Washington%2C%20DC%7CBoston
  &units=imperial
  &key=YOUR_API_KEY
        wynik = requests.request
$function$