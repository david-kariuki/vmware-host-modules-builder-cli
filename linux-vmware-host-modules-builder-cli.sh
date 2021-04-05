# Copyright (c) 2020 by David Kariuki (dk). All Rights Reserved.

# This script uses two methods to retrieve the VMWARE module source build modules and
# install them.

#!/bin/bash

$1="" # Empty any parameter passed by user during script exercution
declare -r targetLinux="Debian Linux"
declare -r scriptVersion="2.0" # Stores scripts version
declare -l -r scriptName="linux-vmware-host-modules-builder-cli" # Set to lowers and read-only
declare -l -r networkTestUrl="www.google.com" # Set to lowers and read-only
declare -r versionNoSequence='^[0-9.]+$'
declare -l startTime="" # Stores start time of execution
declare -l totalExecutionTime="" # Total execution time in days:hours:minutes:seconds
declare -r buildFromSourceAndInstall="buildFromSourceAndInstall"
declare -r replaceOriginalTarballs="replaceOriginalTarballs"
declare targetVmwareVersion="" # Target vmware version
declare -i runningBothOptions=0
declare -i ranAnyMethod=0

clear=clear # Command to clear terminal
${clear} # Clear terminal

# Function to create a custom coloured print
function cPrint(){
    RED="\033[0;31m"    # 31 - red    : "\e[1;31m$1\e[0m"
    GREEN="\033[0;32m"  # 32 - green  : "\e[1;32m$1\e[0m"
    YELLOW="\033[1;33m" # 33 - yellow : "\e[1;33m$1\e[0m"
    BLUE="\033[1;34m"   # 34 - blue   : "\e[1;34m$1\e[0m"
    PURPLE="\033[1;35m" # 35 - purple : "\e[1;35m$1\e[0m"
    NC="\033[0m"        # No Color    : "\e[0m$1\e[0m"
    # Display coloured text setting its background color to black
    printf "\e[48;5;0m${!1}\n ${2} ${NC}\n" || exit
}

# Function to space out different sections
function sectionBreak(){
    cPrint "NC" "\n" # Print without color
}

# Function to show connection established message
function connEstMessage(){
    cPrint "GREEN" "Internet connection established.\n"
    holdTerminal 2 # Hold
}

# Function to show connection failed message
function connFailedMessage(){
    cPrint "RED" "Internet connection failed!!!"
    holdTerminal 2 # Hold
}

# Function to show script information
function showScriptInfo(){
    ${clear} # Clear terminal
    cPrint "NC" "About\n   Script       : $scriptName.\n   Target Linux : $targetLinux.\n   Version      : $scriptVersion\n   License      : MIT Licence.\n   Developer    : David Kariuki (dk)\n"
    cPrint "PURPLE" "Downloaded Vmware host modules from https://github.com/mkubecek/vmware-host-modules\n."
}

# Function to hold terminal with simple terminal animation
function holdTerminal(){
    local -r initialTime=`date +%s` # Get start time
    local -r characters=" //--\\|| "
    while :
    do
        local currentTime=`date +%s`
        for (( i=0; i<${#characters}; i++ ))
        do
            sleep .1
            echo -en "  ${characters:$i:1}" "\r"
        done
        difference=$((currentTime-initialTime))
        if [[ "$difference" -eq $1 ]]
        then
            break
        fi
    done
}

# Function to format time from seconds to days:hours:minutes:seconds
function formatTime() {
    local inputSeconds=$1 local minutes=0 hour=0 day=0
    if((inputSeconds>59))
    then
        ((seconds=inputSeconds%60))
        ((inputSeconds=inputSeconds/60))
        if((inputSeconds>59))
        then
            ((minutes=inputSeconds%60))
            ((inputSeconds=inputSeconds/60))
            if((inputSeconds>23))
            then
                ((hour=inputSeconds%24))
                ((day=inputSeconds/24))
            else ((hour=inputSeconds))
            fi
        else ((minutes=inputSeconds))
        fi
    else ((seconds=inputSeconds))
    fi
    unset totalExecutionTime
    totalExecutionTime="${totalExecutionTime}$day"
    totalExecutionTime="${totalExecutionTime}d "
    totalExecutionTime="${totalExecutionTime}$hour"
    totalExecutionTime="${totalExecutionTime}h "
    totalExecutionTime="${totalExecutionTime}$minutes"
    totalExecutionTime="${totalExecutionTime}m "
    totalExecutionTime="${totalExecutionTime}$seconds"
    totalExecutionTime="${totalExecutionTime}s "
}

# Function to initiate logfile
function createWorkingDirectory(){
    cd ~ || exit # Change directory to users' home directory
    rm -r vmwareFix > /dev/null # Delete vmwareFix folder
    $(mkdir vmwareFix) > /dev/null # Create vmwareFix folder
    cd vmwareFix > /dev/null # Change directory to vmwareFix folder
}

# Function to check if user is running as root
function isUserRoot(){
    declare -l -r user=$USER # Declare user variable as lowercase
    if [ "$user" != 'root' ]
    then
        cPrint "RED" "This script works fully when run as root.\n Please run it as root to avoid issues/errors.\n"
        holdTerminal 1 # Hold for user to read
        exitScript --end
    else
        return $(true)
    fi
}

# Function to check for internet connection and validate security on connection
function isConnected(){
    # Creating integer variable
    local -i count=0 # Declare loop count variable
    local -i -r retrNum=4 # Declare and set number of retries to read-only
    local -i -r maxRetr=$[retrNum + 1] # Declare and set max retry to read-only
    local -i -r countDownTime=30 # Declare and set retry to read-only

    while :
    do # Starting infinite loop
        ${clear} # Clear terminal

        cPrint "YELLOW" "Checking for internet connection!!"
        if `nc -zw1 $networkTestUrl 443` && echo |openssl s_client -connect $networkTestUrl:443 2>&1 |awk '
        handshake && $1 == "Verification" { if ($2=="OK") exit; exit 1 }
        $1 $2 == "SSLhandshake" { handshake = 1 }' &> /dev/null
        then # Internet connection established
            connEstMessage # Display internet connection established message
            return $(true) # Exit loop returning true
        else # Internet connection failed
            connFailedMessage # Display internet connection failed message

            if [ "$count" == 0 ]
            then
                cPrint "YELLOW" "Attemting re-connection...\n Max number of retries : \e[0m$maxRetr\e[0m\n"
            fi
            # Check for max number of retries
            if [ "$count" -gt "$retrNum" ]
            then
                cPrint "YELLOW" "Number of retries: $count" # Display number of retries
                return $(false) # Exit loop returning false
            else
                count=$[count + 1] # Increment loop counter variable

                # Run countdown
                date1=$((`date +%s` + $countDownTime))
                while [ "$date1" -ge "$(date +%s)" ]
                do
                    echo -ne " \e[1;32mRetrying connection after :\e[0m \e[1;33m$(date -u --date @$(($date1 - `date +%s`)) +%H:%M:%S)\r\e[0m"
                    sleep 0.1
                done
            fi
        fi
        sleep 1 # Hold loop
    done
}

# Function to fix any unmet dependencies and broken installs incase of network interruption
function checkDebugAndRollback(){

    ${clear} # Clear terminal

    if [ "$1" == '--debug' ]
    then # Check for debug switch
        cPrint "GREEN" "Checking for errors and debugging. Please wait..."
    elif [ "$1" == '--network' ]
    then # Check for network switch
        cPrint "GREEN" "Debugging and rolling back some changes due to network interrupt. Please wait..."
    fi

    holdTerminal 1 # Hold for user to read

    cPrint "YELLOW"  "Checking for broken/unmet dependencies and fixing broken installs."
    holdTerminal 1 # Hold for user to read
    apt-get check
    apt-get --fix-broken install
    dpkg --configure -a
    sectionBreak

    cPrint "YELLOW" "Cleaning apt-get cache, disk space and removing unused packages."
    holdTerminal 1 # Hold for user to read
    apt-get clean -y
    apt-get autoclean -y
    apt-get autoremove -y
    sectionBreak

    cPrint "GREEN" "Checking and debugging completed successfuly!!"
    sectionBreak
}

# Function to exit script with custom coloured message
function exitScript(){

    cPrint "RED" "Exiting script...." # Display exit message
    holdTerminal 1 # Hold for user to read

    if [ "$1" == '--end' ]
    then # Check for --end switch
        ${clear} # Clear terminal

        cd ~ || exit # Change to home directory
        showScriptInfo # Show script information

        # Get script execution time
        endTime=`date +%s` # Get start time
        executionTimeInSeconds=$((endTime-startTime))
        formatTime $executionTimeInSeconds # Calculate time in days:hours:minutes:seconds

        # Draw logo
        printf "\n\n       __   __\n      |  | |  |  ___\n      |  | |  | /  /\n    __|  | |  |/  /\n  /  _   | |     <\n |  (_|  | |  |\  \ \n  \______| |__| \__\ \n\n "
        cPrint "YELLOW" "Script execution time : $totalExecutionTime \n"
        cPrint "RED" "Exited script...\n\n" # Display exit message
        cd ~ || exit # Change to home directory
        rm -r vmwareFix &> /dev/null # Delete vmwareFix folder

    elif [ "$1" == '--connectionFailure' ]
    then
        cPrint "RED" "\n\n This script requires a stable internet connection to work fully!!"
        cPrint "NC" "Please check your connection settings and re-run the script.\n"

        if [ $ranAnyMethod -eq 1 ]
        then
            # Check for and fix any broken installs or unmet dependencies
            checkDebugAndRollback --network
        fi
    fi

    exit 0 # Exit script
}

# Function to confirm usage of previously used target version
function queryReuseTargetVersion(){

    while true
    do # Start infinite loop
        ${clear} # Clear terminal

        # Prompt user to set GNOME Desktop as default
        cPrint "YELLOW" "Should the script reuse version $targetVmwareVersion for current method?\n\t1. Y (Yes) - to reuse version $targetVmwareVersion\n\t2. N (No) to set another version." |& tee -a $logFileName
        read -p ' option: ' queryReuse
        queryReuse=${queryReuse,,} # Convert to lowercase
        # Display choice
        cPrint "GREEN" " You chose : $queryReuse" |& tee -a $logFileName

        if  [[ "$queryReuse" == 'yes' || "$queryReuse" == 'y'
              || "$queryReuse" == '1' ]]
        then # Option : Yes
            return $(true) # Exit loop returning true
        elif [[ "$queryReuse" == 'no' || "$queryReuse" == 'n'
              || "$queryReuse" == '2' ]]
        then # Option : No
            ${clear} # Clear terminal
            return $(false) # Exit loop returning false
        else
            # Invalid entry
            cPrint "GREEN" "Invalid entry!! Please try again." |& tee -a $logFileName
        fi

        sleep 1 # Hold loop
    done
}

# Function to ask user for vmware version to be used
function getTargetVmwareVersion(){

    # Check if target vmware version is already set
    if [ -z "$targetVmwareVersion" ]
    then
        while true
        do # Start infinite loop
            ${clear} # Clear terminal

            # Prompt user for Vmware version
            cPrint "YELLOW" "Input Vmware version to continue."
            cPrint "GREEN" "Example version - 16.0.0"
            read -p ' Vmware version: ' vmwareVersion
            targetVmwareVersion=${vmwareVersion,,} # Convert to lowercase
            cPrint "GREEN" " You chose : $targetVmwareVersion" # Display choice

            # Check input
            if [[ $targetVmwareVersion =~ $versionNoSequence ]]
            then
                return $(true) # Exit loop returning true
            else
                cPrint "GREEN" "Invalid version!! Please try again." # Invalid entry
            fi

            sleep 1 # Hold loop
        done

    else
        if ! queryReuseTargetVersion
        then
            targetVmwareVersion=""
            getTargetVmwareVersion
            break
        fi
    fi
}

function makeInstalls(){
    cd /usr/lib/vmware/modules/source

    cPrint "YELLOW" "Extracting vmmon.tar in /usr/lib/vmware/modules/source"
    tar xf vmmon.tar
    cPrint "GREEN" "Extracting complete."
    holdTerminal 1 # hold

    cPrint "YELLOW" "Extracting vmnet.tar in /usr/lib/vmware/modules/source"
    tar xf vmnet.tar
    cPrint "GREEN" "Extracting complete."
    holdTerminal 1 # hold

    cd vmmon-only
    cPrint "YELLOW" "Building vmmon modules from MakeFile"
    holdTerminal 1 # Hold
    make
    cd ..

    cd vmnet-only
    cPrint "YELLOW" "Building vmnet modules from MakeFile"
    holdTerminal 1 # Hold
    make
    cd ..

    uname=`uname -r` # Get Linux verison
    cPrint "YELLOW" "Creating /lib/modules/$uname/misc"
    holdTerminal 1 # Hold
    mkdir /lib/modules/`uname -r`/misc

    cPrint "YELLOW" "Copying vmmon.o to /lib/modules/$uname/misc"
    holdTerminal 1 # Hold
    cp vmmon.o /lib/modules/`uname -r`/misc/vmmon.ko
    cPrint "GREEN" "Done"

    cPrint "YELLOW" "Copying vmnet.o to /lib/modules/$uname/misc"
    holdTerminal 1 # Hold
    cp vmnet.o /lib/modules/`uname -r`/misc/vmnet.ko
    cPrint "GREEN" "Done"

    cPrint "YELLOW" "Generating a list of dependency description of modules and associated map files"
    holdTerminal 1 # Hold
    depmod -a

    cPrint "YELLOW" "Restarting vmware service"
    holdTerminal 1 # Hold
    /etc/init.d/vmware restart
}

# Function to build the modules from source and install them manually
function retrieveBuildInstallModules(){
    if getTargetVmwareVersion
    then
        if [ ! -z "$targetVmwareVersion" ]
        then
            ${clear} # Clear terminal

            createWorkingDirectory # Create working directory

            cPrint "YELLOW" "Downloading vmware-host-modules for version $targetVmwareVersion from https://github.com/mkubecek/vmware-host-modules"
            holdTerminal 1 # Hold terminal

            # Url with vmware host odules
            url="https://github.com/mkubecek/vmware-host-modules/archive/workstation-$targetVmwareVersion.tar.gz"

            # File with vmware host modules
            file="workstation-$targetVmwareVersion.tar.gz"

            if isConnected
            then # Network connection established
                # Check if file was downloaded
                cPrint "YELLOW" "Downloading modules. Please wait..."
                `wget -q -N $url` &> /dev/null
                current_ts=`stat -c %y $file`
                if new_ts=$(stat -c %y $file &> /dev/null)
                then
                    if [ "$current_ts" != "$new_ts" ];
                    then

                        if [[ "$1" == "$buildFromSourceAndInstall" ]]
                        then
                            cPrint "GREEN" "Version $targetVmwareVersion download complete."
                            holdTerminal 1 # Hold terminal
                            ${clear} # Clear terminal

                            cPrint "YELLOW" "Extracting downloaded workstation-$targetVmwareVersion.tar.gz"
                            holdTerminal 1 # Hold terminal
                            $(tar -xzf workstation-$targetVmwareVersion.tar.gz)
                            cPrint "GREEN" "Extraction complete."
                            holdTerminal 1 # Hold terminal

                            cPrint "YELLOW" "Copying modules for building."
                            holdTerminal 1 # Hold terminal
                            path="vmware-host-modules-workstation-$targetVmwareVersion"
                            $(cp -r $path/* .)
                            cPrint "GREEN" "Copying complete."
                            holdTerminal 1 # Hold terminal

                            cPrint "YELLOW" "Running make to build modules from Makefile."
                            holdTerminal 1 # Hold terminal
                            $(make -i) # make ignoring errors

                            cPrint "YELLOW" "Running make install to copy the built modules to required locations."
                            holdTerminal 2 # Hold
                            $(make install -i ) # make install ignoring errors

                            cPrint "GREEN" "Installation by method 1 completed."
                            holdTerminal 1 # Hold terminal

                            ranAnyMethod=1 # Set ran any method to 1

                        elif [[ "$1" == "$replaceOriginalTarballs" ]]
                        then
                            cPrint "GREEN" "Version $targetVmwareVersion download complete."
                            holdTerminal 1 # Hold terminal
                            ${clear} # Clear terminal

                            cPrint "YELLOW" "Extracting downloaded workstation-$targetVmwareVersion.tar.gz"
                            holdTerminal 1 # Hold terminal
                            $(tar -xzf workstation-$targetVmwareVersion.tar.gz)
                            cPrint "GREEN" "Extraction complete."
                            holdTerminal 1 # Hold terminal

                            cPrint "YELLOW" "Copying vmmon and vmnet for archiving."
                            holdTerminal 1 # Hold terminal
                            path="vmware-host-modules-workstation-$targetVmwareVersion"
                            $(cp -r $path/* .)
                            cPrint "GREEN" "Copying complete."
                            holdTerminal 1 # Hold terminal

                            cPrint "YELLOW" "Adding vmmon to .tar archive."
                            holdTerminal 1 # Hold terminal
                            $(tar -cf vmmon.tar vmmon-only)
                            cPrint "GREEN" "Archiving complete."
                            holdTerminal 1 # Hold terminal

                            cPrint "YELLOW" "Adding vmnet to .tar archive."
                            holdTerminal 1 # Hold terminal
                            $(tar -cf vmnet.tar vmnet-only)
                            cPrint "GREEN" "Archiving complete."
                            holdTerminal 1 # Hold terminal

                            cPrint "YELLOW" "Copying vmmon.tar and vmnet.tar to /usr/lib/vmware/modules/source/"
                            holdTerminal 1 # Hold terminal
                            cp -v vmmon.tar vmnet.tar /usr/lib/vmware/modules/source/
                            cPrint "GREEN" "Copying complete."
                            holdTerminal 1 # Hold terminal

                            cPrint "NC" "Checking for and removing duplicates..."
                            holdTerminal 1 # Hold terminal
                            rm -f usr/lib/vmware/modules/source/vmnet\ copy.tar &> /dev/null

                            cPrint "YELLOW" "Installing modules..."
                            holdTerminal 1 # Hold terminal
                            vmware-modconfig --console --install-all

                            cPrint "GREEN" "Installation by method 2 completed."
                            holdTerminal 1 # Hold terminal

                            # Run make after downloading and copying required module files
                            makeInstalls

                            ranAnyMethod=1 # Set ran any method to 1
                        fi
                    fi
                else
                    cPrint "RED" "\nNetwork connection failure!!\n"
                    ranAnyMethod=0 # Set ran any method to 0
                fi
            else
                ${clear} # Clear terminal
                cPrint "RED" "The version $targetVmwareVersion you entered does not exist. Please try again."
                holdTerminal 3 # Hold terminal
                targetVmwareVersion="" # Reset target vmware version
            fi
        else
            cPrint "GREEN" "Vmware version empty!"
            holdTerminal 1 # Hold terminal
        fi
    else
        cPrint "GREEN" "Vmware version not provided!"
        holdTerminal 1 # Hold terminal
    fi
}

# Function to set PATH
function exportPath(){

    # Export path
    cPrint "YELLOW" "Exporting PATH."
    holdTerminal 1 # Hold terminal
    export PATH="/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin"
    cPrint "RED" "$PATH" # Display PATH
    holdTerminal 1 # Hold terminal
    #export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin"
}

# Function to display main menu
function displayMainMenu(){
    while true
    do # Start infinite loop
        ${clear} # Clear terminal

        # Prompt user for Vmware version
        cPrint "YELLOW" "This script uses two methods to retrieve the module source build modules and install them. Use the second if the first does not work for you.\n\n\t1. Method 1: Build and install.\n\t2. Method 2: Replace original tarballs.\n\t3. Run both methods.\n\t4. Exit"

        cPrint "GREEN" "Select a method above to proceed."
        read -p ' Method: ' method
        method=${method,,} # Convert to lowercase
        cPrint "GREEN" " You chose : $method" # Display choice

        # Check input
        if [[ "$method" == "1" ]]
        then
            # Build the modules from source and install them manually
            retrieveBuildInstallModules "$buildFromSourceAndInstall"

        elif [[ "$method" == "2" ]]
        then
            # Download Vmware host modules and replace original tarballs
            retrieveBuildInstallModules "$replaceOriginalTarballs"

        elif [[ "$method" == "3" ]]
        then
            runningBothOptions=1 # Set running both options to 1

            # Build the modules from source and install them manually
            retrieveBuildInstallModules "$buildFromSourceAndInstall"

            # Download Vmware host modules and replace original tarballs
            retrieveBuildInstallModules "$replaceOriginalTarballs"

        elif [[ "$method" == "4" ]]
        then # Exit script

            if [ $ranAnyMethod -eq 1 ]
            then
                checkDebugAndRollback
            fi
            break # Break from loop
        else
            cPrint "GREEN" "Invalid version!! Please try again." # Invalid entry
        fi

        sleep 1 # Hold loop
    done
}

# Functio to start script
function initScript(){

    startTime=`date +%s` # Get start time

    echo ""
    ${clear} # Clear terminal
    cPrint "GREEN" "Fetching required packages."
    apt-get install netcat &> /dev/null # Install netcat if not installed to be used for connection check
    holdTerminal 1 # Hold
    ${clear} # Clear terminal

    echo ""; cPrint "RED" "Running as $USER!!"
    cPrint "YELLOW"	"This script will help you fix your Vmware host modules and vmmon on your $targetLinux."
    holdTerminal 5 # Hold for user to read

    # Check if user is running as root
    if isUserRoot
    then
        if isConnected
        then # Network connection established
            displayMainMenu # Display main menu with options

            if [ $ranAnyMethod -eq 1 ]
            then
                exportPath # export PATH
                sectionBreak
            fi
        else
            exitScript --connectionFailure # Exit script on connection failure
        fi
    fi

    sectionBreak
    showScriptInfo # Show Script Information
}

initScript # Initiate script
exitScript --end # Exit script
