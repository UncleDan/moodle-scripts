#!/bin/bash
# ========================================================
# Permessi e proprietà per Moodle 4.x su Debian 12
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

echo "📁 Impostazione permessi Moodle..."
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

# Permessi speciali per alcune directory di Moodle
echo "⚙️  Impostazione permessi speciali..."
if [ -d "$MOODLE_DIR/admin/cli" ]; then
    find "$MOODLE_DIR/admin/cli" -name "*.php" -exec chmod 755 {} \;
    echo "   ✅ Script CLI impostati come eseguibili"
fi

echo "✅ Permessi impostati correttamente!"
echo ""
echo "📋 Riepilogo:"
echo "   - Moodle dir: $MOODLE_DIR (755/644)"
echo "   - Moodledata: $MOODLEDATA_DIR (770/660)" 
echo "   - Proprietario: $WWW_USER:$WWW_GROUP"
echo "   - config.php: 640 (se presente)"