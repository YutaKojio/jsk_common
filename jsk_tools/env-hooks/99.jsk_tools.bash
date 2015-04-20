#!/bin/bash
# -*- mode: Shell-script; -*-

function rossetdefault() {
    local hostname=${1-"local"}
    local ros_port=${2-"11311"}
    echo "$hostname\n$ros_port" > ~/.rosdefault
    rosdefault
}
function rosdefault() {
    if [ -f ~/.rosdefault ]; then
        local hostname="$(sed -n 1p ~/.rosdefault)"
        local ros_port="$(sed -n 2p ~/.rosdefault)"
    else
        local hostname="local"
        local ros_port="11311"
    fi
    if [ "$hostname" = "local" ]; then
        rossetlocal $ros_port
    else
        rossetmaster $hostname $ros_port
    fi
}

function rossetmaster() { # 自分のよく使うロボットのhostnameを入れる
    local hostname=${1-"pr1040"}
    local ros_port=${2-"11311"}
    export ROS_MASTER_URI=http://$hostname:$ros_port
    if [ "$NO_ROS_PROMPT" = "" ]; then
        if [[ "${PS1}" =~ \[http://.*:.*\]\ (.*)$ ]] ; then
            export PS1="${BASH_REMATCH[1]}"
        fi
        export PS1="\[\033[00;31m\][$ROS_MASTER_URI][$ROS_IP]\[\033[00m\] ${PS1}"
    fi
    echo -e "\e[1;31mset ROS_MASTER_URI to $ROS_MASTER_URI\e[m"
}
function rossetrobot() {
    echo -e "\e[1;31m *** rossetrobot is obsoleted, use rossetmaster ***\e[m"
    rossetmaster $@
}

function rossetlocal() {
    rossetmaster localhost
    if [ "$NO_ROS_PROMPT" = "" ]; then
        if [[ "${PS1}" =~ \[http://.*:.*\]\ (.*)$ ]] ; then
            export PS1="${BASH_REMATCH[1]}"
        fi
    fi
}

function rossetip_dev() {
  local device=${1-"(eth0|eth1|eth2|eth3|eth4|wlan0|wlan1|wlan2|wlan3|wlan4)"}
  export ROS_IP=`PATH=$PATH:/sbin LANGUAGE=en LANG=C ifconfig | egrep -A1 "${device}"| grep inet\  | grep -v 127.0.0.1 | sed 's/.*inet addr:\([0-9\.]*\).*/\1/' | head -1`
  export ROS_HOSTNAME=$ROS_IP
}

function rossetip_addr() {
  local target_host=${1-"133.11.216.211"}
  ##target_hostip=$(host ${target_host} | sed -n -e 's/.*address \(.*\)/\1/gp')
  target_hostip=$(getent hosts ${target_host} | cut -f 1 -d ' ')
  if [ "$target_hostip" == "" ]; then target_hostip=$target_host; fi
  local mask_target_ip=$(echo ${target_hostip} | cut -d. -f1-3)
  export ROS_IP=$(PATH=$PATH:/sbin LANGUAGE=en LANG=C ifconfig | grep inet\ | sed 's/.*inet addr:\([0-9\.]*\).*/\1/' | tr ' ' '\n' | grep $mask_target_ip | head -1)
  export ROS_HOSTNAME=$ROS_IP
}

function rossetip() {
  local device=${1-"(eth0|eth1|eth2|eth3|eth4|wlan0|wlan1|wlan2|wlan3|wlan4)"}
  if [[ $device =~ [0-9]+.[0-9]+.[0-9]+.[0-9]+ ]]; then
      export ROS_IP="$device"
  else
      export ROS_IP=""
      local master_host=$(echo $ROS_MASTER_URI | cut -d\/ -f3 | cut -d\: -f1);
      if [ "${master_host}" != "localhost" ]; then rossetip_addr ${master_host} ; fi
      if [ "${ROS_IP}" == "" ]; then rossetip_addr ${device}; fi
      if [ "${ROS_IP}" == "" ]; then rossetip_dev ${device}; fi
  fi
  export ROS_HOSTNAME=$ROS_IP
  if [ "${ROS_IP}" == "" ];
  then
      export -n ROS_IP
      export -n ROS_HOSTNAME
      echo -e "\e[1;31munable to set ROS_IP and ROS_HOSTNAME\e[m"
  else
      echo -e "\e[1;31mset ROS_IP and ROS_HOSTNAME to $ROS_IP\e[m";
  fi
  # update PS1
  if [[ "${ROS_MASTER_URI}" =~ ^http://(.*):(.*)$ ]] ; then
      rossetmaster ${BASH_REMATCH[1]} ${BASH_REMATCH[2]}
  fi
}

function rosn() {
    which percol || echo -e "\e[1;31mNeed to install percol, \`sudo pip install python-percol\` or \`rosdep install jsk_tools\` \e[m";
    which percol || return 1
    if [ "$1" = "" ]; then
        topic=$(rosnode list | percol | xargs -n 1 rosnode info | percol | sed -e 's%.* \* \(/[/a-zA-Z0-9_]*\) .*%\1%')
    else
        topic=$(rosnode info $1 | percol | sed -e 's%.* \* \(/[/a-zA-Z0-9_]*\) .*%\1%')
    fi
    if [ "$topic" != "" ] ; then
        rost $topic
    fi
}
function rost() {
    which percol || echo -e "\e[1;31mNeed to install percol, \`sudo pip install python-percol\` or \`rosdep install jsk_tools\` \e[m";
    which percol || return 1
    if [ "$1" = "" ]; then
        node=$(rostopic list | percol | xargs -n 1 rostopic info | percol | sed -e 's%.* \* \(/[/a-zA-Z0-9_]*\) .*%\1%')
    else
        node=$(rostopic info $1 | percol | sed -e 's%.* \* \(/[/a-zA-Z0-9_]*\) .*%\1%')
    fi
    if [ "$node" != "" ] ; then
        rosn $node
    fi
}

