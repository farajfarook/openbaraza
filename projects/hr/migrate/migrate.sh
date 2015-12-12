#!/bin/bash

psql -q hr0 < pre0_update.sql 
psql -q hr < pre1_update.sql 

java -XX:-UseGCOverheadLimit -Xmx2048m -cp /root/baraza/build/baraza.jar org.baraza.DB.BMigration migrate.xml

psql -q hr < post_update.sql

