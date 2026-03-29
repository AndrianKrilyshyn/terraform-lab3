#!/bin/bash
exec >> >(tee -a /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1
echo "[ІНФО] Початок виконання user_data скрипта - $(date)"

if ! command -v apache2 &> /dev/null; then
    echo "[ІНФО] Встановлення вебсервера Apache2..."
    apt-get update -y
    apt-get install -y apache2
else
    echo "[ІНФО] Apache2 вже встановлений. Пропуск кроку."
fi

echo "[ІНФО] Зміна порту прослуховування на ${WEB_PORT}..."
sed -i "s/Listen 80/Listen ${WEB_PORT}/" /etc/apache2/ports.conf

echo "[ІНФО] Створення цільової директорії ${DOC_ROOT}..."
mkdir -p ${DOC_ROOT}

cat <<EOF > ${DOC_ROOT}/index.html
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Lab 3</title>
</head>
<body>
    <h1>Andrian K. Terraform lab3</h1>
</body>
</html>
EOF

chown -R www-data:www-data ${DOC_ROOT}
chmod -R 755 ${DOC_ROOT}

VHOST_CONF="/etc/apache2/sites-available/custom-site.conf"
cat <<EOF > $VHOST_CONF
<VirtualHost *:${WEB_PORT}>
    ServerName ${SERVER_NAME}
    DocumentRoot ${DOC_ROOT}
    ErrorLog $${APACHE_LOG_DIR}/custom_error.log
    CustomLog $${APACHE_LOG_DIR}/custom_access.log combined
</VirtualHost>
EOF

if ! grep -q "<Directory ${DOC_ROOT}>" /etc/apache2/apache2.conf; then
    cat <<EOF >> /etc/apache2/apache2.conf
<Directory ${DOC_ROOT}>
    Options Indexes FollowSymLinks
    AllowOverride None
    Require all granted
</Directory>
EOF
fi

a2dissite 000-default.conf
a2ensite custom-site.conf
systemctl restart apache2
systemctl enable apache2
echo "[ІНФО] Ініціалізацію успішно завершено $(date)"
