#!/bin/env bash
installed=`paludis --list-packages --repository installed | grep -c "*"`
available=`cave print-packages | grep -v user/ | grep -v group/ | wc -l`
echo "  Installed:  $installed"
echo "  Available: $available"
