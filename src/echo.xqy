xquery version "1.0-ml";

(
    xdmp:add-response-header("Content-Type", "text/plain"),
    concat(xdmp:get-request-method(), " ", xdmp:get-request-url()),
    xdmp:get-request-path(),
    for $h in xdmp:get-request-header-names() return concat($h, ": ", xdmp:get-request-header($h)),
    for $f in xdmp:get-request-field-names() return concat($f, ": ", string-join(xdmp:get-request-field($f), ", "))
)