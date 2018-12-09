# generic things
export SRC_PATH="${BASH_SOURCE[1]}"
export SRC_PATH_REAL=`readlink -f $SRC_PATH`
export INCLUDES_DIR=$(dirname "$SRC_PATH_REAL");
export BASEDIR=$(dirname $INCLUDES_DIR);
export LOGS_DIR="${BASEDIR}/logs/";
export APPEND_TO_LOG="1"

logger() {
  [ -z $1 ] && APPEND=$APPEND_TO_LOG || APPEND=$1;
  [ -z $2 ] && LOGDIR=$LOGS_DIR || LOGDIR=$2;
  export LOGFILE="${LOGDIR}/install.log";
  export ERRLOG="${LOGDIR}/error.log";
  [ -d $LOGDIR ]  || mkdir -p $LOGDIR || { echo -e "ERROR:\nLOGDIR ${LOGDIR} could not be created."  && exit 1; };
  [ -f $ERRLOG ]  || touch $ERRLOG || { echo -e "ERROR:\nERRLOG $ERRLOG could not be created." && exit 2; };
  [ -f $LOGFILE ] || touch $LOGFILE || { echo -e "ERROR:\nLOGFILE $LOGFILE could not be created."  && exit 3; };
  [ -w $ERRLOG ]  || chmod +w $ERRLOG || { echo -e "ERROR:\ncould not make $ERRLOG writeable" && exit 4; }
  [ -w $LOGFILE ] || chmod +w $LOGFILE || { echo -e "ERROR:\ncould not make $LOGFILE writeable" && exit 5; };
  [ $APPEND == 0 ] && cat > $LOGFILE 2> $ERRLOG && exit 0 || { cat >> $LOGFILE 2>> $ERRLOG; };
}
