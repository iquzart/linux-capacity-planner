#!/bin/bash
#########################################################################################################################
# Purpose       :- Generate Monthly Capacity Report Email from Linux nodes (systat)
# Author        :- Muhammed Iqbal
# Created       :- 13-May-2019
# Updated       :- 16-may-2019
# Version       :- 0.1
# License       :- MIT   
# Notes         :-                                                                                                    
##########################################################################################################################


##########################################################################################################################
# Total Processing Capacity = Processing capacity, rated on processor * No. Of Physical Socket * No. of Cores per socket 
# For example :-                                                                                                         
# If we have 2 physical processor of 2.599GHz capacity and each processor has 6 Cores then as per formula,               
# Total Processing Capacity = [2.599 (Processor rating)*2(physical processor)*6(cores per processor) ]GHz = 31.188GHz    
##########################################################################################################################

# Email Variables
TEMPLATE='Email.html'
email_desc="Linux Nodes Compute & Storage Utilization Report:"
email_sub="Monthly Capacity - "
date=`date +%m-%d-%Y`
email_recipient=""

# CPU Variables
CPU_Mhz=$(lscpu | grep "Model name:" | awk '{print $9}' | cut -b -4)
CPU_Sockets=$(lscpu  | grep "Socket(s):"  |awk '{ print $2}')
CPU_Core=$(lscpu  | grep "Core(s) per socket"  |awk '{ print $4}')
total_cpu=`echo $CPU_Mhz*$CPU_Sockets*$CPU_Core | bc`


# Memory Variables
total_mem=`awk '/MemTotal/ {print $2/1024^2}' /proc/meminfo`




main ()
{
        # Calculate Average CPU utilization from systat logs
        for file in `ls -tr /var/log/sa/* | grep -v sar`
        do
            sa_cpu+=($(sar -u -f $file | grep Average: | awk -F " " '{sum = (100 - $8) } END { print sum}'))
        done
        AverageCPU=( $( printf "%s\n" "${sa_cpu[@]}" | sort -r )) #| awk -F " " '{sum = (100 - $1) } END { print sum }'

        # Calculate Average Memory utilization from systat logs
        for file in `ls -tr /var/log/sa/* | grep -v sar`
        do
            sa_mem+=($(sar -r -f $file | grep Average | awk -F " " '{ sum = ($3-$5-$6)/($2+$3) * 100   } END { print sum }'))
        done
        AverageMem=( $( printf "%s\n" "${sa_mem[@]}" | sort -r ))
        capacity_calc
}

capacity_calc()
{
        # Calculation for Capacity Report 
        # Percentage of total CPU and Memory utilization
        cpu=`echo "$AverageCPU*$total_cpu/100" |bc`
        memory=`echo "$AverageMem*64/100" |bc`
        values
}

values ()
{
        # This section can be used for debugging
        #echo "Total Installed CPU"
        #echo $total_cpu Ghz
        #echo "Total Installed Memory"
        #echo $total_mem GB

        #echo "Avarage CPU Utilization"
        #echo $AverageCPU
        #echo "Avarage Memory Utilization"
        #echo $AverageMem

        #echo "Capacity Report CPU - $HOSTNAME"
        #echo $cpu
        #echo "Capacity Report Memory - $HOSTNAME"
        #echo $memory
	
        # Replace values on Email template. 
	while read LINE; do
	  echo $LINE |
	  sed "s/hostname/$HOSTNAME/g" |
	  sed 's/dear/Admin/g' |
          sed "s/email_description/$email_desc/g" |
	  sed "s/total_cpu/$total_cpu/g" | 
          sed "s/total_mem/$total_mem/g" |
          sed "s/AverageCPU/$AverageCPU/g" |
          sed "s/AverageMem/$AverageMem/g" |
          sed "s/cpu/$cpu/g" |
          sed "s/memory/$memory/g" 
	done < $TEMPLATE | mutt -e 'set content_type=text/html' -s "$email_sub $date" $email_recipient


}
main $*

