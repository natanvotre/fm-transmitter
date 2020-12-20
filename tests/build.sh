SRC_PATH="$(pwd)/src"
VERILOG_FILES=$(find $SRC_PATH -name "*.v")
TOPLEVEL="max10"

HAS_ERROR=0
iverilog -s $TOPLEVEL $VERILOG_FILES
RESULT=$(echo $?)
if [ $RESULT -eq 0 ]
then
  echo "$(echo "$VERILOG_FILES" | wc -l)\e[90m Files \e[92mCompiled\e[39m!"
else
  HAS_ERROR=1
fi

exit $HAS_ERROR
