#!/bin/bash
# ========================================================
# Moodle Permissions Manager - Unified Script
# Supports Moodle 4.x and 5.x
# ========================================================

# Variabile di release in stile Ubuntu (SCRIPT RELEASE)
SCRIPT_RELEASE="25.10"
SCRIPT_CODENAME="Universal Hawk"
SCRIPT_DATE="2025-10-25"
SCRIPT_AUTHOR="Daniele Lolli (UncleDan)"
SCRIPT_LICENSE="GPL-3.0"

# Versione Moodle di default (indipendente dalla release dello script)
DEFAULT_MOODLE_VERSION="4"

set -e  # Esce immediatamente in caso di errore

# Configurazioni predefinite
MOODLE_DIR="/var/www/moodle"
MOODLEDATA_DIR="/var/moodledata"
WWW_USER="www-data"
WWW_GROUP="www-data"

# Determina versione Moodle (usa default se non specificata)
MOODLE_VERSION="$DEFAULT_MOODLE_VERSION"

# Funzione per mostrare l'header
show_header() {
    echo "================================================================================"
    echo "Moodle Permissions Manager v${SCRIPT_RELEASE} (${SCRIPT_CODENAME})"
    echo "================================================================================"
    echo "Author: ${SCRIPT_AUTHOR}"
    echo "Release: ${SCRIPT_RELEASE} - ${SCRIPT_DATE}"
    echo "License: ${SCRIPT_LICENSE}"
    echo "Default Moodle Version: ${DEFAULT_MOODLE_VERSION}.x"
    echo "Selected Moodle Version: ${MOODLE_VERSION}.x"
    echo "================================================================================"
    echo ""
}

# Funzione per mostrare l'help
show_help() {
    echo "Utilizzo: $0 [OPZIONI]"
    echo ""
    echo "Opzioni:"
    echo "  -h, --help              Mostra questo help"
    echo "  -v, --version           Mostra informazioni sulla versione"
    echo "  -d, --dry-run           Simula le operazioni senza applicare cambiamenti"
    echo "  -s, --show-perms        Mostra i permessi attuali senza modificare"
    echo "  -mp, --moodlepath PATH  Specifica il percorso di installazione di Moodle"
    echo "  -md, --moodledata PATH  Specifica il percorso di moodledata"
    echo "  -mv, --moodleversion VERSION Specifica versione Moodle (4|5)"
    echo ""
    echo "Esempi:"
    echo "  $0                               # Usa versione default (Moodle ${DEFAULT_MOODLE_VERSION})"
    echo "  $0 -mv 5                         # Forza versione Moodle 5"
    echo "  $0 -mv 4 -d                      # Moodle 4 in dry-run"
    echo "  $0 -mv 5 -s                      # Mostra permessi attuali Moodle 5"
    echo "  $0 -mp /opt/moodle -mv 5         # Percorso personalizzato + versione"
    echo "  $0 -mp /opt/moodle -md /opt/moodledata -mv 4 -s  # Tutti i parametri + show"
    echo ""
    echo "Note:"
    echo "  Versione Moodle di default: ${DEFAULT_MOODLE_VERSION}.x"
    echo "  Versione script: ${SCRIPT_RELEASE}"
}

# Funzione per mostrare la versione
show_version() {
    echo "Moodle Permissions Manager v${SCRIPT_RELEASE}"
    echo "Codename: ${SCRIPT_CODENAME}"
    echo "Release Date: ${SCRIPT_DATE}"
    echo "Author: ${SCRIPT_AUTHOR}"
    echo "License: ${SCRIPT_LICENSE}"
    echo "Default Moodle Version: ${DEFAULT_MOODLE_VERSION}.x"
    echo "Compatible with: Moodle 4.x & 5.x, Debian 11/12, Ubuntu 20.04+"
    exit 0
}

# Funzione per validare la versione Moodle
validate_moodle_version() {
    local version=$1
    if [[ "$version" != "4" && "$version" != "5" ]]; then
        echo "❌ ERRORE: Versione Moodle non valida: '$version'"
        echo "   Usa '4' per Moodle 4.x o '5' per Moodle 5.x"
        exit 1
    fi
}

# Funzione per verificare l'esistenza delle directory principali
check_main_directories() {
    if [ ! -d "$MOODLE_DIR" ]; then
        echo "❌ ERRORE: Directory Moodle non trovata: $MOODLE_DIR"
        exit 1
    fi
    
    if [ ! -d "$MOODLEDATA_DIR" ]; then
        echo "❌ ERRORE: Directory Moodledata non trovata: $MOODLEDATA_DIR"
        exit 1
    fi
}

# Funzione per mostrare i permessi attuali Moodle 4
show_moodle4_permissions() {
    echo "🔍 Permessi attuali directory Moodle 4:"
    echo ""
    
    echo "📁 Directory principali:"
    for dir in "$MOODLE_DIR" "$MOODLEDATA_DIR"; do
        if [ -d "$dir" ]; then
            perms=$(stat -c "%a %U:%G" "$dir")
            echo "   $dir: $perms"
        else
            echo "   $dir: ❌ NON TROVATA"
        fi
    done
    
    echo ""
    echo "📁 Directory specifiche Moodle 4:"
    local moodle4_dirs=("cache" "temp" "sessions" "lang" "h5p" "backup" "restore" "trashdir" "webservice" "filedir" "repository" "log")
    
    for dir in "${moodle4_dirs[@]}"; do
        local full_path="$MOODLEDATA_DIR/$dir"
        if [ -d "$full_path" ]; then
            perms=$(stat -c "%a %U:%G" "$full_path")
            echo "   $full_path: $perms"
        else
            echo "   $full_path: 📁 NON ESISTE"
        fi
    done
    
    echo ""
    echo "📁 File config.php:"
    if [ -f "$MOODLE_DIR/config.php" ]; then
        perms=$(stat -c "%a %U:%G" "$MOODLE_DIR/config.php")
        echo "   $MOODLE_DIR/config.php: $perms"
    else
        echo "   $MOODLE_DIR/config.php: ❌ NON TROVATO"
    fi
    
    echo ""
    echo "📁 Script CLI:"
    if [ -d "$MOODLE_DIR/admin/cli" ]; then
        local cli_scripts=$(find "$MOODLE_DIR/admin/cli" -name "*.php" | head -3)
        if [ -n "$cli_scripts" ]; then
            echo "   Prime 3 script CLI:"
            while IFS= read -r script; do
                if [ -f "$script" ]; then
                    perms=$(stat -c "%a %U:%G" "$script")
                    echo "   $script: $perms"
                fi
            done <<< "$cli_scripts"
        else
            echo "   Nessuno script CLI trovato"
        fi
    else
        echo "   Directory CLI non trovata"
    fi
}

# Funzione per mostrare i permessi attuali Moodle 5
show_moodle5_permissions() {
    echo "🔍 Permessi attuali directory Moodle 5:"
    echo ""
    
    echo "📁 Directory principali:"
    for dir in "$MOODLE_DIR" "$MOODLEDATA_DIR"; do
        if [ -d "$dir" ]; then
            perms=$(stat -c "%a %U:%G" "$dir")
            echo "   $dir: $perms"
        else
            echo "   $dir: ❌ NON TROVATA"
        fi
    done
    
    echo ""
    echo "📁 Directory specifiche Moodle 5:"
    local moodle5_dirs=("cache" "temp" "lock" "tasks" "localcache" "sessions" "lang" "h5p" "backup" "restore" "trash" "webservice")
    
    for dir in "${moodle5_dirs[@]}"; do
        local full_path="$MOODLEDATA_DIR/$dir"
        if [ -d "$full_path" ]; then
            perms=$(stat -c "%a %U:%G" "$full_path")
            echo "   $full_path: $perms"
        else
            echo "   $full_path: 📁 NON ESISTE"
        fi
    done
    
    echo ""
    echo "📁 File config.php:"
    if [ -f "$MOODLE_DIR/config.php" ]; then
        perms=$(stat -c "%a %U:%G" "$MOODLE_DIR/config.php")
        echo "   $MOODLE_DIR/config.php: $perms"
    else
        echo "   $MOODLE_DIR/config.php: ❌ NON TROVATO"
    fi
    
    echo ""
    echo "📁 Script CLI:"
    if [ -d "$MOODLE_DIR/admin/cli" ]; then
        local cli_scripts=$(find "$MOODLE_DIR/admin/cli" -name "*.php" | head -3)
        if [ -n "$cli_scripts" ]; then
            echo "   Prime 3 script CLI:"
            while IFS= read -r script; do
                if [ -f "$script" ]; then
                    perms=$(stat -c "%a %U:%G" "$script")
                    echo "   $script: $perms"
                fi
            done <<< "$cli_scripts"
        else
            echo "   Nessuno script CLI trovato"
        fi
    else
        echo "   Directory CLI non trovata"
    fi
}

# Funzione per mostrare i permessi attuali
show_current_permissions() {
    echo "🔍 [SHOW-PERMS] Visualizzazione permessi attuali - Nessuna modifica verrà applicata"
    echo "🎯 Versione Moodle: ${MOODLE_VERSION}.x"
    echo ""
    
    if [ "$MOODLE_VERSION" = "4" ]; then
        show_moodle4_permissions
    else
        show_moodle5_permissions
    fi
    
    echo ""
    echo "📋 Permessi raccomandati:"
    echo "   - Directory Moodle: 755 (dir) / 644 (file)"
    echo "   - Directory Moodledata: 770 (dir) / 660 (file)"
    echo "   - config.php: 640"
    echo "   - Script CLI: 755"
    echo "   - Proprietario: ${WWW_USER}:${WWW_GROUP}"
    
    exit 0
}

# Funzione per creare directory se non esistono
create_directory_if_missing() {
    local dir="$1"
    if [ ! -d "$dir" ]; then
        echo "📁 Creazione directory: $dir"
        mkdir -p "$dir"
        return 0  # Directory creata
    else
        return 1  # Directory già esistente
    fi
}

# Funzione per creare directory critiche Moodle 4
create_moodle4_directories() {
    echo "📁 Creazione directory critiche Moodle 4..."
    
    local moodle4_dirs=("cache" "temp" "sessions" "lang" "h5p" "backup" "restore" "trashdir" "webservice" "filedir" "repository" "log")
    
    for dir in "${moodle4_dirs[@]}"; do
        local full_path="$MOODLEDATA_DIR/$dir"
        if create_directory_if_missing "$full_path"; then
            echo "   ✅ Creata: $dir"
        else
            echo "   📁 Esistente: $dir"
        fi
    done
}

# Funzione per creare directory critiche Moodle 5
create_moodle5_directories() {
    echo "📁 Creazione directory critiche Moodle 5..."
    
    local moodle5_dirs=("cache" "temp" "lock" "tasks" "localcache" "sessions" "lang" "h5p" "backup" "restore" "trash" "webservice")
    
    for dir in "${moodle5_dirs[@]}"; do
        local full_path="$MOODLEDATA_DIR/$dir"
        if create_directory_if_missing "$full_path"; then
            echo "   ✅ Creata: $dir"
        else
            echo "   📁 Esistente: $dir"
        fi
    done
}

# Funzione per impostare permessi Moodle 4
set_moodle4_permissions() {
    echo "🎯 Impostazione permessi specifici Moodle 4..."
    
    local moodle4_dirs=("cache" "temp" "sessions" "lang" "h5p" "backup" "restore" "trashdir" "webservice" "filedir" "repository" "log")
    
    for dir in "${moodle4_dirs[@]}"; do
        if [ -d "$MOODLEDATA_DIR/$dir" ]; then
            chmod 770 "$MOODLEDATA_DIR/$dir"
            echo "   ✅ $dir directory impostata a 770"
        fi
    done
}

# Funzione per impostare permessi Moodle 5
set_moodle5_permissions() {
    echo "🎯 Impostazione permessi specifici Moodle 5..."
    
    local moodle5_dirs=("cache" "temp" "lock" "tasks" "localcache" "sessions" "lang" "h5p" "backup" "restore" "trash" "webservice")
    
    for dir in "${moodle5_dirs[@]}"; do
        if [ -d "$MOODLEDATA_DIR/$dir" ]; then
            chmod 770 "$MOODLEDATA_DIR/$dir"
            echo "   ✅ $dir directory impostata a 770"
        fi
    done
}

# Funzione per dry-run Moodle 4
dry_run_moodle4() {
    echo "📋 Operazioni specifiche Moodle 4 che verrebbero eseguite:"
    
    local moodle4_dirs=("cache" "temp" "sessions" "lang" "h5p" "backup" "restore" "trashdir" "webservice" "filedir" "repository" "log")
    
    for dir in "${moodle4_dirs[@]}"; do
        if [ -d "$MOODLEDATA_DIR/$dir" ]; then
            echo "   chmod 770 \"$MOODLEDATA_DIR/$dir\""
        else
            echo "   mkdir -p \"$MOODLEDATA_DIR/$dir\" && chmod 770 \"$MOODLEDATA_DIR/$dir\""
        fi
    done
    
    echo ""
    echo "📝 Note specifiche Moodle 4:"
    echo "   - Directory 'trashdir' invece di 'trash'"
    echo "   - Directory 'filedir' per file storage principale"
    echo "   - Directory 'repository' per repository files"
    echo "   - Directory 'log' dedicata per i log"
}

# Funzione per dry-run Moodle 5
dry_run_moodle5() {
    echo "📋 Operazioni specifiche Moodle 5 che verrebbero eseguite:"
    
    local moodle5_dirs=("cache" "temp" "lock" "tasks" "localcache" "sessions" "lang" "h5p" "backup" "restore" "trash" "webservice")
    
    for dir in "${moodle5_dirs[@]}"; do
        if [ -d "$MOODLEDATA_DIR/$dir" ]; then
            echo "   chmod 770 \"$MOODLEDATA_DIR/$dir\""
        else
            echo "   mkdir -p \"$MOODLEDATA_DIR/$dir\" && chmod 770 \"$MOODLEDATA_DIR/$dir\""
        fi
    done
    
    echo ""
    echo "📝 Note specifiche Moodle 5:"
    echo "   - Directory 'lock' per gestione lock migliorata"
    echo "   - Directory 'tasks' per task scheduling"
    echo "   - Directory 'localcache' per cache locale"
    echo "   - Directory 'trash' invece di 'trashdir'"
}

# Funzione per il dry-run
dry_run() {
    echo "🔍 [DRY-RUN] Modalità simulazione attiva - Nessuna modifica verrà applicata"
    echo "🎯 Versione Moodle: ${MOODLE_VERSION}.x"
    echo ""
    
    echo "📋 Operazioni comuni che verrebbero eseguite:"
    echo "   chown -R ${WWW_USER}:${WWW_GROUP} \"$MOODLE_DIR\""
    echo "   chown -R ${WWW_USER}:${WWW_GROUP} \"$MOODLEDATA_DIR\""
    echo "   find \"$MOODLE_DIR\" -type d -exec chmod 755 {} \\;"
    echo "   find \"$MOODLE_DIR\" -type f -exec chmod 644 {} \\;"
    echo "   find \"$MOODLEDATA_DIR\" -type d -exec chmod 770 {} \\;"
    echo "   find \"$MOODLEDATA_DIR\" -type f -exec chmod 660 {} \\;"
    
    if [ -f "$MOODLE_DIR/config.php" ]; then
        echo "   chmod 640 \"$MOODLE_DIR/config.php\""
    else
        echo "   # config.php non trovato in $MOODLE_DIR (verrà saltato)"
    fi
    
    if [ -d "$MOODLE_DIR/admin/cli" ]; then
        echo "   find \"$MOODLE_DIR/admin/cli\" -name \"*.php\" -exec chmod 755 {} \\;"
    else
        echo "   # Directory CLI non trovata in $MOODLE_DIR/admin/cli (verrà saltata)"
    fi
    
    echo ""
    
    # Operazioni specifiche per versione
    if [ "$MOODLE_VERSION" = "4" ]; then
        dry_run_moodle4
    else
        dry_run_moodle5
    fi
    
    echo ""
    echo "🔍 Verifiche che verrebbero eseguite:"
    echo "   stat -c \"%a %U:%G\" \"$MOODLEDATA_DIR\""
    echo "   stat -c \"%a %U:%G\" \"$MOODLE_DIR\""
    
    echo ""
    echo "✅ [DRY-RUN] Simulazione completata - Nessuna modifica applicata"
    exit 0
}

# Parsing degli argomenti
DRY_RUN=false
SHOW_PERMS=false
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
        -s|--show-perms)
            SHOW_PERMS=true
            shift
            ;;
        -mp|--moodlepath)
            MOODLE_DIR="$2"
            shift 2
            ;;
        -md|--moodledata)
            MOODLEDATA_DIR="$2"
            shift 2
            ;;
        -mv|--moodleversion)
            MOODLE_VERSION="$2"
            validate_moodle_version "$MOODLE_VERSION"
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

echo "🎯 Configurazione rilevata:"
echo "   - Versione Moodle: ${MOODLE_VERSION}.x"
echo "   - Directory Moodle: $MOODLE_DIR"
echo "   - Directory Moodledata: $MOODLEDATA_DIR"
echo ""

# Verifica che lo script sia eseguito come root (tranne per show-perms)
if [ "$SHOW_PERMS" = false ] && [ "$(id -u)" -ne 0 ]; then
    echo "❌ Questo script deve essere eseguito come root"
    exit 1
fi

# Esegui show-perms se richiesto
if [ "$SHOW_PERMS" = true ]; then
    show_current_permissions
fi

# Esegui dry-run se richiesto
if [ "$DRY_RUN" = true ]; then
    dry_run
fi

echo "🔍 Verifica directory principali..."
check_main_directories

echo "📁 Creazione directory critiche..."
# Crea directory critiche in base alla versione
if [ "$MOODLE_VERSION" = "4" ]; then
    create_moodle4_directories
else
    create_moodle5_directories
fi

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

# Script CLI (comune a entrambe le versioni)
if [ -d "$MOODLE_DIR/admin/cli" ]; then
    find "$MOODLE_DIR/admin/cli" -name "*.php" -exec chmod 755 {} \;
    echo "✅ Script CLI impostati come eseguibili"
fi

# Impostazione permessi specifici per versione
if [ "$MOODLE_VERSION" = "4" ]; then
    set_moodle4_permissions
else
    set_moodle5_permissions
fi

# Verifica permessi directory critiche
echo "🔍 Verifica permessi directory critiche..."
for dir in "$MOODLEDATA_DIR" "$MOODLE_DIR"; do
    if [ -d "$dir" ]; then
        perms=$(stat -c "%a %U:%G" "$dir")
        echo "   📁 $dir: $perms"
    fi
done

# Verifica permessi directory specifiche
echo "🔍 Verifica permessi directory specifiche Moodle ${MOODLE_VERSION}..."
if [ "$MOODLE_VERSION" = "4" ]; then
    specific_dirs=("cache" "temp" "sessions" "lang" "h5p" "backup" "restore" "trashdir" "filedir" "repository" "log")
else
    specific_dirs=("cache" "temp" "lock" "tasks" "localcache" "sessions" "lang" "h5p" "backup" "restore" "trash")
fi

for dir in "${specific_dirs[@]}"; do
    if [ -d "$MOODLEDATA_DIR/$dir" ]; then
        perms=$(stat -c "%a %U:%G" "$MOODLEDATA_DIR/$dir")
        echo "   📁 $MOODLEDATA_DIR/$dir: $perms"
    fi
done

echo ""
echo "✅ Permessi Moodle ${MOODLE_VERSION}.x impostati correttamente!"
echo ""
echo "📋 Riepilogo configurazione:"
echo "   - Versione script: ${SCRIPT_RELEASE} (${SCRIPT_CODENAME})"
echo "   - Versione Moodle: ${MOODLE_VERSION}.x"
echo "   - Moodle dir: $MOODLE_DIR (755/644)"
echo "   - Moodledata: $MOODLEDATA_DIR (770/660)" 
echo "   - Proprietario: $WWW_USER:$WWW_GROUP"
echo "   - config.php: 640 (se presente)"
echo "   - Script CLI: 755"
echo ""

# Note specifiche per versione
if [ "$MOODLE_VERSION" = "4" ]; then
    echo "⚠️  Note importanti per Moodle 4:"
    echo "   - PHP 7.4/8.0 richiesto (8.0+ raccomandato)"
    echo "   - MySQL 5.7+ o PostgreSQL 9.5+ o MariaDB 10.4+"
    echo "   - Directory specifiche: trashdir/, filedir/, repository/"
else
    echo "⚠️  Note importanti per Moodle 5:"
    echo "   - PHP 8.1+ richiesto"
    echo "   - MySQL 8.0+ o PostgreSQL 13+ o MariaDB 10.6+ raccomandati"
    echo "   - Directory specifiche: trash/, localcache/, lock/, tasks/"
fi

echo "   - Controlla i log in $MOODLEDATA_DIR per errori"
echo ""
echo "================================================================================"
echo "Moodle Permissions Manager v${SCRIPT_RELEASE} - Operazione completata"
echo "Moodle ${MOODLE_VERSION}.x - Configurazione applicata con successo"
echo "================================================================================"
