#!/bin/bash

#TO DO check if h1 > h2 or h2 < h1 for yesterday and today set
h1="18:00"
h2="06:00"

bstart=0.9
bend=0.2
#bcurrent=0"$(echo "scale=2;$bstart -0.01" | bc)"
bcurrent=$bstart
btransitions="$(echo "scale=0;($bcurrent -$bend)*100/1" | bc)"
echo $bcurrent

#0 - custom
#1 - 1000K #2 - 1500K #3 - 2000K
#4 - 2500K #5 - 3000K #6 - 3500K
#7 - 4000K #8 - 4500K #9 - 5000K
#10- 5500K #11- 6000K #12- 6500K
temps=("1:0.54:0.42" \
       "1.00000000:0.18172716:0.00000001" \
       "1.00000000:0.42322816:0.00000001" \
       "1.00000000:0.54360078:0.08679949" \
       "1.00000000:0.64373109:0.28819679" \
       "1.00000000:0.71976951:0.42860152" \
       "1.00000000:0.77987699:0.54642268" \
       "1.00000000:0.82854786:0.64816570" \
       "1.00000000:0.86860704:0.73688797" \
       "1.00000000:0.90198230:0.81465502" \
       "1.00000000:0.93853986:0.88130458" \
       "1.00000000:0.97107439:0.94305985" \
       "1.00000000:1.00000000:1.00000000" \
      )

echo "Temperatures:"
for i in $(seq 0 12);
do
    echo $i: ${temps[$i]}
done

redstart=1:1:1
redend=${temps[7]}
redcurrent=$redend

dateformat='+%G-%m-%d %H:%M'
starttime=$(date "$dateformat" -d "$h1 yesterday")
#endtime=$(date "$dateformat" -d "12:00 today")
endtime=$(date "$dateformat" -d "$h2 today")
standardset=0

smooth=3

transition=$(date "$dateformat" -d "$starttime today -$(($btransitions*$smooth))minutes")

_adjust() {
    for i in $(xrandr -q | grep ' connected' | grep -oP '^.*? ')
    do
        xrandr --output $i \
            --brightness $1 \
            --gamma $2
    done
}

echo ==================================================
echo transition: $transition + $btransitions t
echo time:'       '$starttime - $endtime
echo ==================================================

while true
do
    currenttime=$(date "$dateformat")

    if [[ "$bcurrent" == "$bend" ]];
    then
        echo breached
    fi

    if [[ "$currenttime" > "$transition" ]];
    then
        echo $currenttime grt $transition
    fi

    if [[ "$currenttime" < "$endtime" ]];
    then
        echo $currenttime dcr $endtime
    fi

    if [[ "$standardset" == 0 ]];
    then
        echo standard: $standardset
    fi

    echo \\/

    if [[ "$bcurrent" > "$bend" ]] \
    && [[ "$currenttime" > "$transition" ]] && [[ "$currenttime" < "$endtime" ]];
    then
        echo '<<<for 1if>>>'

        if [[ "$currenttime" > "$starttime" ]];
        then
            bcurrent=$bend
            standardset=0
            echo **reached**
            echo "$bcurrent <-> $redend"
            _adjust "$bcurrent" "$redend"

            waitingtime=$(($(date +%s -d "$endtime") - $(date +%s -d "$starttime")))
            echo waiting $(($waitingtime/60)) minutes...
            sleep $waitingtime
        else
            aux=$bend
            for i in $(seq 1 $btransitions);
            do
                transition=$(date "$dateformat" -d "$starttime today -$(($i*$smooth)) minutes")
                aux="$(echo "scale=2;$aux+0.01" | bc)"

                if [[ "$bcurrent" == "$aux" ]];
                then
                    echo already set - break
                    break
                fi

                echo "$currenttime grt $transition"
                if [[ "$currenttime" > "$transition" ]];
                then
                    bcurrent=$aux

                    echo "$bcurrent <-> $redstart"

                    _adjust "$bcurrent" "$redstart"

                    break
                fi
            done

            echo waiting 6 minutes...
            sleep 360

        fi

    elif [[ "$standardset" == 0 ]] \
      && [[ "$currenttime" > "$endtime" ]] \
      || [[ "$currenttime" < "$transition" ]];
    then
        standardset=1
        echo standardset

        if [[ "$currenttime" > "$endtime" ]];
        then
            bcurrent=$bstart
            starttime=$(date "$dateformat" -d "$starttime tomorrow")
            endtime=$(date "$dateformat" -d "$endtime tomorrow")
            transition=$(date "$dateformat" -d "$starttime today -$(($btransitions*$smooth))minutes")
            echo !times updated!
        fi

        _adjust "$bstart" "$redstart"

        waitingtime=$(($(date +%s -d "$transition") - $(date +%s -d "$currenttime")))

        if [[ $waitingtime > 0 ]];
        then
            echo waiting $(($waitingtime/60)) minutes...
            sleep $waitingtime
        fi


    else
        sleep 360
    fi

    echo ==================================================
    echo currenttime:$currenttime
    echo transition: $transition + $btransitions t
    echo time:'       '$starttime - $endtime
    echo ==================================================
done

