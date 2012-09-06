Статистика по балансу

Используется для работы IP телефонии Asterisk совместно с3G модемами в качестве каналов голосовой сотовой связи. Задача системы, запрашивать баланс по СИМ-картам операторов сотовой связи и анализировать их ответ. Полученную информацию сохранять в базе данных. На основании данных из базы строить отчеты о движении средств на счетах и организации уведомлений, в случае если баланс окажется ниже порогового значения. Модемы, баланс которых ниже допустимого уровня, должны автоматически исключаться из работы.

Компоненты системы

    Asterisk (сервер голосовой связи)
    chan_dongle (модуль для asterisk обеспечения голосовых звонков через 3G модемы)
    mysql для хранения и обработки данных
    openssl для вычисления md5 значений уникальности строк
    apache или любой другой web сервер (не обязательно, нужен для удобства просмотра отчетов) 

Принцип работы
Сбор и анализ статистики

Первый скрипт назначенный на периодическое выполнение (раз в 30 минут) в cron, осуществляет USSD запросы с добавлением случайной составляющей времени от 0 до 65 секунд с момента запуска для каждого модема. Это нужно для того, чтобы избежать одновременной отправки запросов сразу со всех устройств.

Asterisk должен быть предварительно настроен на то, чтобы обеспечивать отправку и получение USSD запросов через модемы.

Ответ операторов Asterisk помещает в текстовый файл, а скрипт выполняет извлечение информации о балансе из этих ответов, опираясь на строку разбора (парсинга), которая может быть написана для каждого оператора индивидуально. В текущем скрипте описано для МТС (2 варианта), Билайна и Мегафона для Хабаровского края. Возможно в других регионах придется что-то менять. Прошу свои варианты добавляйте в коментариях.

Каждая строка при внесении в базу контролируется на уникальность по md5 в качестве индекса. Таким образом не играет роли сколько раз запускается скрипт и считывает файл ответов, в базу будут внесены только уникальные значения и повторного добавления не произойдет.

При выполнении скрипт не ждет, когда каждый оператор ответит о состоянии баланса, а сразу строит отчеты из предыдущих данных. Таким образом текущее состояние баланса попадет в отчет только после следующего запуска.
Система уведомлений

Второй скрипт предназначен для уведомления пользователя об истечении баланса на счетах операторов. Он выполняется раз в сутки, считывает итоговые значения баланса из базы. Далее проверяется, не опустились ли значения баланса ниже установленного порога для одного и более операторов, и если это обнаружилось, на электронную почту отправляется письмо с этим списком. Почтовая подсистема MTA должна быть настроена в системе.
Подготовка к работе
Подготовка базы mysqlПравить

Создаем новую таблицу gsmbalans в базе asteriskcdrdb. Она обычно уже есть, если установлен FreePBX. Но можно создать и свою.

    Заходим в консоль mysql 

mysql -p

    Выполняем запрос на создание новой таблицы gsmbalans в базе asteriskcdrdb 

 USE asteriskcdrdb;
 CREATE TABLE 
  gsmbalans (
   md5 VARCHAR(64),
   port VARCHAR(10),
   balans DOUBLE(10,2),
   time DATETIME,
 UNIQUE (md5));

Добавим пользователя сервера mysql gsmbalans с паролем gSmBlNs

GRANT usage ON *.* TO gsmbalans@localhost IDENTIFIED BY 'gSmBlNs';
GRANT ALL privileges ON gsmbalans.* TO gsmbalans@localhost;

Подготовка плана набора AsteriskПравить

Для успешной работы файл с ответами должен иметь определенный формат.

nano /etc/asterisk/extension_custom.conf

Добавим в диалплан работу с ussd запросами в контекст прописанный в dadacard.conf

[from-gsm]
exten => ussd,1,Verbose(Incoming USSD: ${BASE64_DECODE(${USSD_BASE64})})
exten => ussd,n,System(echo '${STRFTIME(${EPOCH},,%d.%m.%Y %H:%M:%S)} - USSD - ${DONGLENAME}: ${BASE64_DECODE(${USSD_BASE64})}' >> /var/www/msg)
exten => ussd,n,Hangup()

Пример файла с ответами операторов на запрос баланса

28.04.2012 04:30:21 - USSD - 000104: 216.4 p.
28.04.2012 04:30:29 - USSD - 000105: Баланс 393.08 р. iPhone в офисах Билайн от 16 590 р. Инф 068006
28.04.2012 04:30:34 - USSD - 000106: Balans:14,20r

Обработка баланса
Скрипт обработки балансаПравить

nano /etc/balans

Скопируем и вставим

#!/bin/bash
 
# Имя файла ответов оператора
opermsg=/var/www/msg
 
# Число считываемых последних строк из файла 
# (при первичном заполнении базы ставим большое значение)
# Процедура разбора большого числа строк может занимать
# продолжительное время, так-как требуется вычислять md5
# для каждой строки
tn=1
 
# Имя базы данных
dbname=asteriskcdrdb
 
# Имя таблицы баланса
tbname=gsmbalans
 
# Имя пользователя базы
dbuser=gsmbalans
 
# Пароль пользователя базы
dbpass=gSmBlNs
 
# Минимальный баланс при достижении которого, модем отключается из работы.
min_bal=50
 
# Отключать ли модемы, баланс которых ниже порогового
otklmod=yes
 
 
# Путь до папки с отчетами (каталог web сервера)
repath=/var/www/bal
 
# Создаем индексную страничку в каталоге веб сервера
# Пытаться создать папку автоматически?
mkdir -p $repath
echo "<b>Баланс модемов</b><br>" >$repath/index.htm
echo "<a href='balans_ob.txt'>Сводный баланс</a><br>" >>$repath/index.htm
echo "<b>Подробно</b><br>" >>$repath/index.htm
 
 
# Список модемов и соответствующих им типов ответов операторов 
# о состоянии баланса
# Последовательность заполнения:
# 1. Номер Dongle устройства, 2. Префикс строки разбора, 3. Номер симки
# 4. Имя оператора 5. USSD запрос баланса
# Внимание, пробелы в полях не допускаются
 
for opsos in \
"  000103    MTS2   +79140000001    МТС      *100#" \
"  000101    MTS    +79140000002    МТС      *100#" \
"  000106    MTS    +79140000003    МТС      *100#" \
"  000104    MGF    +79240000004    МЕГАФОН  *100#" \
"  000102    MGF    +79240000005    МЕГАФОН  *100#" \
"  000105    BEE    +79620000006    БИЛАЙН   *102#" \
"  000107    BEE    +79090000007    БИЛАЙН   *102#"
 
do
num=`echo $opsos | awk '{print $1}'`
oper=`echo $opsos | awk '{print $2}'`
numsim=`echo $opsos | awk '{print $3}'`
fovsim=`echo $opsos | awk '{print $4}'`
ussdzap=`echo $opsos | awk '{print $5}'`
 
## Включаем модемы (они могут быть отключены при низком балансе) перед запросом.
asterisk -rx "dongle start $num"
let D=$RANDOM/1000 && sleep $D && asterisk -rx "dongle ussd $num $ussdzap" &
 
# Создаем отчеты по снятию/Пополнению средств с симкарт
echo "Оператор связи $fovsim" > $repath/bal-$num.txt
echo "Федеральный номер СИМ карты $numsim" >> $repath/bal-$num.txt
 
mysql -u$dbuser -p$dbpass -D $dbname -e "\
 set @a=0.0;select port as 'Модем',time as 'Дата Время',balans as 'Баланс',if(delta>0 and balans<>delta,delta,'-') as 'Приход',if(delta<0,delta,'-') as 'Расход' \
 from(select * from (select port,time,balans,round(balans-pv_balans,2) as delta \
 from(select port,time,@a as pv_balans,@a:=balans,balans \
 from ${tbname} where port='${num}' order by time) as t1) as t2 where delta<>0) as t3;" | column -t >> $repath/bal-$num.txt
 
# Наполняем индексную страничку
echo "<a href='bal-$num.txt'>$num</a> $numsim $fovsim<br>" >> $repath/index.htm
 
balans=""
######## Варианты парсинга баланса для разных операторов #######################
# Результат разбора должен быть в виде:
# 28.04.2012 08:30:17;52.70;000101
################################################################################
 
# Оператор МТС
  if [ "${oper}" = "MTS" ]
  then cat $opermsg | grep $num| grep USSD| grep Balans | sed -E 's/( - |: Balans:|r )/;/g' | sed 's/,/./g'  | awk -F ";" '{print $1";"$4";"$3}' | tail -n $tn >>tmpallbalans
  fi
 
# Оператор МТС вариант 2
  if [ "${oper}" = "MTS2" ]
  then cat $opermsg | grep $num| grep USSD| grep Баланс: | sed -E 's/( - |: Баланс:|р | р.)/;/g' | sed 's/,/./g' | awk -F ";" '{print $1";"$4";"$3}'|tail -n $tn  >>tmpallbalans
  fi
 
# Оператор БИЛАЙН
  if [ "${oper}" = "BEE" ]
  then cat $opermsg | grep $num| grep USSD| grep Баланс| grep р.| sed -E 's/( - |: Баланс | р.)/;/g' | sed 's/,/./g' | awk -F ";" '{print $1";"$4";"$3}' | tail -n $tn >>tmpallbalans
  fi
 
# Оператор МЕГАФОН
  if [ "${oper}" = "MGF" ]
  then cat $opermsg | grep $num| grep USSD| grep p.| sed -E 's/( - |: | p.)/;/g'| awk -F ";" '{print $1";"$4";"$3}' | tail -n $tn >>tmpallbalans
  fi
# Универсальный парсер. Использовать только в тестовых целях.
  if [ "${oper}" = "UNV" ]
  then cat $opermsg|grep $num|grep USSD|sed 's/^/;/g'|grep -o -P ".+(?= - USSD -)|(- USSD - \w+(?=\:))|([-0-9]+([.,]\d+)?)"|sed 's/$/;/g'|tr "\n" "_"|sed 's/;_;/\n/g'|sed -r 's/(_|- USSD - )//g'|sed 's/,/./g'|awk -F ";" '{print $1";"$2";"$3}' | grep -P -v "(;$|^;)"|awk -F ";" '{print $1";"$3";"$2}'|tail -n $tn >>tmpallbalans
  fi
################################################################################
 
done
 
# Парсим построчно получившийся файл и считаем md5 для каждой строки
cat tmpallbalans| while read line; 
 
do                     
    mdha=`echo "$line"|openssl md5`
    baldate=`echo "$line" | awk -F ";" '{print $1}' | awk '{print $1"."$2}'|awk -F "." '{print $3"-"$2"-"$1" "$4}'`
    balance=`echo "$line" | awk -F ";" '{print $2}'`
    modnumr=`echo "$line" | awk -F ";" '{print $3}'`
 
# Заполняем базу значениями
mysql -u$dbuser -p$dbpass -D $dbname -e "INSERT INTO ${tbname} (md5,port,balans,time) values ('$mdha' , '$modnumr' , '$balance' , '$baldate');" >/dev/null
 
# Отключаем модемы с низким балансом
celbal=`echo $balance | awk -F "." '{print $1}'`
if [ "${celbal}" -le "$min_bal" ] 
then
 if [ "${otklmod}" = "yes" ]
  then sleep 60 && asterisk -rx "dongle stop now $modnumr"
 fi
fi
 
done 
 
# Создаем сводный отчет по текущим балансам
zapr="select port as 'Модем',balans as 'Баланс',time as 'Дата Время' \
 from (select * from (select max(time) as last_date,port as prt \
 from ${tbname} group by port) as tbl1 \
 JOIN ${tbname} where tbl1.last_date=${tbname}.time and tbl1.prt=${tbname}.port) as itog where port<>'' order by port;"
 
mysql -u$dbuser -p$dbpass -D $dbname -e "${zapr}" | column -t > $repath/balans_ob.txt
 
# Очистка временных файлов
echo "">tmpbalans
echo "">tmpallbalans


Делаем скрипт исполняемым

chmod +x /etc/balans

Добавляем его исполнение в крон на каждые полчаса

echo "*/30 * * * * root /etc/balans > /tmp/bal.tmp" >> /etc/crontab

Настройка уведомлений

    Перед настройкой уведомлений, необходимо настроить почтовую подсистему на пересылку почты, если это еще не сделано. Пересылка почты 

Создадим скрипт, который будет получать из базы текущее состояние балансов и в случае достижения минимального значения одного или более устройств, уведомлять об этом по электронной почте

nano /etc/balansevent

# Параметры подключения к базе
dbname=asteriskcdrdb
tbname=gsmbalans
dbuser=gsmbalans
dbpass=gSmBlNs
# Порог срабатывания при значении меньше которого будет отправлено уведомление 
porog=100
# Адрес получателя уведомления (несколько адресов через запятую без пробелов
maddr=user@mail.com
 
# Создаем сводный отчет по низким балансам
 
zapr="select port as 'Модем',balans as 'Баланс',time as 'Дата Время' \
 from (select * from (select max(time) as last_date,port as prt \
 from ${tbname} group by port) as tbl1 \
 JOIN ${tbname} where tbl1.last_date=${tbname}.time and tbl1.prt=${tbname}.port) as itog where port<>'' and balans<'${porog}' order by port;"
mysql -u$dbuser -p$dbpass -D $dbname -e "${zapr}" | column -t > emltmp
 
nbal=`cat emltmp | wc -l`
if [ 1 -le ${nbal} ]
   then cat emltmp | mail -s 'Small Balans Events' $maddr
fi

Сделаем скрипт исполняемым и добавим в крон для запуска раз в сутки в 6 часов утра

chmod +x /etc/balansevent
echo "0 6 * * * root /etc/balansevent > /dev/null" >> /etc/crontab

