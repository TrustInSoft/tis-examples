#!/bin/bash
set -euo pipefail

BOLD=`tput bold`
CYAN=`tput setaf 6`
GREEN=`tput setaf 2`
RED=`tput setaf 1`
YELLOW=`tput setaf 3`
RESET=`tput sgr0`
UNDERLINE=`tput sgr 0 1`
MAGENTA=`tput setaf 5`

SLEEP_TIME=1

MSG="Press [Enter] to proceed: "
H1="================================================================================"
H2="--------------------------------------------------------------------------------"

steps=true

#------------------------------------------------------------------------------
clear
cat << EOF

${CYAN}$H1
           THE ${YELLOW}increment_array()${CYAN} UNDEFINED BEHAVIOR EXAMPLE
$H1

${GREEN}$H2
In this example we'll show how Undefined Behaviors are quite subtle,
may be visible or not in different execution conditions, and how it can be
extremely difficult to detect them with traditional tests
$H2${RESET}
EOF


[ "$steps" = "true" ] && read -p "$MSG" c
#------------------------------------------------------------------------------
clear
cat << EOF
${GREEN}$H2
Here's a simple function that increments all cells of an array of integers.
We'll see that this function has an undefined behavior (UB) and, because of
that, a program using this function can behave differently depending on the
context, and the UB can be more or less noticeable depending on cases
$H2${RESET}
EOF

cat increment.c

[ "$steps" = "true" ] && read -p "$MSG" c

cat << EOF
${GREEN}$H2
This function is tested with the below test driver.
Note the presence of variable ${YELLOW}name${GREEN} that will play a role
$H2${RESET}
EOF

tac test_driver.c | sed -e '/int main()/q' | tac

[ "$steps" = "true" ] && read -p "$MSG" c

#------------------------------------------------------------------------------
clear
cat << EOF
${GREEN}$H2
Let's compile the program (with gcc) and run a test of it
${RESET}
EOF

sleep $SLEEP_TIME
make ut

cat << EOF
${GREEN}As you can see the array is well incremented for all its cells
${RESET}
EOF

[ "$steps" = "true" ] && read -p "$MSG" c

#------------------------------------------------------------------------------
clear
cat << EOF
${GREEN}$H2
Now let's compile with a bit more information printed on stdout during the test
${RESET}
EOF

sleep $SLEEP_TIME
make ut-debug

cat << EOF
${GREEN}If you carefully look, you'll notice that the compiler stored the ${YELLOW}name${GREEN} variable
in memory just after the ${YELLOW}array${GREEN} variable (16 bytes further, just the size of ${YELLOW}array${GREEN}).
...and when we display the ${YELLOW}name${GREEN} variable before and after calling ${YELLOW}increment_array()${GREEN} we can see
that this variable is affected (It was "${RED}O${GREEN}livier" before the call, and becomes "${RED}P${GREEN}livier"
after the call) even though it is not used for the call to ${YELLOW}increment_array()${GREEN}

The reason for that is the buffer overflow in ${YELLOW}increment_array()${GREEN} that increments past the end
of the array and overwrites the memory location that happens to be the location of ${YELLOW}name${GREEN}
${RESET}
EOF

[ "$steps" = "true" ] && read -p "$MSG" c

#------------------------------------------------------------------------------
clear
cat << EOF
${GREEN}$H2
Now let's run the same code and test, but compiled with clang instead of gcc
${RESET}
EOF

sleep $SLEEP_TIME
make ut-clang

cat << EOF
${GREEN}clang decides for another way of storing the ${YELLOW}data${GREEN} and ${YELLOW}name${GREEN} variables in memory.
If you look at the addresses, ${YELLOW}data${GREEN} is after ${YELLOW}name${GREEN}, not before

In this context the UB remains completely invisible (${YELLOW}name${GREEN} is not modified), even if the
tester has the idea to verify the variable name, because the memory overwritten by the
${YELLOW}increment_array()${GREEN} buffer overflow is not overlapping with ${YELLOW}name${GREEN}.
The UB problem is nevertheless still present.
${RESET}
EOF

[ "$steps" = "true" ] && read -p "$MSG" c

#------------------------------------------------------------------------------
clear
cat << EOF
${GREEN}$H2
Another example of the non-deterministic behavior of the code due to the UB.

Let's compile again with gcc (just like in the 2nd run), but change the value of variable ${YELLOW}name${GREEN}
from "Olivier" to "TrustInSoft". And run the test again. We could expect the name to be
changed into "${RED}U${GREEN}rustInSoft" because of the buffer overflow. Let's see...
${RESET}
EOF

sleep $SLEEP_TIME
make ut-long-name

cat << EOF
${GREEN}"Que nenni!" as we'd say in old French: For some reason, because the ${YELLOW}name${GREEN}
string size has changed, gcc now decided to implant ${YELLOW}name${GREEN} further past ${YELLOW}data${GREEN} in memory
(precisely 28 bytes). So the array buffer overflow does not overwrites ${YELLOW}name${GREEN}...
(but again: The UB is still well present and is a potential time bomb) 

It's important to be clear that the UB is NOT there because ${YELLOW}name${GREEN} is overwritten, but because
any memory location is overwritten. The UB is present in all tests scenarii above,
just that in some conditions it overwrites the memory location of ${YELLOW}name${GREEN},
and in others another memory location (which is very likely used for some other data so
that's just as bad).
${RESET}
EOF

make clean

[ "$steps" = "true" ] && read -p "$MSG" c

if [ $(which tis-analyzer) ]; then
    #------------------------------------------------------------------------------
    clear
    cat << EOF
${GREEN}$H2
Let's now analyze the same code with the TrustInSoft Analyzer (TISA).
${RESET}
EOF

    make tis

    cat << EOF

${GREEN}As you can see from the warning 
${RESET}increment.c:10:${MAGENTA}[kernel] warning:${RESET} out of bounds write. assert \valid(p);
${GREEN}above, the UB is detected.${RESET}
EOF
fi

cat << EOF

${GREEN}$H2
With the TrustInSoft Analyzer the analysis/test result is deterministic, not context dependent.
There is a UB and it will always be detected and reported whatever the environment.
${RED}$H1
        That's how you can get mathematical guarantee of
        absence of Undefined Behaviors with TrustInSoft !
$H1
${RESET}
EOF
