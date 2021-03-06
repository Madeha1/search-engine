xquery version "1.0-ml";
import module namespace search = "http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";

declare variable $options := 
  <options xmlns="http://marklogic.com/appservices/search">

  (: search on specific element :)
 <constraint name="articalTitle">
    <container>
      <element name="ArticleTitle"/>
    </container>
  </constraint>
  <constraint name="author">
    <container>
      <element name="LastName"/>
    </container>
  </constraint>
  (:auto complete:)
   <default-suggestion-source>
    <range type="xs:string">
      <element name="articalTitle"/>
   </range>
  </default-suggestion-source> 
  (: facits :)
  <constraint name="PubDate">
    <range type="xs:gYear">
      <bucket ge="2020" name="2020s">2020s</bucket>
      <bucket lt="2020" ge="2010" name="2010s">2010s</bucket>
      <bucket lt="2010" ge="2000" name="2000s">2000s</bucket>
      <bucket lt="2000" ge="1990" name="1990s">1990s</bucket>
      <bucket lt="1990" ge="1980" name="1980s">1980s</bucket>
      <bucket lt="1980" ge="1970" name="1970s">1970s</bucket>
      <bucket lt="1970" ge="1960" name="1960s">1960s</bucket>
      <bucket lt="1960" ge="1950" name="1950s">1950s</bucket>
      <bucket lt="1950" name="1940s">1940s</bucket>
      <field name="PubDate"/>
      <facet-option>limit=10</facet-option>
    </range>
  </constraint>
  <constraint name="PublicationType">
    <range type="xs:string" collation="http://marklogic.com/collation/en/S1/AS/T00BB">
     <element name="PublicationType"/>
     <facet-option>limit=20</facet-option>
     <facet-option>frequency-order</facet-option>
     <facet-option>descending</facet-option>
    </range>
  </constraint>
    (: Snippet :)
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
			<search:sort-order direction="descending" type="xs:gYear">
        <field name="PubDate"/>
			</search:sort-order>
			<search:sort-order>
				<search:score/>
			</search:sort-order>
		</search:state>
		<search:state name="oldest">
			<search:sort-order direction="ascending" type="xs:gYear">
        <field name="PubDate"/>
			</search:sort-order>
			<search:sort-order>
				<search:score/>
			</search:sort-order>
		</search:state>
		<search:state name="title">
			<search:sort-order direction="ascending" type="xs:string">
				<search:element  name="ArticleTitle"/>
			</search:sort-order>
			<search:sort-order>
				<search:score/>
			</search:sort-order>
		</search:state>
	</search:operator>
  </options>;

  declare variable $facet-size as xs:integer := 8;
  declare variable $results :=  let $q := xdmp:get-request-field("q", "sort:newest")
                              let $q := local:add-sort($q)
                              return  search:search($q, $options, xs:unsignedLong(xdmp:get-request-field("start","1")));


declare function local:result-controller() {
	if(xdmp:get-request-field("uri"))
	then local:magazine-detail()  
	else local:search-results()
};

(: builds the search drop-down with appropriate option selected :)
declare function local:search-by-options(){
    let $searchby := local:search-by-controller()
    let $search-options := 
            <options>
                <option value="all">All</option>   
                <option value="articalTitle">Title</option>
                <option value="author">Author</option>

            </options>
    let $newSearchOptions := 
        for $option in $search-options/*
        return 
            element {fn:node-name($option)}
            {
                $option/@*,
                if($searchby eq $option/@value)
                then attribute selected {"true"}
                else (),
                $option/node()
            }
    return 
        <div>
             &#160;&#160; Search by: 
                <select class="form-select" aria-label="Default select example" name="searchby" onchange='this.form.submit()'>
                     {$newSearchOptions}
                </select>
        </div>

};

declare function local:search-by-controller(){
    xdmp:get-request-field("searchby")
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

(: determines if the end-user set the sort through the drop-down or through editing the search text field:)
declare function local:sort-controller(){
    if(xdmp:get-request-field("submitbtn") or not(xdmp:get-request-field("sortby")))
    then 
    (: gets the word after sort and ignors the words befor it :)
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
        <div>
             &#160;&#160; sort by: 
                <select class="form-select" aria-label="Default select example" name="sortby" onchange='this.form.submit()'>
                     {$newsortoptions}
                </select>
        </div>
};


declare function local:pagination($resultspag)
{
  (: from search result <search:response> :)
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
        <div id="countdiv" style="text-align: right"><b>{$start}</b> to <b>{$end}</b> of {$total}</div>,
        if($rangestart eq $rangeend)
        then ()
        else
            <div id="pagenumdiv" style="text-align: left"> 
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
  let $searchby := xdmp:get-request-field("searchby")
  let $q2 := 
  if ($searchby eq 'author')
  then 'author'
  else if ($searchby eq 'articalTitle')
  then 'articalTitle'
  else ''
	let $start :=xs:unsignedLong(xdmp:get-request-field("start"))
    let $q := local:add-sort(xdmp:get-request-field("q", "sort:newest"))
    let $q := if($q2 ne '') then
      fn:concat($q2,":", $q)
      else $q
	let $results := search:search($q, $options, $start)
	let $items :=
		for $magazine in $results/search:result
		let $uri := fn:data($magazine//@uri)
		let $magazine-doc := fn:doc($uri)
		return 
		  <div>
			 <div class="magazine">"{$magazine-doc//ArticleTitle/text()}"</div>
       <div class="authors">
          {for $authors in $magazine-doc//Author 
          return <span >{$authors/LastName/text()}, </span>
          }
        </div>
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

declare function local:magazine-detail(){
	let $uri := xdmp:get-request-field("uri")
	let $magazine := fn:doc($uri) 
	return <div>
		<div class="magazine-large">"{$magazine//ArticleTitle/text()}"</div>
		<div class="date"> Publish Date: {fn:data($magazine//PubDate/Year)}</div>    
    <div class="authors">
          {for $authors in $magazine//Author 
          return <span >{$authors/LastName/text()}, </span>
          }
    </div>
		{if ($magazine//Abstract) then <div class="detailitem">{$magazine//Abstract}</div> else ()}
		</div>
};

(: start facet function :)
declare function local:facets()
{
    for $facet in $results/search:facet
    let $facet-count := fn:count($facet/search:facet-value)
    let $facet-name := fn:data($facet/@name)
    return
        if($facet-count > 0)
        then <div class="facet">
                <div class="purplesubheading"><img src="images/checkblank.gif"/>{$facet-name}</div>
                {
                    let $facet-items :=
                        for $val in $facet/search:facet-value
                        let $print := if($val/text()) then $val/text() else "Unknown"
                        let $qtext := ($results/search:qtext)
                        let $sort := local:get-sort($qtext)
                        let $this :=
                            if (fn:matches($val/@name/string(),"\W"))
                            then fn:concat('"',$val/@name/string(),'"')
                            else if ($val/@name eq "") then '""'
                            else $val/@name/string()
                        let $this := fn:concat($facet/@name,':',$this)
                        let $selected := fn:matches($qtext,$this,"i")
                        let $icon := 
                            if($selected)
                            then <img src="images/checkmark.gif"/>
                            else <img src="images/checkblank.gif"/>
                        let $link := 
                            if($selected)
                            then search:remove-constraint($qtext,$this,$options)
                            else if(string-length($qtext) gt 0)
                            then fn:concat("(",$qtext,")"," AND ",$this)
                            else $this
                        let $link := if($sort and fn:not(local:get-sort($link))) then fn:concat($link," ",$sort) else $link
                        let $link := fn:encode-for-uri($link)
                        return
                            <div class="facet-value">{$icon}<a href="index.xqy?q={$link}">
                            {fn:lower-case($print)}</a> [{fn:data($val/@count)}]</div>
                     return (
                                <div>{$facet-items[1 to $facet-size]}</div>,
                                if($facet-count gt $facet-size)
                                then (
									<div class="facet-hidden" id="{$facet-name}">{$facet-items[position() gt $facet-size]}</div>,
									<div class="facet-toggle" id="{$facet-name}_more"><img src="images/checkblank.gif"/><a href="javascript:toggle('{$facet-name}');" class="white">more...</a></div>,
									<div class="facet-toggle-hidden" id="{$facet-name}_less"><img src="images/checkblank.gif"/><a href="javascript:toggle('{$facet-name}');" class="white">less...</a></div>
								)                                 
                                else ()   
                            )
                }          
            </div>
         else <div>&#160;</div>
};
(: end facet function :)

xdmp:set-response-content-type("text/html; charset=utf-8"),
'<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">',
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
	<title>Pub Med</title>
	<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0/css/bootstrap.min.css" integrity="sha384-Gn5384xqQ1aoWXA+058RXPxPg6fy4IWvTNh0E263XmFcJlSAwiGgFAW/dAiS6JXm" crossorigin="anonymous"/>  
  <link href="css\style.css" rel="stylesheet"/>
  <script type="" src="/js/magazine.js"></script> 
  <script type="text/javascript" src="/autocomplete/lib/prototype/prototype.js"></script> 
  <script type="text/javascript" src="/autocomplete/lib/scriptaculous/scriptaculous.js"></script> 
  <script type="text/javascript" src="/autocomplete/src/AutoComplete.js"></script>
  <script type="text/javascript" src="/autocomplete/src/lib.js"></script>
</head>
<body>
  <div class="container-0">
    <nav class="navbar-expand-lg navbar navbar-light" style="background-color: #e3f2fd">
      <a class="navbar-brand px-4 py-2" href="http://localhost:8051">Magazine</a>
      <div class="collapse navbar-collapse" id="navbarSupportedContent">
        <ul class="navbar-nav mr-auto">
          <li class="nav-item active">
            <a class="nav-link" href="http://localhost:8051">Home</a>
          </li>
          <li class="nav-item active">
            <a class="nav-link" href="#">About</a>
          </li>
        </ul>
      </div>
    </nav>

    <div>
      <br/>
    </div>
    <div class ="row">
      <div class="col-4 text-left">
        <p class="text-center">Facet Content Here</p> 
          <img src="images/checkblank.gif"/>{local:facets()}
      </div>
      <div class="col-8">
        <form class="form-inline my-2 my-lg-0" name="form1" method="get" action="index.xqy" id="form1">
          <div id="searchdiv">
            <input autocomplete="off" class="form-control w-1600 mr-sm-2" type="text" name="q" id="q" placeholder="Search" value="{local:add-sort(xdmp:get-request-field("q"))}"/>
            <button class="btn btn-outline-dark" type="submit" id="submitbtn" name="submitbtn" value="search">Search</button>
          </div>
            {local:sort-options()}
            {local:search-by-options()}
        </form>
          <div id="detaildiv">
            { local:result-controller() }  	
          </div>
      </div>
    </div>
  </div>

  <!-- Footer -->
  <footer class="page-footer font-small blue">

    <!-- Copyright -->
    <div class="footer-copyright text-center py-3">?? 2021 Copyright:
      <a href="#"> Magazine.com</a>
    </div>
    <!-- Copyright -->

  </footer>
  <!-- Footer -->  
</body>
</html>