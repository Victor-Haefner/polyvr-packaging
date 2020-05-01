<?php
$dir = $_GET['path'];
$files = scandir($dir);
echo implode( "|", $files );
?>
