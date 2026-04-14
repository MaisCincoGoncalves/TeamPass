<?php
require '/var/www/html/vendor/autoload.php';
require '/var/www/html/install/tp.functions.php';
use Defuse\Crypto\Key;
$key = Key::createNewRandomKey();
$salt = $key->saveToAsciiSafeString();
$result = encryptFollowingDefuseForInstall('testpassword', $salt);
var_dump($result);
