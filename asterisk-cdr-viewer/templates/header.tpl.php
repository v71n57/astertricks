<head>
  <title>Asterisk Call Detail Records</title>
  <meta http-equiv="Content-Type" content="application/xhtml+xml; charset=utf-8" />
<link rel="stylesheet" href="style/screen.css" type="text/css" media="screen" />
<link rel="stylesheet" href="style/simpleplayer.css" type="text/css">
<script src="js/jquery-1.8.0.min.js"></script>
<script src="js/jquery.simpleplayer.js"></script>

<script type="text/javascript">
        $(document).ready(function() {
            var settings = {
                progressbarWidth: '200px',
                progressbarHeight: '5px',
                progressbarColor: '#22ccff',
                progressbarBGColor: '#eeeeee',
                defaultVolume: 1.0
            };
            $(".player").player(settings);
        });
</script>

<link rel="shortcut icon" href="templates/images/favicon.ico" />
</head>
<body>
<table id="header">
  <tr>
    <td id="header_logo" rowspan="2" align="left"><a href="/" title="Home"><img src="templates/images/asterisk.gif" alt="Asterisk CDR Viewer" /></a></td>
    <td id="header_title">Asterisk CDR Viewer</td>
  </tr>
  <tr>
    <td id="header_subtitle">&nbsp;</td>
	<td align='right'>
	<?php
		if ( strlen(getenv('REMOTE_USER')) ) {
			echo "<a href='/acdr/index.php?action=logout'>logout: ". getenv('REMOTE_USER') ."</a>&nbsp;&nbsp;";
		}
	?>
	</td>
  </tr>
</table>
