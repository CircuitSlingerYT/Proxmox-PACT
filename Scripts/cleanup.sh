source ./workingdir/Options.ini

qm destroy $((nVMID + 1))
qm destroy $((nVMID + 2))
qm destroy $((nVMID + 3))
qm destroy $((nVMID + 11))
qm destroy $((nVMID + 12))
qm destroy $((nVMID + 21))
qm destroy $((nVMID + 22))
qm destroy $((nVMID + 31))

rm -r ./workingdir
