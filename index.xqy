xquery version "1.0-ml";
import module namespace search = "http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";

declare variable $options := 
  <options xmlns="http://marklogic.com/appservices/search">
	<transform-results apply="snippet">
		<preferred-elements>
			<element name="Abstract"/>
		</preferred-elements>
	</transform-results>

	(: sort :)
	<search:operator name="sort">
		<search:state name="relevance">
			<search:sort-order direction="descending">
				<search:score/>
			</search:sort-order>
		</search:state>
		<search:state name="newest">
			<search:sort-order direction="descending" type="xs:date">
                <path-index>PubmedArticle//PubDate/Year</path-index>
			</search:sort-order>
			<search:sort-order>
				<search:score/>
			</search:sort-order>
		</search:state>
		<search:state name="oldest">
			<search:sort-order direction="ascending" type="xs:date">
                <path-index>/PubmedArticle//PubDate/Year</path-index>
			</search:sort-order>
			<search:sort-order>
				<search:score/>
			</search:sort-order>
		</search:state>
		<search:state name="title">
			<search:sort-order direction="ascending" type="xs:string">
				<search:element  name="Title"/>
			</search:sort-order>
			<search:sort-order>
				<search:score/>
			</search:sort-order>
		</search:state>
	</search:operator>
  </options>;

declare function local:result-controller() {
	if(xdmp:get-request-field("uri"))
	then local:magazine-detail()  
	else local:search-results()
};


(: gets the current sort argument from the query string :)
declare function local:get-sort($q){
    fn:replace(fn:tokenize($q," ")[fn:contains(.,"sort")],"[()]","")
};

(: adds sort to the search query string :)
declare function local:add-sort($q){
    let $sortby := local:sort-controller()
    return
        if($sortby)
        then
            let $old-sort := local:get-sort($q)
            let $q :=
                if($old-sort)
                then search:remove-constraint($q,$old-sort,$options)
                else $q
            return fn:concat($q," sort:",$sortby)
        else $q
}; 

(: determines if the end-user set the sort through the drop-down or through editing the search text field or came from the advanced search form :)
declare function local:sort-controller(){
    if(xdmp:get-request-field("advanced")) 
    then 
        let $order := fn:replace(fn:substring-after(fn:tokenize(xdmp:get-request-field("q","sort:relevance")," ")[fn:contains(.,"sort")],"sort:"),"[()]","")
        return 
            if(fn:string-length($order) lt 1)
            then "relevance"
            else $order
    else if(xdmp:get-request-field("submitbtn") or not(xdmp:get-request-field("sortby")))
    then 
        let $order := fn:replace(fn:substring-after(fn:tokenize(xdmp:get-request-field("q","sort:newest")," ")[fn:contains(.,"sort")],"sort:"),"[()]","")
        return 
            if(fn:string-length($order) lt 1)
            then "relevance"
            else $order
    else xdmp:get-request-field("sortby")
};

(: builds the sort drop-down with appropriate option selected :)
declare function local:sort-options(){
    let $sortby := local:sort-controller()
    let $sort-options := 
            <options>
                <option value="relevance">relevance</option>   
                <option value="newest">newest</option>
                <option value="oldest">oldest</option>
                <option value="author">author</option>
                <option value="title">title</option>
            </options>
    let $newsortoptions := 
        for $option in $sort-options/*
        return 
            element {fn:node-name($option)}
            {
                $option/@*,
                if($sortby eq $option/@value)
                then attribute selected {"true"}
                else (),
                $option/node()
            }
    return 
        <div id="sortbydiv">
             sort by: 
                <select name="sortby" id="sortby" onchange='this.form.submit()'>
                     {$newsortoptions}
                </select>
        </div>
};


declare function local:pagination($resultspag)
{
    let $start := xs:unsignedLong($resultspag/@start)
    let $length := xs:unsignedLong($resultspag/@page-length)
    let $total := xs:unsignedLong($resultspag/@total)
    let $last := xs:unsignedLong($start + $length -1)
    let $end := if ($total > $last) then $last else $total
    let $qtext := $resultspag/search:qtext[1]/text()
    let $next := if ($total > $last) then $last + 1 else ()
    let $previous := if (($start > 1) and ($start - $length > 0)) then fn:max((($start - $length),1)) else ()
    let $next-href := 
         if ($next) 
         then fn:concat("/index.xqy?q=",if ($qtext) then fn:encode-for-uri($qtext) else (),"&amp;start=",$next,"&amp;submitbtn=page")
         else ()
    let $previous-href := 
         if ($previous)
         then fn:concat("/index.xqy?q=",if ($qtext) then fn:encode-for-uri($qtext) else (),"&amp;start=",$previous,"&amp;submitbtn=page")
         else ()
    let $total-pages := fn:ceiling($total div $length)
    let $currpage := fn:ceiling($start div $length)
    let $pagemin := 
        fn:min(for $i in (1 to 4)
        where ($currpage - $i) > 0
        return $currpage - $i)
    let $rangestart := fn:max(($pagemin, 1))
    let $rangeend := fn:min(($total-pages,$rangestart + 4))
    
    return (
        <div id="countdiv"><b>{$start}</b> to <b>{$end}</b> of {$total}</div>,
        local:sort-options(),
        if($rangestart eq $rangeend)
        then ()
        else
            <div id="pagenumdiv"> 
               { if ($previous) then <a href="{$previous-href}" title="View previous {$length} results"><img src="images/prevarrow.gif" class="imgbaseline"  border="0" /></a> else () }
               {
                 for $i in ($rangestart to $rangeend)
                 let $page-start := (($length * $i) + 1) - $length
                 let $page-href := concat("/index.xqy?q=",if ($qtext) then encode-for-uri($qtext) else (),"&amp;start=",$page-start,"&amp;submitbtn=page")
                 return 
                    if ($i eq $currpage) 
                    then <b>&#160;<u>{$i}</u>&#160;</b>
                    else <span class="hspace">&#160;<a href="{$page-href}">{$i}</a>&#160;</span>
                }
               { if ($next) then <a href="{$next-href}" title="View next {$length} results"><img src="images/nextarrow.gif" class="imgbaseline" border="0" /></a> else ()}
            </div>
    )
};

declare function local:search-results(){

	let $start :=xs:unsignedLong(xdmp:get-request-field("start"))
    let $q := local:add-sort(xdmp:get-request-field("q", "sort:newest"))
	let $results := search:search($q, $options, $start)
	let $items :=
		for $magazine in $results/search:result
		let $uri := fn:data($magazine//@uri)
		let $magazine-doc := fn:doc($uri)
		return 
		  <div>
			 <div class="magazine">"{$magazine-doc//Title/text()}" by {$magazine-doc//Author[1]/LastName/text()}</div>
			 <div class="date"> Publish Date: {fn:data($magazine-doc//PubDate/Year)}</div>    
			 <div class="abstract">{local:desc($magazine)}&#160;
				<a href="index.xqy?uri={xdmp:url-encode($uri)}">[more]</a>
			 </div>
		  </div>
	return 
		if($items) 
		then (local:pagination($results), $items)
		else <div>Sorry, no  results  for your search.<br/><br/><br/></div>
};

declare function local:desc($magazine){
	for $text in $magazine/search:snippet/search:match/node()
		return
	if(fn:node-name($text) eq xs:QName("search:highlight"))
	then <span id="highlight">{$text/text()}</span>
	else $text
};
(: 
declare function local:default-results(){
	(for $magazine in /PubmedArticle 		 
		return (<div>
			 <div class="magazine">"{$magazine//Title/text()}" by {$magazine//Author[1]/LastName/text()}</div>
			 <div class="date"> Publish Date: {fn:data($magazine//PubDate/Year)}</div>    
			 <div class="abstract">{fn:tokenize($magazine//Abstract, " ") [1 to 70]} ...&#160;
				<a href="index.xqy?uri={xdmp:url-encode($magazine/@uri)}">[more]</a>
			</div>
			</div>)	   	
	)[1 to 10]
}; :)

declare function local:magazine-detail(){
	let $uri := xdmp:get-request-field("uri")
	let $magazine := fn:doc($uri) 
	return <div>
		<div class="magazine-large">"{$magazine//Title/text()}"</div>
		<div class="date"> Publish Date: {fn:data($magazine//PubDate/Year)}</div>    
		{if ($magazine//Author[1]/LastName/text()) then <div class="detailitem">Author: {$magazine//Author[1]/LastName/text()}</div> else ()}
		{if ($magazine//Abstract) then <div class="detailitem">{$magazine//Abstract}</div> else ()}
		</div>
};


xdmp:set-response-content-type("text/html; charset=utf-8"),
'<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">',
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
	<title>Pub Med</title>
	<link href="css/style.css" rel="stylesheet" type="text/css"/>
	<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0/css/bootstrap.min.css" integrity="sha384-Gn5384xqQ1aoWXA+058RXPxPg6fy4IWvTNh0E263XmFcJlSAwiGgFAW/dAiS6JXm" crossorigin="anonymous"/>  
  </head>
  <body>
    <div class="container-0">
      <nav class="navbar navbar-expand-lg navbar-dark bg-dark">
        <a class="navbar-brand px-4 py-2" href="#">Magazine</a>
        <div class="collapse navbar-collapse" id="navbarSupportedContent">
          <ul class="navbar-nav mr-auto">
            <li class="nav-item active">
              <a class="nav-link" href="#">Home</a>
            </li>
            <li class="nav-item active">
              <a class="nav-link" href="#">About</a>
            </li>
          </ul>
        </div>
      </nav>
      <div class ="row py-4">
        <div class="col-4 text-center">
          <p>Facet Content Here</p> 
        </div>
        <div class="w-100 mx-auto col-8">
          <form class="form-inline my-2 my-lg-0" name="form1" method="get" action="index.xqy" id="form1">
              <input class="form-control w-50 mr-sm-2" type="text" name="q" id="q" placeholder="Search" value="{local:add-sort(xdmp:get-request-field("q"))}"/>
              <button class="btn btn-outline-success my-2 my-sm-0" type="submit" id="submitbtn" name="submitbtn" value="search">Search</button>
          </form>

		  <div id="detaildiv">
			{  local:result-controller()  }  	
	  	  </div>
        </div>
	  </div>
    </div>  
	<div id="footer"></div>
	</body>
</html>
