#!/bin/bash

usage() {
   echo "$0 [options...]"
   echo ""
   echo "    -s,--stack-id"
   echo "    -b,--bucket-name"
   echo "    --mysql-host"
   echo "    --mysql-port"
   echo "    --mysql-db          add mysql db to list of dbs"
   echo "    --help"
   exit
}

COMMAND=
STACK_ID=
BUCKET_NAME=
MYSQL_HOST=
MYSQL_PORT=
MYSQL_DATABASES=()

while [[ $# > 0 ]]; do
   key="$1"
   case $key in
      freeze|thaw)
	 COMMAND="$key"
	 ;;
      -s|--stack-id)
	 STACK_ID="$2"
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
	 db="$2"
	 MYSQL_DATABASES=(${MYSQL_DATABASES[@]} ${db})
	 shift
	 ;;
      --help)
	 usage
	 ;;
      *)
	 # unknown option
	 ;;
   esac
   shift
done

echo "won't you step into the freezer"

FROZEN_FILE="s3://${BUCKET_NAME}/freezer/frozen_stack_${STACK_ID}.sql.gz"

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
