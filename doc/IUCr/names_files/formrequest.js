var eleid;

function makeRequest(url, formid, seteleid) {
  eleid = seteleid;
  if (window.XMLHttpRequest) {
    request = new XMLHttpRequest();
  } else if (window.ActiveXObject) {
    request = new ActiveXObject("MSXML2.XMLHTTP");
  }
  sendRequest(url, formid);
}

function sendRequest(url, formid) {
  setQueryString(formid);
  request.onreadystatechange=onResponse; 
  request.open("POST",url,true);
  request.setRequestHeader("Content-Type", "application/x-www-form-urlencoded; charset=UTF-8");
  request.send(queryString);
}
    
function checkReadyStatus(obj) {
  if (obj.readyState == 0) {
    document.getElementById(eleid).innerHTML="<b>Please wait</b>";
    // uninitialised
  }
  if (obj.readyState == 1) {
    // loading
    document.getElementById(eleid).innerHTML="<b>loading</b>";
  }
  if (obj.readyState == 2) {
    // loaded
    document.getElementById(eleid).innerHTML="<b>loaded</b>";
  }
  if (obj.readyState == 3) {
    // interactive
    document.getElementById(eleid).innerHTML="<b>not long now</b>";
  }
  if (obj.readyState == 4) {
    // complete
    if (obj.status == 200) {
      // successfully loaded
      return true;
    } else {
      return "there was a problem retrieving the XML.";
    }
  }
}

function onResponse() {
  if (checkReadyStatus(request)) {
    document.getElementById(eleid).innerHTML=request.responseText;
  }
}


function setQueryString(formid){
  queryString="";
  var frm = document.getElementById(formid);
  var numberElements =  frm.elements.length;
  for(var i = 0; i < numberElements; i++)  {
    if(i < numberElements-1)  {
      queryString += frm.elements[i].name+"="+
	encodeURIComponent(frm.elements[i].value)+"&";
    } else {
      queryString += frm.elements[i].name+"="+
	encodeURIComponent(frm.elements[i].value);
    }   
  }
}
