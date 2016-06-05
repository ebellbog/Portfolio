<?php
    $r = $_GET['room']; //get room clicked -> 0 for refresh, -1 for release
    $p = $_GET['pid']; //get private id

    //get master room list
    session_id('shared-rooms');
    session_start();
    $global_rooms = $_SESSION['rooms']; //load array for local use


    // append 5 ints to output, coding the following info:
    // 0 = open; 1 = claimed by me; 2 = claimed by someone else
    
    $output = '';

    for ($i = 1; $i < 6; $i++) {
        $availability = $global_rooms["r".strval($i)];
        
        if(strcmp($availability,'open') == 0) { //room is open
            if (intval($r) == $i) { //i.e. user has opted to change the assignment of this room
                $global_rooms["r".$r] = $p;
                $output .= '1';
            } else { //just report this room as is
                $output .= '0';
            }
        } else if (strcmp($availability, $p) == 0) { //room has private id matching our room
            if (intval($r) == $i || intval($r) == -1) { //release if clicked or release flag has been set
                $global_rooms["r".$i] = 'open';
                $output .= '0';
            } else { // just report
                $output .= '1';
            }
        } else { //room has someone else's id... not much we can do
            $output .= '2';
        }
    }

    $_SESSION['rooms']=$global_rooms; //save array back to session array
    echo($output);
?>
