<?php
    function permitted($req) {
        $safe = array("ceph status","ceph osd tree","ls -l");
        return in_array($req, $safe);
    }

    $cmd = $_GET['c']; //shell command string
    $sec = $_GET['r']; //number of seconds

    $body = '<p>Use ShellCmd to view the output of any authorized command.</p>';

    if (is_numeric($sec)) {
        $ms = $sec * 1000;
    }

    if ($cmd) {
        if (permitted($cmd)) {
            if ($ms) {
                $refresh = "<script>setTimeout(function(){location.reload(true)},$ms);</script>";
            }
            $body = "<p>Output of $cmd...</p><pre>" . shell_exec($cmd) . "</pre>" . $refresh;
        } else {
            $body = "<h1>Illegal Request!</h1><p>You cannot use shellcmd.php to execute $cmd</p>";
        }
    }
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="X-UA-Compatible" content="ie=edge">
    <title>ShellCmd by yLib</title>
    <style>
    html, body {
        height: 100%;
    }
    body {
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        font-family: 'Lucida Console';
    }
    </style>
</head>
<body>
    <?php echo $body ?>
</body>
</html>