#!/bin/sh
export POSIXLY_CORRECT=yes
export LC_NUMERIC=en_US.UTF-8
printMan(){
    echo "Manual zacina tady:"
}
#vyhleda a nahraje obsah souboru do $read
read=""
for var in "$@"
do
    case $var in
    -a|-b|-t|-w|list-tick|last-price|profit|pos|hist-ord|graph-pos)
    ;;
    *)
        if [ "${var##*.}" = "txt" ]||[ "${var##*.}" = "log" ]; then
            logs="$var"
            read="$read$(cat "$logs")\n"
        fi
        if [ "${var##*.}" = "gzip" ]||[ "${var##*.}" = "gz" ]; then
            glogs="$var"
            read="$read$(gzip -d -c "$glogs ")\n"
        fi
        ;;
    esac
done
#nahraje do $read stdin pouze pokud existuje
if [ ! \( -t 0 \)  ];then
read=$read$(cat)
fi
# Odstrani duplicitni radky
read=$(echo "$read" | sort -u|\
    awk '{print}'
)
outLogs=$read
tkrs=""
while [ "$#" -gt 0 ]; do  
#switch, ktery porovna argumenty a posune se na dalsi
#switch ma za dusledek, ze na konci cyklu nezbydou zadne argumenty  
    case "$1" in
        -h|--help)
            printMan
            exit 0
            ;;
    #########################
    #         FILTRY        #
    #########################
        -a)
            afterDt=$(echo "$outLogs"|\
                awk -F ';' \
                -v userDt="$2"\
                '{
                    tickerDt=$1
                    if(userDt<tickerDt){
                    print 
                    }
                }')   
                outLogs=$afterDt  
                shift;shift 
                ;; 
        -b)
        beforeDt=$(echo "$outLogs"|\
                awk -F ';' \
                -v userDt="$2"\
                '{
                    logDt=$1
                    if(userDt>logDt){
                    print 
                    }
                }')   
                outLogs=$beforeDt   
                shift;shift  
                ;; 
        -t)   
        #while cyklus aby dokazal zpracovat vic nez jeden parametr
            while [ "$1" = "-t" ];do
                tkrs="$tkrs $2"
                shift;shift
                done
                tkr="$(echo "$outLogs"|\
                awk -F ';' \
                -v userTkr="$tkrs"\
                '{
                    logTkr=$2
                    if(userTkr ~ logTkr){
                    print 
                    }
                }')"  
            outLogs=$tkr
            ;;   
        -w) 
            #TODO
            shift
            ;;
    #########################
    #       PRIKAZY         #
    #########################
        list-tick)
                listTick=$(echo "$outLogs" | \
                awk -F ';' '{
                    if(a[$2]++ == 0){
                    print $2;}
                    }')
                    listTick=$(echo "$listTick" |sort -t " " -b -d -f| \
                    awk -F ' ' '{
                        print $1
                    }')
                outLogs=$listTick 
                shift
                ;;
            profit)
                profit=$(echo "$outLogs"|\
                awk -F ';' \
                'BEGIN{
                    sellTr=0
                    buyTr=0
                }
                { 
                    if($3=="sell"){
                        sellTr=sellTr+($4*$6)
                    }
                    if($3=="buy"){
                        buyTr=buyTr+($4*$6)
                    }                   
                } END {
                    profit=sellTr-buyTr
                    printf("%.2f\n",profit) 
                }')
                outLogs=$profit
                shift
                ;;
            pos)
                pos=$(echo "$outLogs"|sort -t ";" -r -d|\
                awk -F ';' \
                '{
                    if(a[$2]++ == 0 ){
                        lastPrice[$2]+=$4
                    }
                    if($3=="buy"){
                        obj[$2]+=$6
                    }
                    else{
                        obj[$2]-=$6
                    }
                }
                END{
                    maxLen=0
                    for(tkr in obj){
                        val=lastPrice[tkr]*obj[tkr]
                        val=sprintf("%.2f",val)
                        if(maxLen<length(val)){
                            maxLen=length(val) 
                        }
                    }
                    for (tkr in obj){
                        addSpaceT=""
                        for (i=length(tkr);i<12;i++){
                            addSpaceT=addSpaceT" "
                        }
                        val=lastPrice[tkr]*obj[tkr]
                        val=sprintf("%.2f",val)
                        aSN=""
                        for(i=length(val);i<maxLen;i++){
                            aSN=aSN" "
                        }
                        printf("%s%s: %s%.2f\n",tkr,addSpaceT,aSN,val)
                    }
                }'|sort -t ":" -n -k2 -r)
                outLogs="$pos"
                shift
                ;;
            last-price)
            #temer copy posu, protoze je to v podstate to same, s jinym sortem a bez nasobeni objemem
                lastPrice=$(echo "$outLogs" | sort -t ";" -r -d|\
                awk -F ';' '{
                    if(a[$2]++ == 0 ){
                        lastPrice[$2]+=$4
                    }
                }
                END{
                    maxLen=0
                    for(tkr in lastPrice){
                        val=lastPrice[tkr]
                        val=sprintf("%.2f",val)
                        if(maxLen<length(val)){
                            maxLen=length(val) 
                        }
                    }
                    for (tkr in lastPrice){
                        addSpaceT=""
                        for (i=length(tkr);i<12;i++){
                            addSpaceT=addSpaceT" "
                        }
                        val=lastPrice[tkr]
                        val=sprintf("%.2f",val)
                        aSN=""
                        for(i=length(val);i<maxLen;i++){
                            aSN=aSN" "
                        }
                        printf("%s%s: %s%.2f\n",tkr,addSpaceT,aSN,val)
                    }
                }'|sort -t ":" -k1 -d )
                outLogs=$lastPrice  
                shift
                ;;
            hist-ord)
                #TODO
                shift
                ;;
            graph-pos)
                #TODO
                shift
                ;;
            *)     
                print  
                shift
                ;;          
    esac
done
###################
#     FINISH      #
###################
echo "$outLogs"






