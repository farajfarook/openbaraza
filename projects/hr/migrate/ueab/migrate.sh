#!/bin/bash

dropdb hri
createdb hri
psql -q hri < 01.import_payroll.sql

java -XX:-UseGCOverheadLimit -Xmx2048m -cp /root/baraza/build/baraza.jar org.baraza.DB.BMigration migrate.xml

psql -q hri < 02.import_payroll.sql

pg_dump hri > hri.sql

psql -q hr < hri.sql
