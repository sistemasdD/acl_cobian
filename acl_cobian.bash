#!/usr/bin/env bash

setfacl -m u:backupdd:x /var/lib/psa/dumps/
setfacl -m mask::x /var/lib/psa/dumps/
setfacl -m u:backupdd:rwx /var/lib/psa/dumps/domains/
setfacl -m default:u:backupdd:rwx /var/lib/psa/dumps/domains/
setfacl -m mask::rwx /var/lib/psa/dumps/domains/
setfacl -m default:mask::rwx /var/lib/psa/dumps/domains/

shopt -q globstar ; _globstarStatus=$?
(( _globstarStatus )) && shopt -s globstar
setfacl -m u:backupdd:rwx /var/lib/psa/dumps/domains/**
setfacl -m default:u:backupdd:rwx /var/lib/psa/dumps/domains/**/
setfacl -m mask::rwx /var/lib/psa/dumps/domains/**
setfacl -m default:mask::rwx /var/lib/psa/dumps/domains/**/
(( _globstarStatus )) && shopt -u globstar

echo "Done";
