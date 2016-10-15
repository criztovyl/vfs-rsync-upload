#!/bin/bash

# Constants

PREFIX="$HOME/.p12g"
NAME_REMOTES="remotes"
NAME_MIRR="mirrors"
NAME_BATCH="batch"
NAME_STG="staging"
NAME_QA="qa"
NAME_PROD="production"
NAME_CFG=".p12g"
NAME_SYNC="sync_dir"

# Err Constants
ERR_NO_NAME_CFG=2
ERR_FAILED_WRITE_CFG=3
ERR_REMOTE_NO_DIR=4
ERR_PREFIX_NAME_MISSING=5
ERR_UNKNOWN_TARGET=6

# Globals
RSYNC_EXCL=`echo --exclude{" /$NAME_STG"," /$NAME_QA"}`
RSYNC="rsync -via --no-times --chmod=Da+rx $RSYNC_EXCL"

[ -d "$PREFIX" ] || mkdir -p $PREFIX

GET_PDIR(){
    # Args: target

    local target=${1:-PDIR}

    [ -f $NAME_CFG ] || { echo "No config file found! Abort." >&2; exit $ERR_NO_CFG_FILE; }

    local dir=`cat $NAME_CFG`
    eval $target=$PREFIX/$dir
}

if [[ "$1" =~ -{1,2}h(elp)? ]]; then
    # Idention need to be with hard tabs!
    cat <<-HELP
	Usage: $(basename $0) action params

	setup remote what name
	- remote: The vfs remote to connect to (creates "$NAME_STG" and "$NAME_QA" dirs.)
	- what: which dir to sync, defaults to current dir (".")
	- name: a human-readable name prefixed to the config dir in "$PREFIX"

	upload staging|stg|qa|production|prod
	- staging, stg:
	Uploads to REMOTE/staging
	- qa:
	Uploads to REMOTE/qa
	- production, prod:
	Uploads to REMOTE
	HELP
    exit 0
fi

case $1 in

    setup)

        REMOTE=$2
        WHAT=${3:-$(pwd -P)}
        NAME=$4
        RSYNC_INIT_EXTRA=$5

        WHAT=$(realpath "$WHAT")

        [ "$NAME" ] && ID=$NAME"-"
        ID=$ID`cat /dev/urandom | tr -dc "a-zA-Z0-9" | fold -w28 | head -n1`

        [ -f "$NAME_CFG" ] || echo $ID > "$NAME_CFG"
        [ -f "$NAME_CFG" ] || { echo "Could not write config file $NAME_CFG! Abort." >&2; exit $ERR_FAILED_WRITE_CFG; }

        GET_PDIR

        mkdir -p "$PDIR" && pushd $_ >/dev/null 

        [ -e "$NAME_SYNC" ] && rm "$NAME_SYNC"
        ln -s "$WHAT" "$NAME_SYNC"

        mkdir -p {"$NAME_REMOTES","$NAME_MIRR","$NAME_BATCH"}
        mkdir -p {"$NAME_MIRR","$NAME_BATCH"}/{"$NAME_STG","$NAME_QA","$NAME_PROD"}

        if [ -d "$REMOTE" ]; then
            mkdir -p "$REMOTE"/{"$NAME_STG","$NAME_QA"}
        else
            echo "Remote \"$REMOTE\" is not a directory!"
            exit $ERR_REMOTE_NO_DIR
        fi

        rm "$NAME_REMOTES/"{"$NAME_PROD","$NAME_STG","$NAME_QA"}
        ln -s "$REMOTE" "$NAME_REMOTES/$NAME_PROD"
        ln -s "$REMOTE/$NAME_STG" "$NAME_REMOTES/$NAME_STG"
        ln -s "$REMOTE/$NAME_QA" "$NAME_REMOTES/$NAME_QA"

        $RSYNC $RSYNC_INIT_EXTRA {"$NAME_REMOTES","$NAME_MIRR"}"/$NAME_PROD/"
        $RSYNC $RSYNC_INIT_EXTRA {"$NAME_REMOTES","$NAME_MIRR"}"/$NAME_QA/"
        $RSYNC $RSYNC_INIT_EXTRA {"$NAME_REMOTES","$NAME_MIRR"}"/$NAME_STG/"

        popd >/dev/null
        ;;
    upload)

        GET_PDIR

        [ -d "$PDIR" ] || { echo "Prefix dir \"$PDIR\" does not exits!\n Did you setup?" >&2; exit $ERR_PREFIX_NAME_MISSING; }

        case $2 in
            ""|stg|staging)
                target=$NAME_STG
                ;;
            qa)
                target=$NAME_QA
                ;;
            prod|production)
                target=$NAME_PROD
                ;;
            *)
                echo "Unknown target \"$2\"!" >&2
                exit $ERR_UNKNOWN_TARGET;
                ;;
        esac

        $RSYNC --write-batch="$PDIR/$NAME_BATCH/$target/batch" "$PDIR/$NAME_SYNC/" "$PDIR/$NAME_MIRR/$target"
        "$PDIR/$NAME_BATCH/$target/batch.sh" "$PDIR/$NAME_REMOTES/$target/"
        ;;
esac
