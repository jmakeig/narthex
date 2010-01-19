xquery version "1.0-ml";

let $where as xs:string? := xdmp:get-request-field("where")
return xdmp:redirect-response($where)