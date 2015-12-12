#!/bin/bash

cd $(dirname $0)

for dbno in {1..14}
do
	DBNAME="hr$dbno"
	FILE="hr$dbno.sql"

	echo "Starting $FILE"

	psql $DBNAME < 01.pre.update.sql

	echo "Created $DBNAME"

done

export CLASSPATH=.:/root/baraza/build/baraza.jar:/root/baraza/build/lib/postgresql-8.4-702.jdbc4.jar:

psql -q hr < 02.pre.update.sql 

java -XX:-UseGCOverheadLimit -Xmx2048m -cp /root/baraza/build/baraza.jar org.baraza.DB.BMigration migrate.xml

psql -q hr < 03.update.sql

java com.tegemeo

psql -q hr < 04.update.sql

java -XX:-UseGCOverheadLimit -Xmx2048m -cp /root/baraza/build/baraza.jar org.baraza.DB.BMigration table_seq.xml | psql hr




