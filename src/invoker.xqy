xquery version "1.0-ml";
let $db := xdmp:get-request-field("db", string(xdmp:database("Documents")))
return xdmp:invoke(
  xdmp:get-request-field("_path"),
  (),
  <options xmlns="xdmp:eval">
    <database>{$db}</database>
  </options>
)