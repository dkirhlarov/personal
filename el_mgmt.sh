#!/bin/bash

# dmitrii.kyrkhlarov@lazada.com

help ()
{
echo "Elastic Search management interface. Usage:
$0 start (-n node1[,...] | -g group1[,...]) -d [0-9] -i image -c config [-o options,for,docker]
$0 stop (-n node1[,...] | -g group1[,...]) -d [0-9]
$0 list (-n node1[,...] | -g group1[,...])
$0 replace -p previous_image -i new_image -c config [-o options,for,docker] [-q [0-9]]
Where
-n	node name
-g	you can use predefined groups of nodes instead list of nodes (-n)
-d	docker container identity number
-i	docker image for container
-c	docker config file for usage
-o	docker extended options not included in config
-p	previous docker image for address restart containers
-q	number simultaneously restarted containers"
}

f_start ()
{
while getopts "n:g:d:i:c:o:" opt
do
case $opt in
n)
nodes=$OPTARG
;;
g)
groups=$OPTARG
;;
d)
docker=$OPTARG
;;
i)
image=$OPTARG
;;
c)
config=$OPTARG
;;
o)
options=$OPTARG
;;
*)
help
exit 1
;;
esac
done

if [ -z "$nodes" -a -z "$groups" ] || [ -z "$docker" ] || [ -z "$image" ] || [ -z "$config" ] ; then
help && exit 1
fi
return
}

f_stop ()
{
while getopts "n:g:d:" opt
do
case $opt in
n)
nodes=$OPTARG
;;
g)
groups=$OPTARG
;;
d)
docker=$OPTARG
;;
*)
help
exit 1
;;
esac
done

if [ -z "$nodes" -a -z "$groups" ] || [ -z "$docker" ] ; then
help && exit 1
fi
return
}

f_list ()
{
while getopts "n:g:" opt
do
case $opt in
n)
nodes=$OPTARG
;;
g)
groups=$OPTARG
;;
*)
help
exit 1
;;
esac
done

if [ -z "$nodes" -a -z "$groups" ] ; then
help && exit 1
fi
return
}

f_replace ()
{
while getopts "p:i:c:o:q:" opt
do
case $opt in
p)
previous_image=$OPTARG
;;
i)
image=$OPTARG
;;
c)
config=$OPTARG
;;
o)
options=$OPTARG
;;
q)
quant=$OPTARG
;;
*)
help
exit 1
;;
esac
done

if [ -z "$previous_image" ] || [ -z "$image" ] || [ -z "$config" ] ; then
help && exit 1
fi
return
}

run_start ()
{
echo "ansible-playbook --limit \"$nodes\" --limit \"$groups\" --tag start -a \"docker=$docker\" -a \"image=$image\" -a \"config=$config\" -a \"options="$options"\""
return
}

run_stop ()
{
echo "ansible-playbook --limit \"$nodes\" --limit \"$groups\" --tag stop -a \"docker=$docker\""
return
}

run_list ()
{
echo "ansible-playbook --limit \"$nodes\" --limit \"$groups\" --tag list"
return
}

run_replace ()
{
local _node
local _run_img
local _count_img=0
declare -A array_run_dockers
echo "ansible-playbook --tag list -a \"running_image=$previous_image\""
# supposed format:
# node1: container_name
cat replace_search_out | while IFS=: read _node _run_img; do
array_run_dockers[$_node]="${array_run_dockers[$_node]} $_run_img"
echo $_node
echo $_run_img
_count_img=$(($_count_img+1))
done

echo $_count_img
for i in "${!array_run_dockers[@]}"
do
echo "key: $i"
echo "value: ${array_run_dockers[$i]}"
done

return
}

key="$1"

case $key in
	start)
	shift
	f_start $@
	run_start
	;;
	stop)
	shift
	f_stop $@
	run_stop
	;;
	list)
	shift
	f_list $@
	run_list
	;;
	replace)
	shift
	f_replace $@
	run_replace
	;;
	help)
	help
	exit
	;;
	*)
	help
	exit 1
	;;
esac

echo "
nodes=$nodes
groups=$groups
docker=$docker
image=$image
config=$config
options=$options
previous_image=$previous_image
quant=$quant"

exit
