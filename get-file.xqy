xquery version "1.0-ml";

let $uri := xdmp:get-request-field("uri")
let $mimetype := xdmp:uri-content-type($uri) 
return
 if(fn:doc($uri))
 then
    (
        xdmp:set-response-content-type($mimetype),
        fn:doc($uri)
    )
 else ()