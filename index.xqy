xquery version "1.0-ml";
import module namespace search = "http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";

declare variable $options := 
  <options xmlns="http://marklogic.com/appservices/search">
	<transform-results apply="raw"/>
  </options>;

declare function local:result-controller() {
	if(xdmp:get-request-field("q"))
	then local:search-results()
	else if(xdmp:get-request-field("uri"))
	then local:magazine-detail()  
	else local:default-results()
};

declare function local:search-results()
{
    let $q := xdmp:get-request-field("q")
	let $results :=
		for $magazine in search:search($q, $options)/search:result
		return 
		  <div>
			 <div class="magazine">"{$magazine//Title/text()}" by {$magazine//Author[1]/LastName/text()}</div>
			 <div class="date"> Publish Date: {fn:data($magazine//PubDate/Year)}</div>    
			 <div class="abstract">{fn:tokenize($magazine//Abstract, " ") [1 to 70]} ...&#160;
				<a href="index.xqy?uri={xdmp:url-encode($magazine/@uri)}">[more]</a>
			 </div>
		  </div>
	return 
		if($results) 
		then $results
		else <div>Sorry, no  results  for your search.<br/><br/><br/></div>
};

declare function local:default-results()
{
	(for $magazine in /PubmedArticle 		 
		return (<div>
			 <div class="magazine">"{$magazine//Title/text()}" by {$magazine//Author[1]/LastName/text()}</div>
			 <div class="date"> Publish Date: {fn:data($magazine//PubDate/Year)}</div>    
			 <div class="abstract">{fn:tokenize($magazine//Abstract, " ") [1 to 70]} ...&#160;
				<a href="index.xqy?uri={xdmp:url-encode($magazine/@uri)}">[more]</a>
			</div>
			</div>)	   	
	)[1 to 10]
};

declare function local:magazine-detail()
{
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
          <form class="form-inline my-2 my-lg-0" name="search" method="get" action="index.xqy" id="search">
              <input class="form-control w-50 mr-sm-2" type="text" name="q" id="q" placeholder="Search"/>
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
