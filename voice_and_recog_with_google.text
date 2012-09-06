Устанавливаем необходимые компонентыПравить

Нужные и/или полезные компоненты из репозитория Ubuntu 12.04

apt-get update
apt-get install libasterisk-agi-perl lamp-server^ ffmpeg flac php5-curl


Создаём файл под скрипт

nano /usr/share/asterisk/agi-bin/say.php

Создаем папку для кеша и назначаем права

mkdir /var/lib/asterisk/festivalcache/
chmod -R 777 /var/lib/asterisk/festivalcache/
chmod +x /usr/share/asterisk/agi-bin/say.php

Распознавание голоса

Создаем файл

nano /usr/share/asterisk/agi-bin/voice.php

Делаем созданный скрипт исполняемым

chmod +x /usr/share/asterisk/agi-bin/voice.php

Для задействования созданных AGI скриптов перезагрузим Asterisk

/etc/init.d/asterisk restart


Простой пример для проверки синтеза голоса 

nano /etc/asterisk/extensions.conf

exten => _.,1,Answer()
exten => _.,n,Wait(1)
exten => _.,n,AGI(say.php,"привет вам земляне‚!")

Пример совместного использования синтеза и распознавания голоса 

nano /etc/asterisk/extensions.conf

exten => _.,1,Answer
exten => _.,n,Wait(1)
exten => _.,n,AGI(say.php,"Здравствуйте‚!")
exten => _.,n,AGI(say.php,"скажите имя сотрудника!") #Запись услышанного
exten => _.,n,Record(/tmp/${UNIQUEID}.wav,3,20)  #Запись услышанного
exten => _.,n,AGI(say.php,"!вы сказали")
exten => _.,n,Playback(/tmp/${UNIQUEID})
exten => _.,n,AGI(voice.php,/tmp/${UNIQUEID})
exten => _.,n,AGI(say.php,"я услышала")
exten => _.,n,AGI(say.php,"${VOICE}")

