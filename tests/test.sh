set -ex
. $VENV/bin/activate
make SIM=icarus
MAKE_RESULT=$(echo $?)
FAILURE_CASES=$(grep "failure" results.xml)

if [ ! -z "$FAILURE_CASES" ] || [ $MAKE_RESULT -ne 0 ]
then
    echo "Failed!\n$FAILURE_CASES"
    exit 1
else
    echo "Tests has ran successfully!"
    exit 0
fi
