#!/bin/bash

usage() {
   echo "$0 [options...]"
   echo ""
   echo "    -f,--fname"
   echo "    -b,--bucket-name"
   echo "    --mysql-host"
   echo "    --mysql-port"
   echo "    --mysql-db          add mysql db to list of dbs"
   echo "    --help"
   exit
}

COMMAND=
FNAME=
BUCKET_NAME=
MYSQL_HOST=
MYSQL_PORT=
MYSQL_DATABASES=''

while [[ $# > 0 ]]; do
   key="$1"
   case $key in
      freeze|thaw)
	 COMMAND="$key"
	 ;;
      -f|--fname)
	 FNAME="$2"
	 shift
	 ;;
      -b|--bucket-name)
	 BUCKET_NAME="$2"
	 shift
	 ;;
      --mysql-host)
	 MYSQL_HOST="$2"
	 shift
	 ;;
      --mysql-port)
	 MYSQL_PORT="$2"
	 shift
	 ;;
      --mysql-db)
	 MYSQL_DATABASES="${MYSQL_DATABASES} ${2}"
	 shift
	 ;;
      -h|--help)
	 usage
	 ;;
      *)
	 # unknown option
	 ;;
   esac
   shift
done

echo "won't you step into the freezer"

# strip whitespace just to be pretty
MYSQL_DATABASES="${MYSQL_DATABASES# }"
FROZEN_FILE="s3://${BUCKET_NAME}/${FNAME}"

if [[ $COMMAND == 'freeze' ]]; then

  echo "freezing mysql dbs '${MYSQL_DATABASES}' to ${FROZEN_FILE}"
  mysqldump -h${MYSQL_HOST} -P${MYSQL_PORT} --databases ${MYSQL_DATABASES} | gzip --fast | aws s3 cp - ${FROZEN_FILE}

elif [[ $COMMAND == 'thaw' ]]; then

  echo "thawing mysql dbs from ${FROZEN_FILE}"
  aws s3 cp ${FROZEN_FILE} - | gunzip | mysql -h${MYSQL_HOST} -P${MYSQL_PORT}

else
  echo "unknown command: ${COMMAND}"
  exit 11
fi

echo "exiting"
