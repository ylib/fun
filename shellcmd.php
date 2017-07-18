<?php
    function sanitize($data)
    {
        $data = trim($data);
        $data = stripslashes($data);
        $data = htmlspecialchars($data);
        return $data;
    }

    function permitted($req)
    {
        $safe = array("ps -e","ls -l","ceph status","ceph osd tree");
        if ($req) {
            return in_array($req, $safe);
        }
        else
        {
            return $safe;
        }
    }

    $cmd = escapeshellcmd($_GET['c']); //shell command string
    $sec = sanitize($_GET['r']); //number of seconds

    $body = '<p>Use ShellCmd to view the output of any of these authorized commands.</p>';
    $body .= '<ul><li>' . implode(permitted(),'</li><li>') . '</li></ul>';

    if (is_integer($sec)) {
        $ms = $sec * 1000;
    }

    if ($cmd) {
        if (permitted($cmd)) {
            if ($ms) {
                $refresh = "<script>setTimeout(function(){location.reload(true)},$ms);";
            }
            $body = "<p>Output of $cmd...</p><pre>" . shell_exec($cmd) . "</pre>" . $refresh;
        } else {
            $body = "<h1>Illegal Request!</h1><p>You cannot use shellcmd.php to execute $cmd</p>";
        }
    }
?><!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="X-UA-Compatible" content="ie=edge">
    <title>ShellCmd (by Chris Kramer)</title>
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