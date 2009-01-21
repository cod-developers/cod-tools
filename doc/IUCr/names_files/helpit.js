function getElementsByClass(searchClass,node,tag) {
	var classElements = new Array();
	if ( node == null )
		node = document;
	if ( tag == null )
		tag = '*';
	var els = node.getElementsByTagName(tag);
	var elsLen = els.length;
	var pattern = new RegExp("(^|\\s)"+searchClass+"(\\s|$)");
	for (i = 0, j = 0; i < elsLen; i++) {
		if ( pattern.test(els[i].className) ) {
			classElements[j] = els[i];
			j++;
		}
	}
	return classElements;
}


function blankTitleAlt(searchClass,tag) {
  var myEls = getElementsByClass(searchClass,null,tag);
  for ( i=0;i<myEls.length;i++ ) {
    // do stuff here with myEls[i]
    //alert( myEls[i].getAttribute("title") );
    myEls[i].setAttribute("title", "");
  }
}

function blankJavascriptHint(id) {
  document.getElementById(id).style.visibility = "hidden";
}
