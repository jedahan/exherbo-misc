#! /bin/zsh

for p in `paludis -q system | grep \/`; do 
    for o in `grep $p /var/paludis/repositories/*/packages/*/*/*exheres-0`; do
        echo $o
    done
done
