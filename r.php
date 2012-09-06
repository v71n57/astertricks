<?php
$config['mysql_host'] = 'localhost';
$config['mysql_user'] = 'asteriskuser';
$config['mysql_password'] = 'amp109';
$config['mysql_base'] = 'telnumbers';
$mysql_table = 'codes';

if(isset($_GET['number'])) {
        $number=$_GET['number'];
} else {
        die("Номера нема");
}

$mysql = new mysqli($config['mysql_host'],$config['mysql_user'],$config['mysql_password'],$config['mysql_base']);
$mysql->query("SET NAMES 'utf8'");

//$number = '+7(952)44-044-17';

$number = preg_replace('/[^0-9]+/','',$number);

if (strlen($number) == 11) {
  $number = substr($number,1);
}

if (strlen($number) == 10) {
  $def = substr($number,0,3);
  $code = substr($number,3);
  $stmt = $mysql->stmt_init();
  $stmt->prepare(
  //'SELECT `operator`,`region` FROM `codes` WHERE 4404417 BETWEEN `code_from` AND `code_to` AND `code_abcdef`=952;'
  //'SELECT `region`,`operator` FROM `codes` WHERE `code_abcdef`= ? AND ? > `code_from` AND ? < `code_to`'
  'SELECT `region` FROM `codes` WHERE `code_abcdef`= ? AND ? > `code_from` AND ? < `code_to`'
   );
  //$stmt->bind_param("iii", $def, $code, $code);
  $stmt->bind_param("iii", $def, $code, $code);
  $stmt->execute();
  //$stmt->bind_result($region, $operator);
  $stmt->bind_result($region);
  while ($stmt->fetch()) {
	  if ($region === "Нижегородская область"){
		  echo "$number<br/>\r\n";
	  }else {
		  echo "@$number<br/>\r\n";
	  }
  }
  $stmt->close();
} else {
  echo "Ошибка: неправильный формат номера<br>\r\n";
}
?>
