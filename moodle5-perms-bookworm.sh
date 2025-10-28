#!/bin/bash
# ========================================================
# Permessi e proprietà per Moodle 5.x su Debian 12
# ========================================================

set -e  # Esce immediatamente in caso di errore

MOODLE_DIR="/var/www/moodle"
MOODLEDATA_DIR="/var/moodledata"
WWW_USER="www-data"
WWW_GROUP="www-data"

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

# Verifica che lo script sia eseguito come root
if [ "$(id -u)" -ne 0 ]; then
    echo "❌ Questo script deve essere eseguito come root"
    exit 1
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

# PERMESSI SPECIFICI MOODLE 5
echo "⚙️  Impostazione permessi specifici Moodle 5..."

# Script CLI (cruciali per Moodle 5)
if [ -d "$MOODLE_DIR/admin/cli" ]; then
    find "$MOODLE_DIR/admin/cli" -name "*.php" -exec chmod 755 {} \;
    echo "   ✅ Script CLI impostati come eseguibili"
fi

# Directory per cache e temp (importanti in Moodle 5)
if [ -d "$MOODLEDATA_DIR/cache" ]; then
    chmod 770 "$MOODLEDATA_DIR/cache"
    echo "   ✅ Cache directory impostata a 770"
fi

if [ -d "$MOODLEDATA_DIR/temp" ]; then
    chmod 770 "$MOODLEDATA_DIR/temp"
    echo "   ✅ Temp directory impostata a 770"
fi

# Directory per i lock (nuova in Moodle 5)
if [ -d "$MOODLEDATA_DIR/lock" ]; then
    chmod 770 "$MOODLEDATA_DIR/lock"
    echo "   ✅ Lock directory impostata a 770"
fi

# Directory per task scheduling (migliorata in Moodle 5)
if [ -d "$MOODLEDATA_DIR/tasks" ]; then
    chmod 770 "$MOODLEDATA_DIR/tasks"
    echo "   ✅ Tasks directory impostata a 770"
fi

# Directory per i localcache (specifica Moodle 5)
if [ -d "$MOODLEDATA_DIR/localcache" ]; then
    chmod 770 "$MOODLEDATA_DIR/localcache"
    echo "   ✅ Localcache directory impostata a 770"
fi

# Directory per i session data
if [ -d "$MOODLEDATA_DIR/sessions" ]; then
    chmod 770 "$MOODLEDATA_DIR/sessions"
    echo "   ✅ Sessions directory impostata a 770"
fi

# Directory per i lang (può richiedere scrittura)
if [ -d "$MOODLEDATA_DIR/lang" ]; then
    chmod 770 "$MOODLEDATA_DIR/lang"
    echo "   ✅ Lang directory impostata a 770"
fi

# Permessi per H5P (importante in Moodle 5)
if [ -d "$MOODLEDATA_DIR/h5p" ]; then
    chmod 770 "$MOODLEDATA_DIR/h5p"
    echo "   ✅ H5P directory impostata a 770"
fi

# Permessi per backup e restore
if [ -d "$MOODLEDATA_DIR/backup" ]; then
    chmod 770 "$MOODLEDATA_DIR/backup"
    echo "   ✅ Backup directory impostata a 770"
fi

if [ -d "$MOODLEDATA_DIR/restore" ]; then
    chmod 770 "$MOODLEDATA_DIR/restore"
    echo "   ✅ Restore directory impostata a 770"
fi

# Permessi per i file trash (nuova gestione in Moodle 5)
if [ -d "$MOODLEDATA_DIR/trash" ]; then
    chmod 770 "$MOODLEDATA_DIR/trash"
    echo "   ✅ Trash directory impostata a 770"
fi

# Permessi speciali per webservice (se presenti)
if [ -d "$MOODLEDATA_DIR/webservice" ]; then
    chmod 770 "$MOODLEDATA_DIR/webservice"
    echo "   ✅ Webservice directory impostata a 770"
fi

# Verifica permessi directory critiche
echo "🔍 Verifica permessi directory critiche..."
for dir in "$MOODLEDATA_DIR" "$MOODLE_DIR"; do
    if [ -d "$dir" ]; then
        perms=$(stat -c "%a %U:%G" "$dir")
        echo "   📁 $dir: $perms"
    fi
done

echo ""
echo "✅ Permessi Moodle 5 impostati correttamente!"
echo ""
echo "📋 Riepilogo:"
echo "   - Moodle dir: $MOODLE_DIR (755/644)"
echo "   - Moodledata: $MOODLEDATA_DIR (770/660)" 
echo "   - Proprietario: $WWW_USER:$WWW_GROUP"
echo "   - config.php: 640 (se presente)"
echo "   - Script CLI: 755"
echo "   - Directory critiche: 770"
echo ""
echo "⚠️  Note importanti per Moodle 5:"
echo "   - Assicurati che PHP 8.1+ sia installato"
echo "   - Verifica che le estensioni PHP richieste siano abilitate"
echo "   - Controlla i log in $MOODLEDATA_DIR per errori"
