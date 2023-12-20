#!/bin/bash

IP_ADDRESS="127.0.0.1"

#Function to start application
start_application(){
	./APM1 $IP_ADDRESS &
	./APM2 $IP_ADDRESS & 
	./APM3 $IP_ADDRESS & 
	./APM4 $IP_ADDRESS & 
	./APM5 $IP_ADDRESS & 
	./APM6 $IP_ADDRESS &
}

#Function to collect process level metrics
collect_process_metrics() {
	for app in APM1 APM2 APM3 APM4 APM5 APM6; do
		cpu=$(ps aux| grep $app| xargs| cut -f 3 -d ' ')
		mem=$(ps aux| grep $app| xargs| cut -f 4 -d ' ')
		echo "$SECONDS,$cpu,$mem" >> "${app}_metrics.csv"
	done
}

# Function to collect system-level metrics
collect_system_metrics() {
    rx_data_rate=$( ifstat ens33 1 1 2>/dev/null | sed -n '4p' | xargs | cut -f 7 -d ' ' | sed s/K//g )
    tx_data_rate=$( ifstat ens33 1 1 2>/dev/null | sed -n '4p' | xargs | cut -f 9 -d ' ' | sed s/K//g )
    disk_writes=$(iostat | grep sda | awk '{print $4}')
    disk_capacity=$(df -m / | awk 'NR==2{print $4}')
    echo "$SECONDS,$rx_data_rate,$tx_data_rate,$disk_writes,$disk_capacity" >> "system_metrics.csv"
}

# Function to clean up processes
cleanup(){
  pkill ifstat
  for((i=1; $i <= 6; i++)) 
  do
    psname="APM${i}" 
    id=$(pidof $psname) 
    kill -9 $id
    wait $id 2>/dev/null  # this allows for silent kill
  done 
  echo # new line after CTRL-C
  echo "Check output in <ps_name>_metrics.csv and system_metrics.csv files"
}


# Trap function for cleanup on exit
trap cleanup EXIT

# Main function
main() {
    start_application $1

    duration=900  # 15 minutes
    end_time=$((SECONDS + duration))

    while [ $SECONDS -lt $end_time ]; do
	sleep 5
        collect_process_metrics
        collect_system_metrics
    done
}

# Run the main function with the specified NIC IP address
main "127.0.0.1"
