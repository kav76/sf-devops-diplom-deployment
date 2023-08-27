## Введение
Настоящее руководство описывает процесс автоматизированной установки виртуальных серверов в [Yandex.Cloud](https://cloud.yandex.ru), операционных систем, системы контейнеризации [Docker](https://docker.com) и оркестрации [Kubernetes](https://kubernetes.io), а так же средства их автоматизированной конфигурации для запуска тестового программного продукта.

Для удобства созданы 2 репозитория:
1. https://github.com/kav76/sf-devops-diplom-installation - каталоги и файлы автоматизированной установки инфраструктуры и необходимого программного обеспечения
2. https://github.com/kav76/sf-devops-diplom-application - запускаемый программный продукт.

## Предварительные требования
1. Аккаунт на [Yandex.Cloud](https://cloud.yandex.ru).
2. Персональный компьютер под управлением Linux для установки и настройки.
3. Установленный на локальный ПК [Hashicorp Terraform](https://developer.hashicorp.com/terraform). [Инструкция по установке](https://developer.hashicorp.com/terraform/downloads).
4. Установленный на локальный ПК [Ansible](https://www.ansible.com/). [Инструкция по установке](https://docs.ansible.com/ansible/latest/installation_guide/index.html).
5. SSH клиент. 
6. Git клиент.

## Предварительные действия
Проверьте наличие ssh ключей для организации удаленного доступа к настраиваемой инфраструктуре.
```
ls ~/.ssh
```
Если каталог пуст - сгенерируйте новую пару ключей.
```
 ssh-keygen -t rsa -b 4096 -C "your_email"
 eval "$(ssh-agent -s)"
 ssh-add ~/.ssh/id_rsa
```
Перейдите в каталог, где будут находится файлы проекта или создайте новый.

## Получение файлов проекта  
Склонируйте репозиторий проекта с файлами установки.
   ```
   git clone https://github.com/kav76/sf-devops-diplom-installation.git
   ```

## Создание и настройка серверов
В результате выполнения этого шага будет создано 3 виртуальных сервера на [Yandex.Cloud](https://cloud.yandex.ru).
Перейти в каталог ./infrastructure/1_InstallServers
   ```
   cd infrastructure/1_InstallServers
   ```
Расшифровать файл `yandex_init_variables.tf` и `s3_keys.txt`.
```
ansible-vault decrypt --ask-vault-password --output yandex_init_variables.tf yandex_vars.tf.vault
ansible-vault decrypt --ask-vault-password --output s3_keys.txt s3_keys.txt.vault
```
Для взаимодействия между серверами используется локальный сегмент сети с адресами `10.128.0.0/24`. При необходимости измените локальные адреса серверов в файле `main.tf` и `./config/hosts`.

Откройте в текстовом редакторе `main.tf` и перенесите значения _access_key_ и _secret_key_ в разделе _backend "s3"_ из файла `s3_keys.txt`.

Выполните скрипт `1_run_install.sh`
```
./1_run_install.sh
```
В процессе установки надо будет однократно подтвердить предстоящие изменения - нажмите "Y".

После успешного завершения процесса установки будет создан файл `inventory`, содержащий ip адреса для доступа к серверам - по порядку следования - для master.local (Контроллер кластера Kubernetes), app-1.local (рабочая машина кластера Kubernetes), management.local (сервер CI/CD и мониторинга). Используйте его в дальнейшем для указания в файлах `inventory` других скриптов адресов нужных серверов.

Выполните `2_run-postinstall.sh`
```
./2_run-postinstall.sh
```
Скрипт скопирует на серверы файл `/etc/hosts`.

Проверка установки:

Выполнить `ping` ip адресов установленных серверов.
```
ping master.local
ping app-1.local
ping managerment.local
```
Скопировать ssh ключи на `management.local`. Если файлы ключей имеют имена `id_rsa` и `id_rsa.pub`, то выполнить
```
cd ~/.ssh
scp id_rsa* ubuntu@<ip_management.local>:/home/ubuntu/.ssh/
```

Этап установки серверов закончен. Переходите к установке `Docker`.
   
## Установка Docker
После завершения этапа на все серверы будет установлен `Docker`.

Скопируйте файл `inventory` в каталог установки `Docker`.
```
cp -f inventory ../2_InstallDocker/
```
Перейдите в каталог 2_InstallDocker
```
cd ../2_InstallDocker
```
Выполните скрипт `runme.sh`
```
./runme.sh
```
Проверка установки:

Подключиться к серверам и выполнить 
```
docker --version
```

Этап установки `Docker` завершен. Переходим к установке кластера `Kubernetes`.

## Установка кластера Kubernetes
После завершения этапа на `master.local` будет установлен `kubernetes` и настроен `Control-plane`, на `app-1.local` - установлен `kubernetes` и настроен `node`.

Перейдите в каталог 3_InstallKuberCluster
```
cd ../3_InstallKuberCluster
```
Откройте в текстовом редакторе файл `inventory` и поменяйте ip адреса [master] и [nodes] на ip адреса `master.local` и `app-1.local` соответственно.

Выполните последовательно скрипты `1_install_kubernetes.sh`, `2_init_clister.sh`, `3_make_join_script.sh` и `4_join_node_to_cluster.sh`
```
./1_install_kubernetes.sh
./2_init_clister.sh
./3_make_join_script.sh
./4_join_node_to_cluster.sh
```
### Примечание
Установка и настройка разделена на этапы для обеспечения возможности реагирования на возможное возникновение сбоев и устранения их последствий.

Проверка установки:
Подключиться к `master.local` и выполнить
```
sudo kubectl get nodes
```
Пример правильного ответа:
```
NAME           STATUS   ROLES           AGE    VERSION
app-1.local    Ready    <none>          2d4h   v1.28.0
master.local   Ready    control-plane   2d4h   v1.28.0
```

Этап завершен.

## Установка Jenkins
После завершения установки на сервере `management.local` будет установлен `Jenkins`.
Перейдите в каталог `4_InstallJenkins`
```
cd ../4_InstallJenkins
```
Выполните скрипт `runme.sh`
```
./runme.sh
```
После установки необходимо получить автоматически сгенерированный пароль для первоначального подключения к интерфейсу `Jenkins`. Подключитесь к `management.local` и получите содержимое файла `/var/lib/jenkins/secrets/initialAdminPassword`
```
cat /var/lib/jenkins/secrets/initialAdminPassword
```
Дать пользователю `jenkins` права `sudo`. Выполнить скрипт
```
cd ../5_MakeJenkinsSudo
./runme.sh
```
Этап завершен.

Интерфейс `Jenkins` доступен по адресу http://<ip_management.local>:8080

Документация по работе с `Jenkins`: https://www.jenkins.io/doc/book/


