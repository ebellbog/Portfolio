<?php
    $action = $_GET['action'];

    session_id('shared-rooms');
    session_start();
    $audio_sessions = $_SESSION['audio_sessions'];
 
    if (strcmp($action, 'report') == 0) {
        $r = $_GET['room'];
        $s = $_GET['sound'];

        $i = 0;
        foreach($audio_sessions as &$session_alerts) { //iterates through all values in array...
            array_push($session_alerts['r'.$r], $s);
            $i++;
        }
        unset($session_alerts);
        echo(print_r($audio_sessions));
    }

    else if (strcmp($action, 'check') == 0) {
        $p = $_GET['pid'];
        $output = '';

        for ($i = 1; $i < 6; $i++) {
            if (count($audio_sessions[$p]['r'.strval($i)]) > 0) {
                $output .= array_shift($audio_sessions[$p]['r'.strval($i)]);
            } else $output .= '-1';
            if ($i < 5) $output .= ',';
        }

        echo($output);
    }

    else if (strcmp($action, 'reset') == 0) {
        $p = $_GET['pid'];        
        unset($audio_sessions[$p]);
        echo("Deleted session $p from array");
    }

    else {
        echo('Spurious request.');
    }

    $_SESSION['audio_sessions'] = $audio_sessions;
?>
