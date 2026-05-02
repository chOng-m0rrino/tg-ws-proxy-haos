<div align="center">

# 🚀 TG WS Proxy for Home Assistant OS

[![Version](https://img.shields.io/github/v/release/chOng-m0rrino/tg-ws-proxy-haos?style=for-the-badge&color=blue)](https://github.com/chOng-m0rrino/tg-ws-proxy-haos/releases)
[![Home Assistant](https://img.shields.io/badge/Home_Assistant-Addon-18bcf2?style=for-the-badge&logo=home-assistant&logoColor=white)](https://www.home-assistant.io/)
[![License](https://img.shields.io/github/license/chOng-m0rrino/tg-ws-proxy-haos?style=for-the-badge&color=green)](LICENSE)
[![GitHub stars](https://img.shields.io/github/stars/chOng-m0rrino/tg-ws-proxy-haos?style=for-the-badge)](https://github.com/chOng-m0rrino/tg-ws-proxy-haos/stargazers)

**Это обертка для локального MTProto-прокси для Telegram.**<br>
**Аддон автоматически собирается из исходников [Flowseal/tg-ws-proxy](https://github.com/Flowseal/tg-ws-proxy) и предоставляет интерфейс для настройки в HaOS.**<br>
*Работает прямо в вашем Home Assistant*

</div>

---

<div align="center">
<img src="/logo.png" width="128" height="128" alt="TG WS Proxy Logo">
</div>

### Быстрая установка

# Добавь репозиторий в Home Assistant Supervisor: https://github.com/chOng-m0rrino/tg-ws-proxy-haos

### Что это?

**TG WS Proxy** — Это обертка для локального MTProto-прокси для Telegram. Работающий как аддон в Home Assistant OS.  

---
## Настройки

### Основные настройки

| Параметр | По умолчанию | Описание |
|----------|-------------|----------|
| `host` | `0.0.0.0` | IP адрес для прослушивания |
| `port` | `2443` | Порт для подключения |
| `secret` | `""` | Оставь пустым - сгенерируется сам |
| `dc_ip` | `default` | Дата-центры Telegram |

### Секретный ключ (secret)

**Самый простой способ - оставить пустым:**
secret: ""

Аддон сам сгенерирует ключ при первом запуске.

**Указать свой ключ:**
1. Открой терминал
2. Введи: `openssl rand -hex 16`
3. Скопируй результат (32 символа)
4. Вставь в поле secret

## Как подключиться

1. Запусти аддон
2. Открой вкладку **Логи**
3. Найди ссылку: `tg://proxy?server=...`
4. Нажми на ссылку в Telegram

---

## English

### Quick Installation

# Add repository to Home Assistant Supervisor: https://github.com/chOng-m0rrino/tg-ws-proxy-haos

### What is this?

**TG WS Proxy** A wrapper for a local MTProto proxy for Telegram. Running as a Home Assistant OS addon.<br>
*The addon automatically builds from [Flowseal/tg-ws-proxy](https://github.com/Flowseal/tg-ws-proxy) sources and provides a configuration interface for HaOS.*

---
## Configuration

### Basic Settings

| Parameter | Default | Description |
|----------|-------------|----------|
| `host` | `0.0.0.0` | IP address to listen on |
| `port` | `2443` | Connection port |
| `secret` | `""` | Leave empty - will be auto-generated |
| `dc_ip` | `default` | Telegram datacenters |

### Secret Key

**Easiest way - leave empty:**
secret: ""

The addon will generate a key on first launch.

**Use your own key:**
1. Open terminal
2. Enter: `openssl rand -hex 16`
3. Copy the result (32 characters)
4. Paste into the secret field

## 🔗 How to connect

1. Start the addon
2. Open the **Logs** tab
3. Find the link: `tg://proxy?server=...`
4. Click the link in Telegram

---

<div align="center">

</div>
