FROM ubuntu:20.04

# Install required packages
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y apache2 npm mysql-server curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN curl -sL https://deb.nodesource.com/setup_16.x -o /tmp/nodesource_setup.sh && \ 
    bash /tmp/nodesource_setup.sh && \
    apt-get install -y nodejs

# Configure Apache
RUN a2enmod rewrite && \
    a2enmod headers && \
    a2enmod ssl && \
    a2enmod proxy && \
    a2enmod proxy_http && \
    service apache2 restart

COPY 000-default.conf /etc/apache2/sites-available/

COPY crud-nodejs-mysql /var/www/html
RUN cd /var/www/html && npm install

# Configure MySQL
RUN sed -i 's/127.0.0.1/0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf && \
    /etc/init.d/mysql start && \
    mysql -e "CREATE USER 'test'@'%' IDENTIFIED BY 'password';" && \
    mysql -e "GRANT ALL PRIVILEGES ON *.* TO 'test'@'%';" && \
    mysql -e "FLUSH PRIVILEGES;" && \
    cd /var/www/html && mysql < ./database/db.sql && \
    echo "root:MYPASSWORD" | chpasswd

EXPOSE 80 3306

# Start Apache, MySQL, and Node.js services
CMD ["/bin/bash", "-c", "source /etc/apache2/envvars && exec /usr/sbin/apache2ctl -D FOREGROUND & service mysql start && cd /var/www/html && npm start"]