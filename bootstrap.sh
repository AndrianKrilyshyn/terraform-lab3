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
<html lang="uk">
<head>
    <meta charset="UTF-8">
    <title>Лабораторна робота №3 - Голодна Черепашка</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, sans-serif; background-color: #2c3e50; color: white; text-align: center; margin: 0; padding: 20px; }
        canvas { background-color: #34495e; border: 4px solid #ecf0f1; border-radius: 8px; box-shadow: 0 10px 20px rgba(0,0,0,0.3); }
        .info-card { background: #ecf0f1; color: #2c3e50; padding: 20px; border-radius: 12px; display: inline-block; margin-top: 20px; text-align: left; box-shadow: 0 5px 15px rgba(0,0,0,0.2); }
        h1 { margin-bottom: 5px; color: #f1c40f; }
    </style>
</head>
<body>
    <h1>Голодна Черепашка 🐢</h1>
    <p>Керуй стрілочками на клавіатурі (⬅️ ⬆️ ⬇️ ➡️), щоб зібрати салат!</p>
    <p>Рахунок: <strong id="score" style="font-size: 24px; color: #2ecc71;">0</strong></p>
    
    <canvas id="gameCanvas" width="400" height="400"></canvas>

    <div class="info-card">
        <h3 style="margin-top: 0; color: #2980b9;">AWS Інфраструктура (Terraform)</h3>
        <p><strong>Студент:</strong> ${STUDENT}</p>
        <p><strong>Віртуальний хост:</strong> ${SERVER_NAME}</p>
        <p><strong>Document Root:</strong> ${DOC_ROOT}</p>
        <p><strong>Активний порт:</strong> ${WEB_PORT}</p>
    </div>

    <script>
        const canvas = document.getElementById("gameCanvas");
        const ctx = canvas.getContext("2d");
        let score = 0;
        
        let turtle = { x: 200, y: 200, size: 25, speed: 6 };
        let food = { x: Math.random() * 370, y: Math.random() * 370, size: 15 };

        // Керування
        const keys = {};
        document.addEventListener("keydown", (e) => keys[e.key] = true);
        document.addEventListener("keyup", (e) => keys[e.key] = false);

        function update() {
            if (keys["ArrowUp"] && turtle.y > 0) turtle.y -= turtle.speed;
            if (keys["ArrowDown"] && turtle.y < canvas.height - turtle.size) turtle.y += turtle.speed;
            if (keys["ArrowLeft"] && turtle.x > 0) turtle.x -= turtle.speed;
            if (keys["ArrowRight"] && turtle.x < canvas.width - turtle.size) turtle.x += turtle.speed;

            // Зіткнення з їжею
            if (turtle.x < food.x + food.size && turtle.x + turtle.size > food.x &&
                turtle.y < food.y + food.size && turtle.y + turtle.size > food.y) {
                score++;
                document.getElementById("score").innerText = score;
                food.x = Math.random() * (canvas.width - food.size);
                food.y = Math.random() * (canvas.height - food.size);
            }
        }

        function draw() {
            ctx.clearRect(0, 0, canvas.width, canvas.height);

            // Малюємо салат (їжу)
            ctx.fillStyle = "#2ecc71";
            ctx.beginPath();
            ctx.arc(food.x + food.size/2, food.y + food.size/2, food.size/2, 0, Math.PI*2);
            ctx.fill();

            // Малюємо черепашку
            ctx.fillStyle = "#f1c40f";
            ctx.fillRect(turtle.x, turtle.y, turtle.size, turtle.size);
            
            ctx.fillStyle = "#27ae60"; // Панцир
            ctx.fillRect(turtle.x + 4, turtle.y + 4, turtle.size - 8, turtle.size - 8);
        }

        function gameLoop() {
            update();
            draw();
            requestAnimationFrame(gameLoop);
        }
        
        // Запускаємо гру, щоб курсор не скролив сторінку
        window.addEventListener("keydown", function(e) {
            if(["Space","ArrowUp","ArrowDown","ArrowLeft","ArrowRight"].indexOf(e.code) > -1) {
                e.preventDefault();
            }
        }, false);

        gameLoop();
    </script>
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
