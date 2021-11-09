(: Madeha Tahboub & Shahd Madhoun :)
xquery version "1.0-ml";

import module namespace search ="http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";    

declare option xdmp:mapping "false";
(: This line is required in v4.2 of ML Server for JavaScript to function properly :) 
declare option xdmp:output 'indent=no';

declare variable $options as node() := 
    <options xmlns="http://marklogic.com/appservices/search">
    (: search suggestion on title :)
        <default-suggestion-source>
            <constraint name="searchable">
                <range type="xs:string" collation="http://marklogic.com/collation/en/S1/AS/T00BB">
                    <field name="searchable"/>
                </range>
            </constraint>
        </default-suggestion-source> 
    </options>;

(: cts:query way :)
declare function local:get-suggestions($qname as xs:string,$q as xs:string){
    for $i in cts:element-value-match(xs:QName($qname),fn:concat("*",$q,"*"))
    return element suggestion {$i}
};

let $q := xdmp:get-request-field("q")
return
    if($q)
    then
        <Suggestions>
            {local:get-suggestions("searchable",$q)}
        </Suggestions>
    else ()