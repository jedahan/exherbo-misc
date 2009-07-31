for p in `paludis -k system | grep \/`; do 
    for o in `grep $p /var/paludis/repositories/*/packages/*/*/*ex{heres-0,libs}`; do
        #remove here?
        
        if `$o | cut -d':' -f1` -eq 
        $o
    
    ; 
done
