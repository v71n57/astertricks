DROP TABLE IF EXISTS `codes`;
CREATE TABLE IF NOT EXISTS `codes` (
`code_id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
`code_abcdef` smallint(3) NOT NULL,
`code_from` int(11) NOT NULL,
`code_to` int(11) NOT NULL,
`code_volume` int(11) NOT NULL,
`operator` varchar(400) NOT NULL,
`region` varchar(400) NOT NULL,
UNIQUE KEY `code_id` (`code_id`),
KEY `code_abcdef` (`code_abcdef`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 AUTO_INCREMENT=116182 ; 
