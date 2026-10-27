#!/bin/bash

user_id=$(id -u)
logs_folder="/var/log/roboshop"
logs_file="${logs_folder}/$0.log"
domain_name="dopsaws.online"
scripts_dir=$(dirname "$(realpath "$0")")
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"


if [ $user_id -ne 0 ]; then
    echo "Please run this script with root access"
    exit 1
fi

mkdir -p $logs_folder

timestamp(){
    date +"%F %T"
}

validate(){
    if [ $1 -ne 0 ]; then
        echo -e "$(timestamp) [ERROR] ${2}..${R}FAILED${N}" | tee -a $logs_file
        exit 1
    else
        echo -e "$(timestamp) [INFO] ${2}..${G}SUCCESS${N}" | tee -a $logs_file
    fi
}

echo "$(timestamp) [INFO] ==== Script started execution ====" | tee -a $logs_file

dnf module enable maven:3.9 -y &>> $logs_file
dnf install maven java-25-openjdk-devel -y &>> $logs_file
validate $? "Installing Java and Maven"

alternatives --set java "/usr/lib/jvm/java-25-openjdk/bin/java"
validate $? "Setting Java 25 as default version"

echo "export JAVA_HOME=$(dirname $(dirname $(readlink -f /usr/bin/java)))" > /etc/profile.d/java.sh
source /etc/profile.d/java.sh
echo $JAVA_HOME 
validate $? "Setting JAVA_HOME for Maven"

id roboshop &>> $logs_file
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "Roboshop System User" roboshop &>> $logs_file
    validate $? "Creating System User"
else
    echo -e "$(timestamp) [INFO] System user roboshop already exists...${Y}SKIPPING...${N}"
fi    

rm -rf /app
validate $? "Removing old code"
mkdir -p /app
validate $? "Creating app directory"

curl -L -o /tmp/shipping.zip https://raw.githubusercontent.com/daws-92s/roboshop-documentation/refs/heads/main/artifacts/shipping-v4.zip &>> $logs_file
validate $? "Downloading shipping"

cd /app
unzip /tmp/shipping.zip &>> $logs_file
validate $? "Unzipping shipping"

mvn clean package &>> $logs_file
validate $? "Installing dependencies"

mv target/shipping.jar shipping.jar
validate $? "Moving shipping.jar file"

sed -i "s/DOMAIN_NAME/$domain_name/g" "$scripts_dir/shipping.service" 
cp "$scripts_dir/shipping.service" /etc/systemd/system/shipping.service

dnf install mysql -y
validate $? "Installing MySQL Client"

mysql -h "mysql.$domain_name" -uroot -pRoboshop@1 < /app/db/master-data.sql
validate $? "Loading shipping data"

systemctl daemon-reload &>> $logs_file
systemctl enable shipping &>> $logs_file
systemctl start shipping &>> $logs_file
validate $? "Starting and enabling shipping"

systemctl restart shipping
validate $? "Restarting shipping"


echo "$(timestamp) [INFO] Script completed in $SECONDS seconds"
echo "$(timestamp) [INFO] ==== Scripted executed ====" | tee -a $logs_file