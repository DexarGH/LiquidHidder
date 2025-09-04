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
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Definition
$CONFIG_FILE = Join-Path $SCRIPT_DIR ".minecraft_backup_config"

# Загрузка настроек из файла конфигурации, если таковой имеется
if (Test-Path $CONFIG_FILE) {
    $config = Get-Content $CONFIG_FILE | ConvertFrom-StringData
    $SOURCE = $config.SOURCE
    $BACKUP = $config.BACKUP
}

# Первичное состояние настроек
if (-not $SOURCE) {
    $INITIALIZED = $false
} else {
    $INITIALIZED = $true
}

# Функция первой настройки
function FirstRun {
    # Приветствуем пользователя и просим выбрать пути
    Write-Host "Добро пожаловать в LiquidHidder! Выберите основные пути."

    # Путь для резервных копий
    $BACKUP_PATH = Read-Host "📂 Укажите папку для хранения резервных копий ($BACKUP)"
    if ($BACKUP_PATH -and $BACKUP_PATH -ne $BACKUP) {
        $BACKUP = $BACKUP_PATH
    }

    # Поиск папки gameDir
    Write-Host "🔍 Поиск папки 'gameDir'..."
    $SEARCH_RESULT = Get-ChildItem -Path $env:USERPROFILE -Recurse -Directory -Filter "gameDir"

    if ($SEARCH_RESULT.Count -eq 0) {
        Write-Host "⚠️ Папка 'gameDir' не найдена."
        return 1
    } elseif ($SEARCH_RESULT.Count -gt 1) {
        Write-Host "💬 Найдено несколько папок 'gameDir':"
        for ($i = 0; $i -lt $SEARCH_RESULT.Count; $i++) {
            Write-Host "$($i+1)) $($SEARCH_RESULT[$i].FullName)"
        }

        while ($true) {
            $CHOICE = Read-Host "Выберите номер нужной папки"

            if ($CHOICE -match '^\d+$' -and $CHOICE -ge 1 -and $CHOICE -le $SEARCH_RESULT.Count) {
                $GAMEDIR = $SEARCH_RESULT[$CHOICE-1].FullName
                $SOURCE = Split-Path -Parent $GAMEDIR # Родительская директория
                break
            } else {
                Write-Host "❌ Неверный выбор. Попробуйте снова."
            }
        }
    } else {
        $GAMEDIR = $SEARCH_RESULT[0].FullName
        $SOURCE = Split-Path -Parent $GAMEDIR
    }

    # Сохраняем настройки в файл конфигурации
    @"
SOURCE=$SOURCE
BACKUP=$BACKUP
"@ | Out-File $CONFIG_FILE

    $INITIALIZED = $true
}

# Функция меню
function Menu {
    Write-Host "Меню:"
    Write-Host "1) Сделать бэкап (из $SOURCE → $BACKUP)"
    Write-Host "2) Восстановить из бэкапа (из $BACKUP → $SOURCE)"
    Write-Host "3) Повторная настройка путей"
    $choice = Read-Host "Выберите действие (1/2/3)"

    switch ($choice) {
        1 {
            BackupData
        }
        2 {
            RestoreData
        }
        3 {
            Remove-Item $CONFIG_FILE -Force # Удаляем старое состояние
            FirstRun # Выполняем новую настройку
            Menu # Возвращаемся в меню
        }
        default {
            Write-Host "❌ Неправильный выбор."
        }
    }
}

# Функция создания бэкапа
function BackupData {
    if (-not (Test-Path $BACKUP)) {
        New-Item -ItemType Directory -Path $BACKUP | Out-Null
    }
    Write-Host "🔄 Создание бэкапа..."
    # Исключаем саму папку '.LiquidBounce', копируя только её содержимое
    Copy-Item -Path "$SOURCE\*" -Destination $BACKUP -Recurse -Force
    Write-Host "✅ Бэкап успешно создан!"
}

# Функция восстановления
function RestoreData {
    Write-Host "🔄 Начинаю восстановление..."
    # Клонируем содержимое резервной копии в целевую директорию
    Copy-Item -Path "$BACKUP\*" -Destination $SOURCE -Recurse -Force
    Write-Host "✅ Данные восстановлены!"
}

# Главная логика
if (-not $INITIALIZED) {
    FirstRun
}

if ($INITIALIZED) {
    Menu
} else {
    Write-Host "❌ Ошибка инициализации настроек."
    exit 1
}
