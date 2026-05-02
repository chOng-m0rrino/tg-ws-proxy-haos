# TG WS Proxy (haos)

 A wrapper for a local MTProto proxy for Telegram. The addon automatically builds from [Flowseal/tg-ws-proxy](https://github.com/Flowseal/tg-ws-proxy) sources and provides a configuration interface for HaOS.

🇷🇺 Это обертка для локального MTProto-прокси для Telegram. Аддон автоматически собирается из исходников [Flowseal/tg-ws-proxy](https://github.com/Flowseal/tg-ws-proxy) и предоставляет интерфейс для настройки в HaOS.

---

## 📋 Requirements / Требования

First installation may take 2-5 minutes
Первая установка может занять 2-5 минут  

- `aarch64` / `arm64`
- `amd64`


 ⚠️ `armv7` (32-bit ARM, Raspberry Pi 3 и старше) — **не поддерживается** / **not supported**  

---

## ⚙️ Settings / Настройки

| Parameter / Параметр | Default / По умолчанию | Description / Описание |
|----------|--------------|----------|
| `host` | `0.0.0.0` |  Listen IP /  IP для прослушивания |
| `port` | `2443` |  Proxy port /  Порт прокси |
| `secret` | `""` |  Secret (leave empty for auto-generation) /  Секрет (оставьте пустым для автогенерации) |
| `dc_ip` | `4:149.154.167.220` |  Telegram DCs in `id:ip` format /  Дата-центры Telegram в формате `номер:ip` |
| `auto_update` | `true` |  Auto-update every 24 hours /  Автообновление раз в 24 часа |
| `debug` | `false` |  Verbose logging /  Подробное логирование |
| `fake_tls_domain` | `""` |  Domain for Fake TLS masking (ee-secret) /  Домен для Fake TLS маскировки (ee-secret) |
| `proxy_protocol` | `false` |  HAProxy PROXY protocol v1 support /  Поддержка HAProxy PROXY protocol v1 |
| `no_cfproxy` | `false` |  Disable Cloudflare proxying /  Отключить проксирование через Cloudflare |
| `cfproxy_domain` | `""` |  Custom Cloudflare domain /  Свой домен для Cloudflare |
| `cfproxy_priority` | `true` |  `true` - Cloudflare first, then TCP /  `true` - Cloudflare сначала, затем TCP |
| `buf_kb` | `256` |  Buffer size in KB /  Размер буфера в КБ |
| `pool_size` | `4` |  Connections per DC /  Количество соединений на каждый DC |

## More detailed documentation / Более подробная документация

https://github.com/Flowseal/tg-ws-proxy

---

## 🔗 How to connect / Как подключиться

 After starting the addon, connection links will appear in the logs.

 После запуска аддона в логах появятся ссылки для подключения.

---

## ⚠️ If media doesn't load / Если не грузятся медиа

 Remove all `DC → IP` entries from proxy settings except:
- `4:149.154.167.220`

If that doesn't help, remove all entries from this field.

This issue typically occurs on non-Premium accounts.

If the issue persists, configure your own domain using this guide:
https://github.com/Flowseal/tg-ws-proxy/blob/main/docs/CfProxy.md
## ⠀🇷🇺
 Удали в настройках прокси все записи `DC → IP`, кроме:
- `4:149.154.167.220`

Если не помогло, то удалите вообще всё из этого поля.

Подобная проблема встречается на аккаунтах без Premium.

Если не помогло, настраивайте свой домен по гайду:
https://github.com/Flowseal/tg-ws-proxy/blob/main/docs/CfProxy.md

---

## 🔄 Auto-update / Автообновление

 When `auto_update` is enabled (default):
- The addon checks for a new version on every startup
- Background check runs every 24 hours
- When a new version is detected, automatic update is performed
- The proxy restarts with the new code

**To disable auto-update:** uncheck the option in settings.
## ⠀🇷🇺
 При включенной опции `auto_update` (по умолчанию):
- Аддон проверяет наличие новой версии при каждом запуске
- Фоновая проверка выполняется каждые 24 часа
- При обнаружении новой версии происходит автоматическое обновление
- Прокси перезапускается с новым кодом

**Чтобы отключить автообновление:** уберите флажок в настройках.