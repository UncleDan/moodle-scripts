#!/bin/bash
# ========================================================
# Permessi e proprietà per Moodle 4.x su Debian 12
# ========================================================

MOODLE_DIR="/var/www/moodle"
MOODLEDATA_DIR="/var/moodledata"
WWW_USER="www-data"
WWW_GROUP="www-data"

echo "Impostazione proprietà..."
chown -R ${WWW_USER}:${WWW_GROUP} "$MOODLE_DIR"
chown -R ${WWW_USER}:${WWW_GROUP} "$MOODLEDATA_DIR"

echo "Impostazione permessi Moodle..."
find "$MOODLE_DIR" -type d -exec chmod 755 {} \;
find "$MOODLE_DIR" -type f -exec chmod 644 {} \;

echo "Protezione config.php..."
chmod 640 "$MOODLE_DIR/config.php"

echo "Impostazione permessi moodledata..."
find "$MOODLEDATA_DIR" -type d -exec chmod 770 {} \;
find "$MOODLEDATA_DIR" -type f -exec chmod 660 {} \;

echo "✅ Permessi impostati correttamente."
