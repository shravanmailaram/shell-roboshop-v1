#!/bin/bash

ami_id="ami-0055977a6e828a4f4"
instance_type="t3.micro"
domain_name="dopsaws.online"
hosted_zone_id="Z09522363DO51QKHAWBEB"

for instance in $@
do
    echo "Creating instance: $instance"
done