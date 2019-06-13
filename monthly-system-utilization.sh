!/bin/bash


##########################################################################################################################
# Total Processing Capacity = Processing capacity, rated on processor * No. Of Physical Socket * No. of Cores per socket #
# For example :-                                                                                                         #
# If we have 2 physical processor of 2.599GHz capacity and each processor has 6 Cores then as per formula,               #
# Total Processing Capacity = [2.599 (Processor rating)*2(physical processor)*6(cores per processor) ]GHz = 31.188GHz    #
##########################################################################################################################




# Installed CPU Capacity
CPU_Mhz=$(lscpu  | grep "CPU MHz:" |awk '{ print $3}')
CPU_Sockets=$(lscpu  | grep "Socket(s):"  |awk '{ print $2}')
CPU_Core=$(lscpu  | grep "Core(s) per socket"  |awk '{ print $4}')

echo $CPU_Mhz
echo $CPU_Sockets
echo $CPU_Core
echo "Total CPU Capasity"
total_cpu=`echo $CPU_Mhz*$CPU_Sockets*$CPU_Core/1000 | bc`
echo $total_cpu
#===================================================

# Installed Memory Capacity
echo "Total Memory"
total_mem=`awk '/MemTotal/ {print $2/1024^2}' /proc/meminfo`
echo $total_mem
#===================================================

echo "Avarage CPU Utilization"

for file in `ls -tr /var/log/sa/* | grep -v sar`
do
    sa_cpu+=($(sar -u -f $file | grep Average: | awk -F " " '{sum = (100 - $8) } END { print sum}'))
done
AvarageCPU=( $( printf "%s\n" "${sa_cpu[@]}" | sort -r )) #| awk -F " " '{sum = (100 - $1) } END { print sum }'
echo $AvarageCPU


echo "Avarage Memory Utilization"
for file in `ls -tr /var/log/sa/* | grep -v sar`
do
    sa_mem+=($(sar -r -f $file | grep Average | awk -F " " '{ sum = ($3-$5-$6)/($2+$3) * 100   } END { print sum }'))
done
AvarageMem=( $( printf "%s\n" "${sa_mem[@]}" | sort -r ))
echo $AvarageMem


echo "Meraas Capacity Report CPU - $HOSTNAME"
echo "$AvarageCPU*$total_cpu/100" |bc

echo "Memory Capacity Report Memory - $HOSTNAME"
echo "$AvarageMem*64/100" |bc

