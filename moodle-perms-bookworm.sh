#!/bin/bash
# ========================================================
# Permessi e proprietà per Moodle 4.x su Debian 12
# ========================================================

# Variabile di release in stile Ubuntu
SCRIPT_RELEASE="4.3.0"
SCRIPT_CODENAME="LTS Owl"
SCRIPT_DATE="2024-12-19"
SCRIPT_AUTHOR="Moodle Admin Team"
SCRIPT_LICENSE="GPL-3.0"

set -e  # Esce immediatamente in caso di errore

MOODLE_DIR="/var/www/moodle"
MOODLEDATA_DIR="/var/moodledata"
WWW_USER="www-data"
WWW_GROUP="www-data"

# Funzione per mostrare l'header
show_header() {
    echo "================================================================================"
    echo "Moodle 4 Permissions Manager v${SCRIPT_RELEASE} (${SCRIPT_CODENAME})"
    echo "================================================================================"
    echo "Author: ${SCRIPT_AUTHOR}"
    echo "Release: ${SCRIPT_RELEASE} - ${SCRIPT_DATE}"
    echo "License: ${SCRIPT_LICENSE}"
    echo "================================================================================"
    echo ""
}

# Funzione per mostrare l'help
show_help() {
    echo "Utilizzo: $0 [OPZIONI]"
    echo ""
    echo "Opzioni:"
    echo "  -h, --help          Mostra questo help"
    echo "  -v, --version       Mostra informazioni sulla versione"
    echo "  -d, --dry-run       Simula le operazioni senza applicare cambiamenti"
    echo "  -p, --path PATH     Specifica il percorso di installazione di Moodle"
    echo "  -m, --moodledata PATH Specifica il percorso di moodledata"
    echo ""
    echo "Esempi:"
    echo "  $0                    # Esegue con i percorsi predefiniti"
    echo "  $0 -d                 # Modalità dry-run"
    echo "  $0 -p /opt/moodle     # Specifica percorso personalizzato"
    echo ""
}

# Funzione per mostrare la versione
show_version() {
    echo "Moodle 4 Permissions Manager v${SCRIPT_RELEASE}"
    echo "Codename: ${SCRIPT_CODENAME}"
    echo "Release Date: ${SCRIPT_DATE}"
    echo "Author: ${SCRIPT_AUTHOR}"
    echo "License: ${SCRIPT_LICENSE}"
    echo "Compatible with: Moodle 4.x, Debian 11/12, Ubuntu 20.04/22.04"
    exit 0
}

# Funzione per verificare l'esistenza delle directory
check_directories() {
    if [ ! -d "$MOODLE_DIR" ]; then
        echo "❌ ERRORE: Directory Moodle non trovata: $MOODLE_DIR"
        exit 1
    fi
    
    if [ ! -d "$MOODLEDATA_DIR" ]; then
        echo "❌ ERRORE: Directory Moodledata non trovata: $MOODLEDATA_DIR"
        exit 1
    fi
}

# Funzione per il dry-run
dry_run() {
    echo "🔍 [DRY-RUN] Modalità simulazione attiva - Nessuna modifica verrà applicata"
    echo ""
    echo "📋 Operazioni che verrebbero eseguite:"
    echo "   chown -R ${WWW_USER}:${WWW_GROUP} \"$MOODLE_DIR\""
    echo "   chown -R ${WWW_USER}:${WWW_GROUP} \"$MOODLEDATA_DIR\""
    echo "   find \"$MOODLE_DIR\" -type d -exec chmod 755 {} \\;"
    echo "   find \"$MOODLE_DIR\" -type f -exec chmod 644 {} \\;"
    echo "   find \"$MOODLEDATA_DIR\" -type d -exec chmod 770 {} \\;"
    echo "   find \"$MOODLEDATA_DIR\" -type f -exec chmod 660 {} \\;"
    
    if [ -f "$MOODLE_DIR/config.php" ]; then
        echo "   chmod 640 \"$MOODLE_DIR/config.php\""
    fi
    
    # Directory specifiche Moodle 4
    local special_dirs=("cache" "temp" "sessions" "lang" "h5p" "backup" "restore" "trashdir" "webservice")
    for dir in "${special_dirs[@]}"; do
        if [ -d "$MOODLEDATA_DIR/$dir" ]; then
            echo "   chmod 770 \"$MOODLEDATA_DIR/$dir\""
        fi
    done
    
    if [ -d "$MOODLE_DIR/admin/cli" ]; then
        echo "   find \"$MOODLE_DIR/admin/cli\" -name \"*.php\" -exec chmod 755 {} \\;"
    fi
    
    echo ""
    echo "✅ [DRY-RUN] Simulazione completata - Nessuna modifica applicata"
    exit 0
}

# Parsing degli argomenti
DRY_RUN=false
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_header
            show_help
            exit 0
            ;;
        -v|--version)
            show_version
            ;;
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -p|--path)
            MOODLE_DIR="$2"
            shift 2
            ;;
        -m|--moodledata)
            MOODLEDATA_DIR="$2"
            shift 2
            ;;
        *)
            echo "❌ Argomento sconosciuto: $1"
            echo "Usa $0 --help per vedere le opzioni disponibili"
            exit 1
            ;;
    esac
done

# Mostra header
show_header

# Verifica che lo script sia eseguito come root
if [ "$(id -u)" -ne 0 ]; then
    echo "❌ Questo script deve essere eseguito come root"
    exit 1
fi

# Esegui dry-run se richiesto
if [ "$DRY_RUN" = true ]; then
    dry_run
fi

echo "🔍 Verifica directory..."
check_directories

echo "👤 Impostazione proprietà..."
chown -R ${WWW_USER}:${WWW_GROUP} "$MOODLE_DIR"
chown -R ${WWW_USER}:${WWW_GROUP} "$MOODLEDATA_DIR"

echo "📁 Impostazione permessi base Moodle..."
find "$MOODLE_DIR" -type d -exec chmod 755 {} \;
find "$MOODLE_DIR" -type f -exec chmod 644 {} \;

# Verifica se config.php esiste prima di modificarlo
if [ -f "$MOODLE_DIR/config.php" ]; then
    echo "🔒 Protezione config.php..."
    chmod 640 "$MOODLE_DIR/config.php"
else
    echo "⚠️  Attenzione: config.php non trovato in $MOODLE_DIR"
fi

echo "💾 Impostazione permessi moodledata..."
find "$MOODLEDATA_DIR" -type d -exec chmod 770 {} \;
find "$MOODLEDATA_DIR" -type f -exec chmod 660 {} \;

# PERMESSI SPECIFICI MOODLE 4
echo "⚙️  Impostazione permessi specifici Moodle 4..."

# Script CLI (essenziali per Moodle 4)
if [ -d "$MOODLE_DIR/admin/cli" ]; then
    find "$MOODLE_DIR/admin/cli" -name "*.php" -exec chmod 755 {} \;
    echo "   ✅ Script CLI impostati come eseguibili"
fi

# Directory per cache (critica in Moodle 4)
if [ -d "$MOODLEDATA_DIR/cache" ]; then
    chmod 770 "$MOODLEDATA_DIR/cache"
    echo "   ✅ Cache directory impostata a 770"
fi

# Directory per file temporanei
if [ -d "$MOODLEDATA_DIR/temp" ]; then
    chmod 770 "$MOODLEDATA_DIR/temp"
    echo "   ✅ Temp directory impostata a 770"
fi

# Directory per sessioni
if [ -d "$MOODLEDATA_DIR/sessions" ]; then
    chmod 770 "$MOODLEDATA_DIR/sessions"
    echo "   ✅ Sessions directory impostata a 770"
fi

# Directory per lingue (può richiedere scrittura per aggiornamenti)
if [ -d "$MOODLEDATA_DIR/lang" ]; then
    chmod 770 "$MOODLEDATA_DIR/lang"
    echo "   ✅ Lang directory impostata a 770"
fi

# Permessi per H5P (integrato in Moodle 4)
if [ -d "$MOODLEDATA_DIR/h5p" ]; then
    chmod 770 "$MOODLEDATA_DIR/h5p"
    echo "   ✅ H5P directory impostata a 770"
fi

# Permessi per backup
if [ -d "$MOODLEDATA_DIR/backup" ]; then
    chmod 770 "$MOODLEDATA_DIR/backup"
    echo "   ✅ Backup directory impostata a 770"
fi

# Permessi per restore
if [ -d "$MOODLEDATA_DIR/restore" ]; then
    chmod 770 "$MOODLEDATA_DIR/restore"
    echo "   ✅ Restore directory impostata a 770"
fi

# Directory cestino (trashdir in Moodle 4)
if [ -d "$MOODLEDATA_DIR/trashdir" ]; then
    chmod 770 "$MOODLEDATA_DIR/trashdir"
    echo "   ✅ Trash directory impostata a 770"
fi

# Permessi speciali per webservice
if [ -d "$MOODLEDATA_DIR/webservice" ]; then
    chmod 770 "$MOODLEDATA_DIR/webservice"
    echo "   ✅ Webservice directory impostata a 770"
fi

# Directory per filestorage (importante in Moodle 4)
if [ -d "$MOODLEDATA_DIR/filedir" ]; then
    chmod 770 "$MOODLEDATA_DIR/filedir"
    echo "   ✅ Filedir directory impostata a 770"
fi

# Directory per i repository
if [ -d "$MOODLEDATA_DIR/repository" ]; then
    chmod 770 "$MOODLEDATA_DIR/repository"
    echo "   ✅ Repository directory impostata a 770"
fi

# Directory per i log (cruciale per il debugging)
if [ -d "$MOODLEDATA_DIR/log" ]; then
    chmod 770 "$MOODLEDATA_DIR/log"
    echo "   ✅ Log directory impostata a 770"
fi

# Verifica permessi directory critiche
echo "🔍 Verifica permessi directory critiche..."
for dir in "$MOODLEDATA_DIR" "$MOODLE_DIR"; do
    if [ -d "$dir" ]; then
        perms=$(stat -c "%a %U:%G" "$dir")
        echo "   📁 $dir: $perms"
    fi
done

# Verifica permessi directory specifiche Moodle 4
echo "🔍 Verifica permessi directory specifiche Moodle 4..."
moodle4_dirs=("cache" "filedir" "temp" "sessions" "lang")
for dir in "${moodle4_dirs[@]}"; do
    if [ -d "$MOODLEDATA_DIR/$dir" ]; then
        perms=$(stat -c "%a %U:%G" "$MOODLEDATA_DIR/$dir")
        echo "   📁 $MOODLEDATA_DIR/$dir: $perms"
    fi
done

echo ""
echo "✅ Permessi Moodle 4 impostati correttamente!"
echo ""
echo "📋 Riepilogo configurazione:"
echo "   - Versione script: ${SCRIPT_RELEASE} (${SCRIPT_CODENAME})"
echo "   - Moodle dir: $MOODLE_DIR (755/644)"
echo "   - Moodledata: $MOODLEDATA_DIR (770/660)" 
echo "   - Proprietario: $WWW_USER:$WWW_GROUP"
echo "   - config.php: 640 (se presente)"
echo "   - Script CLI: 755"
echo "   - Directory critiche: 770"
echo ""
echo "⚠️  Note importanti per Moodle 4:"
echo "   - PHP 7.4/8.0 richiesto (8.0+ raccomandato)"
echo "   - Estensioni PHP: xml, curl, zip, gd, intl, json, mbstring"
echo "   - MySQL 5.7+ o PostgreSQL 9.5+ o MariaDB 10.4+"
echo "   - Controlla regolarmente i log in $MOODLEDATA_DIR/log/"
echo ""
echo "🔧 Directory specifiche Moodle 4 gestite:"
echo "   - cache/, filedir/, temp/, sessions/, lang/"
echo "   - h5p/, backup/, restore/, trashdir/, repository/"
echo ""
echo "================================================================================"
echo "Moodle 4 Permissions Manager v${SCRIPT_RELEASE} - Operazione completata"
echo "================================================================================"