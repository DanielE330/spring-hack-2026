Минимальная статическая страница для смены пароля по токену.

Как использовать:

1) Откройте `index.html` в браузере или разверните каталог через любой static-server (напр. `npx http-server` или `python -m http.server 8000`).

2) По ссылке из письма будет открываться страница с параметром `token`, например:
   http://localhost:3000/password-reset/?token=<TOKEN>
   (в письме мы генерируем ссылку как FRONTEND_URL + '/password-reset/confirm?token=...')

3) По умолчанию скрипт отправляет POST на `http://localhost:8000/auth/password-reset/confirm/`.
   Если ваш backend на другом хосте, измените переменную `API_BASE` в `index.html`.

4) Поля: `token`, `new_password`. После успешного запроса увидите сообщение об успехе.

Дополнительно: можно интегрировать эту страницу в ваш фронтенд (React/Flutter/Vue). Страница простая и легко встраиваемая.