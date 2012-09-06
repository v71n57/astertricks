#!/usr/bin/php -q
<?
$agivars = array();
while (!feof(STDIN)) {
    $agivar = trim(fgets(STDIN));
    if ($agivar === '')
        break;
 
    $agivar = explode(':', $agivar);
    $agivars[$agivar[0]] = trim($agivar[1]);
}
extract($agivars);
 
$filename = $_SERVER["argv"][1];
 
exec('flac -f -s '.$filename.'.wav -o '.$filename.'.flac');
 
$file_to_upload = array('myfile'=>'@'.$filename.'.flac');
$ch = curl_init();
curl_setopt($ch, CURLOPT_URL,"https://www.google.com/speech-api/v1/recognize?xjerr=1&client=chromium&lang=ru-RU");
curl_setopt($ch, CURLOPT_POST,1);
curl_setopt($ch, CURLOPT_HTTPHEADER, array("Content-Type: audio/x-flac; rate=8000"));
curl_setopt($ch, CURLOPT_POSTFIELDS, $file_to_upload);
curl_setopt($ch,CURLOPT_RETURNTRANSFER,1);
$result=curl_exec ($ch);
curl_close ($ch);
 
$json_array = json_decode($result, true);
$voice_cmd = $json_array["hypotheses"][0]["utterance"];
 
unlink($filename.'.flac');
unlink($filename.'.wav');
 
echo 'SET VARIABLE VOICE "'.$voice_cmd.'"'."\n";
fgets(STDIN);
echo 'VERBOSE ("'.$voice_cmd.'")'."\n";
fgets(STDIN);
exit(0);
?>
