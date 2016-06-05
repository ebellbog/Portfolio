<?php
    //get private ID

    session_name('Private');
    session_start();
    $p = session_id();
    session_write_close();

    session_name('Global');
    session_id('shared-rooms');
    session_start();

    if (!isset($_SESSION['rooms'])) { //initialize array if needed
       $_SESSION['rooms'] = array(
            'r1' => 'open',
            'r2' => 'open',
            'r3' => 'open',
            'r4' => 'open',
            'r5' => 'open',
        );
    }
    $rooms = $_SESSION['rooms'];

    if (!isset($_SESSION['audio_sessions'])) $_SESSION['audio_sessions'] = array();
    if (!isset($_SESSION['audio_sessions'][$p])) {
        $_SESSION['audio_sessions'][$p] = array(
            'r1' => array(),
            'r2' => array(),
            'r3' => array(),
            'r4' => array(),
            'r5' => array(),
        );
    }

    session_write_close();
?>

<html>
 <head>
  <title>Audio Room Assignment</title>
    <script>

    gameInProgress = 0;
    assignedRooms = [0, 0, 0, 0, 0];

    /*window.onbeforeunload = function(event){
        window.alert('hi');
        return 1;
    };*/

    function playAlert() {
        var alertSound = document.getElementById("alert");
        alertSound.play();
    }

    function startGame() {
        var gameButton = document.getElementById("gameButton");
        var form = document.getElementById("rooms");

        if (gameInProgress == 0) {
            gameButton.innerText = "End game";
            form.disabled = 1;
            gameInProgress = 1;
            checkAudio(); //restart alert loop
        } else {
            gameButton.innerText = "Start game";
            form.disabled = 0;
            gameInProgress = 0;
            updateList('0'); //restart refresh loop
        }
    }

    function updateList(list_item) {
        if (window.XMLHttpRequest) {
            xmlhttp= new XMLHttpRequest();
        }

        xmlhttp.onreadystatechange=function(){
            if (xmlhttp.readyState == 4 && xmlhttp.status == 200) {
                //handle callback stuff here!
                var response = xmlhttp.responseText;
                var newText;
                for(var i = 1; i < 6; i++) {
                    newText = "Room "+ i.toString() + " - ";

                    var x = parseInt(response.charAt(i-1));
                    if (x == 0) newText += "open";
                    else if (x == 1) newText += "mine";
                    else if (x == 2) newText += "unavailable";

                    document.getElementById("r"+i.toString()).innerHTML = newText;
                }

                assignedRooms = response.split("");
                if (!gameInProgress) setTimeout(function(){updateList('0')}, 1000); //disable once game started
            }
        }

        xmlhttp.open("GET","rooms.php?pid=<?=$p?>"+"&room="+list_item,true);
        xmlhttp.send();
    }

    function checkAudio() {
        if (window.XMLHttpRequest) {
            xmlhttp= new XMLHttpRequest();
        }

        xmlhttp.onreadystatechange=function(){
            if (xmlhttp.readyState == 4 && xmlhttp.status == 200) {
                var alert_array = xmlhttp.responseText.split(',');
                for (var i = 0; i < 5; i++) {
                    if (assignedRooms[i] == 1) handleAlert(parseInt(alert_array[i]));
                }

                if (gameInProgress) setTimeout(function(){checkAudio()}, 1000);
            }
        }

        xmlhttp.open("GET","deploy_audio.php?action=check&pid=<?=$p?>",true);
        xmlhttp.send();
    }

    function reportAudio() {
        if (window.XMLHttpRequest) {
            xmlhttp= new XMLHttpRequest();
        }

        xmlhttp.onreadystatechange=function(){
            if (xmlhttp.readyState == 4 && xmlhttp.status == 200) {
                document.getElementById("myDiv").innerHTML = xmlhttp.responseText;
            }
        }

        xmlhttp.open("GET","deploy_audio.php?action=report&room=1&sound=14",true);
        xmlhttp.send();
    }

    function resetAudio() {
        if (window.XMLHttpRequest) {
            xmlhttp= new XMLHttpRequest();
        }

        xmlhttp.open("GET","deploy_audio.php?action=reset&pid=<?=$p?>",true);
        xmlhttp.send();
    }

    function resetRooms() {
        updateList('-1');
    }

    function closeWindow() {
        resetRooms();
        resetAudio();
        setTimeout(function(){open(location, '_self').close();}, 200);
    }

    function handleAlert(alert_id) {
        if (alert_id > 0) {
            document.body.style.background = 'red';
            setTimeout(function(){resetBackground()}, 3000);
        }
    }

    function resetBackground(){
        document.body.style.background = 'white';
    }

    updateList('0');

    var alertSound = document.getElementById("alert");
    alertSound.preload = 'auto';

    </script>
 </head>

 <body>
 <h1 id="myDiv"> Select your rooms: </h1>

  <select id="rooms" size=5 onchange="updateList(this.value)"> 
   <option value="1" id="r1"> loading...
   <option value="2" id="r2"> loading...
   <option value="3" id="r3"> loading...
   <option value="4" id="r4"> loading...
   <option value="5" id="r5"> loading...
  </select>
  
  <br>
  
  <button onclick="reportAudio()"> Test sound report </button>

  <br>

  <button id="gameButton" onclick="startGame()"> Start game </button>

  <br>

  <button onclick="closeWindow()"> Exit </button>

  <audio id="alert">
    <source src="PokeBattle.mp3" type="audio/mpeg">
  </audio>

 </body>
</html>
