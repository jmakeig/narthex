xquery version "1.0-ml";

(: TODO: This should handle more than 404s :)
xdmp:set-response-code(404, "Not found"),
"404 Not found"