#!/usr/bin/php -q
<?php
$agivars = array();
while (!feof(STDIN)) {
    $agivar = trim(fgets(STDIN));
    if ($agivar === '')
        break;
 
    $agivar = explode(':', $agivar);
    $agivars[$agivar[0]] = trim($agivar[1]);
}
extract($agivars);
 
$text = $_SERVER["argv"][1];
if (isset($_SERVER["argv"][2])) $lang = $_SERVER["argv"][2];
else $lang = 'ru';
 
$md5 = md5($text);
 
$prefix = '/var/lib/asterisk/festivalcache/';
$filename = $prefix.$md5;
 
if (!file_exists($filename.'.alaw')) {
    $wget = 'wget -U "Mozilla/5.0 (Windows; U; Windows NT 6.0; en-US; rv:1.9.1.5) Gecko/20091102 Firefox/3.5.5" ';
    $wget.= '"http://translate.google.com/translate_tts?q='.$text.'&tl='.$lang.'" -O '.$filename.'.mp3';
    $ffmpeg = 'ffmpeg -i '.$filename.'.mp3 -ar 8000 -ac 1 -ab 64 '.$filename.'.wav -ar 8000 -ac 1 -ab 64 -f alaw '.$filename.'.alaw -map 0:0 -map 0:0';
    $exec = $wget.' && '.$ffmpeg.' && rm '.$filename.'.mp3 '.$filename.'.wav';
    exec($exec);
}
 
echo 'STREAM FILE "'.$filename.'" ""'."\n";
fgets(STDIN);
exit(0);
?>
