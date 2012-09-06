 USE asteriskcdrdb;
 CREATE TABLE 
  gsmbalans (
   md5 VARCHAR(64),
   port VARCHAR(10),
   balans DOUBLE(10,2),
   time DATETIME,
 UNIQUE (md5));

GRANT usage ON *.* TO gsmbalans@localhost IDENTIFIED BY 'gSmBlNs';
GRANT ALL privileges ON gsmbalans.* TO gsmbalans@localhost;
