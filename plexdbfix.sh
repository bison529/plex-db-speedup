#!/bin/bash
#
######################################################################################################
# Cleans up Plex databases and increases PRAGMA setting to improve use of large remote video storage #
#                                                                                                    #
#                                                                                                    #
#  chmod a+x plexdbfix.sh                                                                            #
#  ./plexdbfix.sh                                                                                    #
######################################################################################################

PLEX_DATABASE="/opt/plex/Library/Application Support/Plex Media Server/Plug-in Support/Databases/com.plexapp.plugins.library.db"
PLEX_DATABASE_BLOBS="/opt/plex/Library/Application Support/Plex Media Server/Plug-in Support/Databases/com.plexapp.plugins.library.blobs.db"
PLEX_DATABASE_TRAKT="/opt/plex/Library/Application Support/Plex Media Server/Plug-in Support/Databases/com.plexapp.plugins.trakttv.db"

SQLITE3="/usr/bin/sqlite3"
SQLDUMP="/tmp/dump.sql"
BACKUPDIR="/opt/plex/maintenance"

if [ ! -d "$BACKUPDIR" ] ; then
  sudo mkdir /opt/plex/maintenance
fi

if [ ! -e "$SQLDUMP" ] ; then
  sudo touch /tmp/dump.sql
fi

NO_FORMAT="\033[0m"
C_ORANGE1="\033[38;5;214m"
C_SPRINGGREEN3="\033[38;5;41m"
C_RED1="\033[38;5;196m"
C_YELLOW1="\033[38;5;226m"
C_DODGERBLUE1="\033[38;5;33m"
C_PURPLE="\033[38;5;129m"
echo -e "${C_RED1}Stopping Plex Docker Container${NO_FORMAT}"
docker stop plex
wait
echo -e "${C_PURPLE}Starting Maintenance${NO_FORMAT}"
#
echo -e "${C_PURPLE}Checking for sqlite installation${NO_FORMAT}"
if type sqlite3 >/dev/null 2>&1 ; then
        echo -e "${C_SPRINGGREEN3}sqlite already installed.${NO_FORMAT}"
else 
        echo -e "${C_PURPLE}sqlite installing...${NO_FORMAT}" && apt update && apt install sqlite
fi
#
sudo rm $BACKUPDIR/*
sudo rm $SQLDUMP
#
echo -e "${C_PURPLE}Copying Plex databases to /opt/plex/maintenance ${NO_FORMAT}"
sudo cp -f "$PLEX_DATABASE" "$BACKUPDIR/com.plexapp.plugins.library.db-$(date +"%Y-%m-%d")"
sudo cp -f "$PLEX_DATABASE_BLOBS" "$BACKUPDIR/com.plexapp.plugins.library.blobs.db-$(date +"%Y-%m-%d")"
sudo cp -f "$PLEX_DATABASE_TRAKT" "$BACKUPDIR/com.plexapp.plugins.trakttv.db-$(date +"%Y-%m-%d")"
#
echo -e "${C_PURPLE}PRAGMA optimize main database & cache size set to 9000000${NO_FORMAT}"
$SQLITE3 "$PLEX_DATABASE" "PRAGMA optimize"
$SQLITE3 "$PLEX_DATABASE" vacuum
$SQLITE3 "$PLEX_DATABASE" .dump > "$SQLDUMP"
sudo rm "$PLEX_DATABASE"
$SQLITE3 "$PLEX_DATABASE" < "$SQLDUMP"
$SQLITE3 -header -line "$PLEX_DATABASE" "PRAGMA default_cache_size = 9000000"
$SQLITE3 "$PLEX_DATABASE" "PRAGMA optimize"
sudo rm "$SQLDUMP"
#
echo -e "${C_PURPLE}PRAGMA optimize blob database${NO_FORMAT}"
$SQLITE3 "$PLEX_DATABASE_BLOBS" "PRAGMA optimize"
$SQLITE3 "$PLEX_DATABASE_BLOBS" vacuum
$SQLITE3 "$PLEX_DATABASE_BLOBS" .dump > "$SQLDUMP"
sudo rm "$PLEX_DATABASE_BLOBS"
$SQLITE3 "$PLEX_DATABASE_BLOBS" < "$SQLDUMP"
$SQLITE3 "$PLEX_DATABASE_BLOBS" "PRAGMA optimize"
sudo rm "$SQLDUMP"
#
echo -e "${C_PURPLE}PRAGMA optimize Trakt database${NO_FORMAT}"
$SQLITE3 "$PLEX_DATABASE_TRAKT" "PRAGMA optimize"
$SQLITE3 "$PLEX_DATABASE_TRAKT" vacuum
$SQLITE3 "$PLEX_DATABASE_TRAKT" .dump > "$SQLDUMP"
sudo rm "$PLEX_DATABASE_TRAKT"
$SQLITE3 "$PLEX_DATABASE_TRAKT" < "$SQLDUMP"
$SQLITE3 "$PLEX_DATABASE_TRAKT" "PRAGMA optimize"
sudo rm "$SQLDUMP"
sudo chown -R seed:seed "/opt/plex/Library/Application Support/Plex Media Server/Plug-in Support/Databases/"
#
sudo rm -rf "/opt/plex/Library/Application Support/Plex Media Server/Codecs/"*
#
echo 3 > /proc/sys/vm/drop_caches && swapoff -a && swapon -a
#
echo -e "${C_SPRINGGREEN3}Starting Plex Docker Container${NO_FORMAT}"
docker start plex
wait

#
echo -e "${C_PURPLE}Maintenance Finished${NO_FORMAT}!"
exit
