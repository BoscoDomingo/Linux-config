#!/bin/bash

# A crude way to display some system resources. There's plenty of plugins out there
# that can do this much better, such as with dynamic colouring

while true; do
	CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{printf "%.2f%", 100 - $1}')
	MEM_TOTAL=$(free -m | awk 'NR==2{printf "%.2f", $2/1024}')
	MEM_USED=$(free -m | awk 'NR==2{printf "%.2f", $3/1024}')
	DATE_TIME=$(date +"%Y-%m-%d %H:%M:%S")

	# Long version (With date)
	# echo "CPU: #[fg=cyan]$CPU_USAGE#[default] | RAM: #[fg=yellow]${MEM_USED}/${MEM_TOTAL}GiB#[default] | #[fg=white]$DATE_TIME#[default]" >~/.tmux-status
	# Short version (Without date)
	echo "CPU: #[fg=cyan]$CPU_USAGE#[default] | RAM: #[fg=yellow]${MEM_USED}/${MEM_TOTAL}GiB#[default]" >~/.tmux-status

	sleep 1
done
