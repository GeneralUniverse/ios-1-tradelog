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
                tkr=$(echo "$outLogs"|\
                awk -F ';' \
                -v userTkr="$2"\
                '{
                    logTkr=$2
                    if(userTkr==logTkr){
                    print 
                    }
                }')   
                shift;shift 
                outLogs=$tkr    
                ;; 
        -w)
            $width=$2   
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
                    if (profit>=0){
                    printf("Celkový zisk je: %i $\n",profit) 
                    }
                    else{
                        printf("Celková ztráta je: %i $\n",profit) 
                    }
                }')
                outLogs=$profit
                shift
                ;;
            pos)
                pos=$(echo "$outLogs"|sort -t ";" -bdfk2|\
                awk -F ';' \
                'BEGIN{
                    prev=""
                    buyTr=0
                    sellTr=0
                }
                {    
                    if($3=="sell"){
                        sellTr=sellTr+$6
                    }
                    else{
                        buyTr=buyTr+$6
                        }
                    
                    if($2!=prev&&NR!=1){
                        objem=buyTr-sellTr      
                        printf("%s -  %i\n",prev,$4*objem)
                        sellTr=0
                        buyTr=0 
                        } 
                    prev=$2
                    
                }')
                #|sort -t ";" -nk4 -r)
                
                outLogs="$pos"
                shift
                ;;
            last-price)
                lastPrice=$(echo "$outLogs" | sort -t ";" -r -d|\
                awk -F ';' '{
                    if(a[$2]++ == 0){
                    print $2" - "$4;}
                    }'|sort -t ";" -b -d -f)
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
echo "$outLogs"




