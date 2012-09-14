#!/bin/bash

#[incoming-gorod]
#exten => 2009XXX,1,NoOp( == входящий звонок с номера == ${CALLERID(number)} == )
#exten => 2009XXX,n,GotoIF($[${LEN($CALLERID(number)})} != 10 ]?nesotovik) ; номер не равен 10 знакам ? нафиг его
#exten => 2009XXX,n,GotoIF($[${CALLERID(number):0:1} != 9 ]?nesotovik) ; начало номера не на 9 ? это не сотовый
#exten => 2009XXX,n,macro(seekmobnumber,${CALLERID(number)})
#exten => 2009XXX,n(nesotovik),NoOp( == обработка далее == )

#[macro-seekmobnumber]
#exten => s,1,Set(sql=SELECT `operator`,`region` FROM `codes` WHERE ${ARG1:3:9} BETWEEN `code_from` AND `code_to` AND `code_abcdef`=${ARG1:0:3})
#exten => s,n,NoOp( == номер телефона == ${ARG1:0:3} == ${ARG1:3:9} == )
#exten => s,n,MYSQL(Connect connid localhost login password asterisk utf8)
#exten => s,n,GotoIf($["${connid}" = ""]?error,1) ;если ошибка то выход
#exten => s,n,MYSQL(Query resultid ${connid} ${sql})
#exten => s,n,MYSQL(Fetch foundRow ${resultid} operator region)
#exten => s,n,MYSQL(Clear ${resultid})
#exten => s,n,MYSQL(Disconnect ${connid})
#exten => s,n,NoOp( == название == ${operator} == ${region} == )
#exten => s,n,Set(CDR(userfield)=${operator},${region}) ;результат запроса сюда
#exten => error,1,NoOp( == error ! == )
#exten => error,n,MYSQL(Disconnect ${connid}) 

DOWNFILE9="http://www.rossvyaz.ru/docs/articles/DEF-9x.html"
DOWNFILE3="http://www.rossvyaz.ru/docs/articles/ABC-3x.html"
DOWNFILE4="http://www.rossvyaz.ru/docs/articles/ABC-4x.html"
DOWNFILE8="http://www.rossvyaz.ru/docs/articles/ABC-8x.html"

TMPDIR="./defto";
DB_USER='asteriskuser';
DB_PASSWORD='amp109';
DATABASE_NAME='telnumbers';

DB_TABLE_NAME9='codes9';
DB_TABLE_NAME3='codes3';
DB_TABLE_NAME4='codes4';
DB_TABLE_NAME8='codes8';

DATE=`date +%F`
mkdir -p $TMPDIR

wget -c -q -O - $DOWNFILE9 | grep "^<tr>" | sed -e 's/<\/td>//g' -e 's/<tr>//g' -e 's/<\/tr>//g' -e 's/[\t]//g' -e 's/^<td>//g' -e 's/<td>/;/g' -e 's/'"$(printf '\015')"'$//g' | iconv -c -f WINDOWS-1251 -t UTF8 > $TMPDIR/$DB_TABLE_NAME9.$DATE
wget -c -q -O - $DOWNFILE3 | grep "^<tr>" | sed -e 's/<\/td>//g' -e 's/<tr>//g' -e 's/<\/tr>//g' -e 's/[\t]//g' -e 's/^<td>//g' -e 's/<td>/;/g' -e 's/|/- /g' -e 's/'"$(printf '\015')"'$//g' | iconv -c -f WINDOWS-1251 -t UTF8 > $TMPDIR/$DB_TABLE_NAME3.$DATE
wget -c -q -O - $DOWNFILE4 | grep "^<tr>" | sed -e 's/<\/td>//g' -e 's/<tr>//g' -e 's/<\/tr>//g' -e 's/[\t]//g' -e 's/^<td>//g' -e 's/<td>/;/g' -e 's/|/- /g' -e 's/'"$(printf '\015')"'$//g' | iconv -c -f WINDOWS-1251 -t UTF8 > $TMPDIR/$DB_TABLE_NAME4.$DATE
wget -c -q -O - $DOWNFILE8 | grep "^<tr>" | sed -e 's/<\/td>//g' -e 's/<tr>//g' -e 's/<\/tr>//g' -e 's/[\t]//g' -e 's/^<td>//g' -e 's/<td>/;/g' -e 's/|/- /g' -e 's/'"$(printf '\015')"'$//g' | iconv -c -f WINDOWS-1251 -t UTF8 > $TMPDIR/$DB_TABLE_NAME8.$DATE

### Добавим Ростелеком
# echo "831;0000000;9999999;9999999;Ростелеком;Нижегородская область" >> $TMPDIR/$DB_TABLE_NAME.$DATE
### Имя файла = имя таблицы
mysql -u $DB_USER -p$DB_PASSWORD $DATABASE_NAME < ./defcodesall.sql

#mysqlimport --user=$DB_USER --password=$DB_PASSWORD --columns "code_abcdef,code_from,code_to,code_volume,operator,region" --local --fields-terminated-by=";" --lines-terminated-by="\\n" $DATABASE_NAME $TMPDIR/$DB_TABLE_NAME9.$DATE
#mysqlimport --user=$DB_USER --password=$DB_PASSWORD --columns "code_abcdef,code_from,code_to,code_volume,operator,region" --local --fields-terminated-by=";" --lines-terminated-by="\\n" $DATABASE_NAME $TMPDIR/$DB_TABLE_NAME3.$DATE
#mysqlimport --user=$DB_USER --password=$DB_PASSWORD --columns "code_abcdef,code_from,code_to,code_volume,operator,region" --local --fields-terminated-by=";" --lines-terminated-by="\\n" $DATABASE_NAME $TMPDIR/$DB_TABLE_NAME4.$DATE
#mysqlimport --user=$DB_USER --password=$DB_PASSWORD --columns "code_abcdef,code_from,code_to,code_volume,operator,region" --local --fields-terminated-by=";" --lines-terminated-by="\\n" $DATABASE_NAME $TMPDIR/$DB_TABLE_NAME8.$DATE
