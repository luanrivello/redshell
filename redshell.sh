#!/bin/bash

bstart=9
bcurrent=$(($bstart - 1))
bend=2
btransitions=$(($bcurrent - $bend))
echo bcurrent: $bcurrent
echo btransitions: $btransitions

redstart=1:1:1
redend=1:0.54:0.42
redcurrent=$redend

starttime="18:00"
endtime="06:00"
standardset=0

transition=$(date +%H:%M -d "$starttime today -$btransitions"hours)
echo transition: $transition
echo ==========

_adjust() {
    for i in $(xrandr -q | grep ' connected' | grep -oP '^.*? ')
    do
        xrandr --output $i \
            --brightness 0.$1 \
            --gamma $2
    done
}

while true
do
    currenttime=$(date +%H:%M)
    echo currenttime: $currenttime

    if [[ "$currenttime" > "$transition" ]] || [[ "$currenttime" < "$endtime" ]] \
    && [[ "$bcurrent" > "$bend" ]];
    then
        echo -----
        echo *for*

        if [[ "$currenttime" > "$starttime" ]];
        then
            bcurrent=$bend
            standardset=0
            echo reached
            echo "$currenttime c $starttime"
            echo "$bcurrent <-> $redstart"
            echo ----
            _adjust "$bcurrent" "$redend"
        else
            for i in $(seq 1 $btransitions);
            do
                transition=$(date +%H:%M -d "$starttime today -$i"hours)
                echo "$currenttime c $transition"
                aux=$(($bend + $i))

                if [[ "$bcurrent" == "$aux" ]];
                then
                    echo break
                    break
                fi

                if [[ "$currenttime" > "$transition" ]];
                then
                    bcurrent=$aux
                    echo "$bcurrent <-> $redstart"
                    echo ----
                    _adjust "$bcurrent" "$redstart"
                    break
                fi
            done
        fi


    elif [[ "$standardset" == 0 ]] && [[ "$currenttime" < "$endtime" ]];
    then
        standardset=1
        echo standardset
        _adjust "$bstart" "$redstart"
    fi

    echo waiting
    sleep 60

done

#/* cribbed from redshift, but truncated with 500K steps */
#static const struct { float r; float g; float b; } whitepoints[] = {
#    { 1.00000000,  0.18172716,  0.00000000, }, /* 1000K */
#    { 1.00000000,  0.42322816,  0.00000000, },
#    { 1.00000000,  0.54360078,  0.08679949, },
#    { 1.00000000,  0.64373109,  0.28819679, },
#    { 1.00000000,  0.71976951,  0.42860152, },
#    { 1.00000000,  0.77987699,  0.54642268, },
#    { 1.00000000,  0.82854786,  0.64816570, },
#    { 1.00000000,  0.86860704,  0.73688797, },
#    { 1.00000000,  0.90198230,  0.81465502, },
#    { 1.00000000,  0.93853986,  0.88130458, },
#    { 1.00000000,  0.97107439,  0.94305985, },
#    { 1.00000000,  1.00000000,  1.00000000, }, /* 6500K */
#    { 0.95160805,  0.96983355,  1.00000000, },
#    { 0.91194747,  0.94470005,  1.00000000, },
#    { 0.87906581,  0.92357340,  1.00000000, },
#    { 0.85139976,  0.90559011,  1.00000000, },
#    { 0.82782969,  0.89011714,  1.00000000, },
#    { 0.80753191,  0.87667891,  1.00000000, },
#    { 0.78988728,  0.86491137,  1.00000000, }, /* 10000K */
#    { 0.77442176,  0.85453121,  1.00000000, },
#};
