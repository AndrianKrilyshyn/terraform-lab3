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
    <title>Лабораторна робота №3 - IaC Terraform</title>
    <style>
        body { font-family: sans-serif; background-color: #e9ecef; text-align: center; padding-top: 10vh; }
        .container { background: white; padding: 40px; border-radius: 12px; display: inline-block; }
    </style>
</head>
<body>
    <div class="container">
        <h1>AWS Інфраструктура успішно розгорнута</h1>
        <p><strong>Студент/Префікс:</strong> ${STUDENT}</p>
        <p><strong>Віртуальний хост:</strong> ${SERVER_NAME}</p>
        <p><strong>Шлях до Document Root:</strong> ${DOC_ROOT}</p>
        <p><strong>Активний порт:</strong> ${WEB_PORT}</p>
    </div>
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
