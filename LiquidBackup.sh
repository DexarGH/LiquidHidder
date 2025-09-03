#!/bin/bash

echo "
####       ####    ## ##   ##  ###    ####   ### ##   ###  ##    ####   ### ##   ### ##   ### ###  ### ##
 ##         ##    ##   ##  ##   ##     ##     ##  ##   ##  ##     ##     ##  ##   ##  ##   ##  ##   ##  ##
 ##         ##    ##   ##  ##   ##     ##     ##  ##   ##  ##     ##     ##  ##   ##  ##   ##       ##  ##
 ##         ##    ##   ##  ##   ##     ##     ##  ##   ## ###     ##     ##  ##   ##  ##   ## ##    ## ##
 ##         ##    ##   ##  ##   ##     ##     ##  ##   ##  ##     ##     ##  ##   ##  ##   ##       ## ##
 ##  ##     ##    ##  ##   ##   ##     ##     ##  ##   ##  ##     ##     ##  ##   ##  ##   ##  ##   ##  ##
### ###    ####    ##  ##   ## ##     ####   ### ##   ###  ##    ####   ### ##   ### ##   ### ###  #### ##


"

# Определение путей
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
CONFIG_FILE="$SCRIPT_DIR/.minecraft_backup_config"

# Загрузка настроек из файла конфигурации, если таковой имеется
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
fi

# Первичное состояние настроек
if [[ -z "$SOURCE" ]]; then
    INITIALIZED=false
else
    INITIALIZED=true
fi

# Функция первой настройки
first_run() {
    # Приветствуем пользователя и просим выбрать пути
    echo "Добро пожаловать в LiquidHidder! Выберите основные пути."

    # Путь для резервных копий
    read -ep "📂 Укажите папку для хранения резервных копий ($BACKUP): " BACKUP_PATH
    if [[ -n "$BACKUP_PATH" && "$BACKUP_PATH" != "$BACKUP" ]]; then
        BACKUP=$BACKUP_PATH
    fi

    # Поиск папки gameDir
    echo "🔍 Поиск папки 'gameDir'..."
    SEARCH_RESULT=($(find ~ -type d -name "gameDir"))

    if [[ ${#SEARCH_RESULT[@]} -eq 0 ]]; then
        echo "⚠️ Папка 'gameDir' не найдена."
        return 1
    elif [[ ${#SEARCH_RESULT[@]} -gt 1 ]]; then
        echo "💬 Найдено несколько папок 'gameDir':"
        for i in "${!SEARCH_RESULT[@]}"; do
            echo "$((i+1))) ${SEARCH_RESULT[$i]}"
        done

        while true; do
            read -ep "Выберите номер нужной папки: " CHOICE

            if [[ $CHOICE =~ ^[0-9]+$ && $CHOICE -ge 1 && $CHOICE -le ${#SEARCH_RESULT[@]} ]]; then
                GAMEDIR=${SEARCH_RESULT[$(($CHOICE-1))]}
                SOURCE=$(dirname "$GAMEDIR") # Родительская директория
                break
            else
                echo "❌ Неверный выбор. Попробуйте снова."
            fi
        done
    else
        GAMEDIR="${SEARCH_RESULT[0]}"
        SOURCE=$(dirname "$GAMEDIR")
    fi

    # Сохраняем настройки в файл конфигурации
    cat <<EOF > "$CONFIG_FILE"
SOURCE="$SOURCE"
BACKUP="$BACKUP"
EOF

    INITIALIZED=true
}

# Функция меню
menu() {
    echo "Меню:"
    echo "1) Сделать бэкап (из $SOURCE → $BACKUP)"
    echo "2) Восстановить из бэкапа (из $BACKUP → $SOURCE)"
    echo "3) Повторная настройка путей"
    read -p "Выберите действие (1/2/3): " choice

    case $choice in
      1)
          backup_data
          ;;
      2)
          restore_data
          ;;
      3)
          rm -f "$CONFIG_FILE" # Удаляем старое состояние
          first_run           # Выполняем новую настройку
          menu               # Возвращаемся в меню
          ;;
      *)
          echo "❌ Неправильный выбор."
          ;;
    esac
}

# Функция создания бэкапа
backup_data() {
    mkdir -p "$BACKUP"
    echo "🔄 Создание бэкапа..."
    # Исключаем саму папку '.LiquidBounce', копируя только её содержимое
    rsync -a --recursive --exclude='.*' "$SOURCE"/ "$BACKUP"
    echo "✅ Бэкап успешно создан!"
}

# Функция восстановления
restore_data() {
    echo "🔄 Начинаю восстановление..."
    TEMP_DIR="$(mktemp -d)" # Временная папка для временного размещения файлов
    # Клонируем содержимое резервной копии в временную папку
    cp -r "$BACKUP"/* "$TEMP_DIR"
    # Пересобираем дерево папок и перемещаем элементы обратно в правильную позицию
    mv "$TEMP_DIR"/* "$SOURCE"
    rmdir "$TEMP_DIR" # Удаляем временную папку
    echo "✅ Данные восстановлены!"
}

# Главная логика
if ! $INITIALIZED; then
    first_run
fi

if $INITIALIZED; then
    menu
else
    echo "❌ Ошибка инициализации настроек."
    exit 1
fi
