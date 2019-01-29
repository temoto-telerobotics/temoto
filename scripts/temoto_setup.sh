#!/bin/bash

RED="\e[31m"
YELLOW="\e[33m"
GREEN="\e[32m"
BOLD="\e[1m"
NL="\n"
RESET="\e[39m\e[0m"

ROS_VERSION="kinetic"
NEW_STUFF_INSTALLED=0

# Usage: find_install_from_source <package_name> <git_repo_uri> 
find_install_from_source () {
  PACKAGE_NAME=$1
  PACKAGE_PATH=$2

  # Look for the package
  rospack find $PACKAGE_NAME &> /dev/null

  # Get the package if it was not found
  if [[ $? = 0 ]]; then
    echo -e $GREEN$BOLD"*" $PACKAGE_NAME $RESET$GREEN"package is already installed."$RESET
  else
    # Clone the rviz_plugin_manager package
    echo -e $RESET$GREEN"Cloning the" $PACKAGE_NAME "package to"$BOLD $CW_DIR/$SUBFOLDER $RESET
    git clone $PACKAGE_PATH
    NEW_STUFF_INSTALLED=1
  fi 
}

# Usage: find_install_from_apt <package_name>
find_install_from_apt () {
  PACKAGE_NAME=$1
  
  # Look for the package
  SEARCH_RESULT=$(dpkg --list | grep $PACKAGE_NAME | awk -F: '{print $1}' | cut -d' ' -f3)

  if [[ $SEARCH_RESULT = $PACKAGE_NAME ]]; then
    echo -e $GREEN$BOLD"*" $PACKAGE_NAME $RESET$GREEN"package is already installed."$RESET
  else
    # Clone the rviz_plugin_manager package
    echo -e $RESET$GREEN"Installing the" $PACKAGE_NAME $RESET
    sudo apt install $PACKAGE_NAME
    NEW_STUFF_INSTALLED=1
  fi 
}

# Go back to the catkin_workspace/src folder
P1=$(awk -F: '{print $1}' <<< "$ROS_PACKAGE_PATH")
P2=$(awk -F: '{print $2}' <<< "$ROS_PACKAGE_PATH")
CW_DIR="Uninitialized directory"

# Find the catkin_workspace directory
if [[ $P1 = *"opt"* ]]; then
  CW_DIR=$P2
else
  CW_DIR=$P1
fi

if [[ -z $CW_DIR ]]; then
  echo -e $RED$BOLD"Could not find the catkin workspace, have you sourced it? Exiting."$RESET
  exit
fi

# Check for sub-folder argument
SUBFOLDER="" 
if [[ ! -z $1 ]]; then
  SUBFOLDER=$1
  mkdir -p $CW_DIR/$SUBFOLDER
fi

# Save the currend directory and go to the catcin_ws/src directory
PREV_DIR=$(pwd)
cd $CW_DIR/$SUBFOLDER

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#                  Install TeMoto dependencies
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

echo -e $NL"TeMoto dependencies:"

find_install_from_source rviz_plugin_manager https://github.com/UTNuclearRoboticsPublic/rviz_plugin_manager
find_install_from_source human_msgs https://github.com/ut-ims-robotics/human_msgs
find_install_from_source file_template_parser https://github.com/ut-ims-robotics/file_template_parser
find_install_from_apt ros-$ROS_VERSION-moveit-ros-planning-interface
find_install_from_apt ros-$ROS_VERSION-tf2-geometry-msgs

# Install Intel TBB
find_install_from_apt libtbb2
find_install_from_apt libtbb-dev

# Install TinyXML
find_install_from_apt libtinyxml-dev
find_install_from_apt libtinyxml2-2v5
find_install_from_apt libtinyxml2-dev
find_install_from_apt libtinyxml2.6.2v5

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#                  Install TeMoto subsystems
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

echo -e $NL"TeMoto subsystems:"

# Open the subsystems file
TEMOTO_SUBSYS_FILE=$(rospack find temoto)/scripts/temoto_subsystems.txt
SUBSYSTEM_NAMES=$(cat  $TEMOTO_SUBSYS_FILE |tr "\n" " ")

for subsys_name in $SUBSYSTEM_NAMES 
do
  if [[ $subsys_name == "temoto" ]]; then
    continue
  fi
  # Download temoto repositories
  find_install_from_source $subsys_name https://github.com/temoto-telerobotics/$subsys_name.git
done

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#                  Export TeMoto aliases
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ -z $TEMOTO_ALIASES_SET ]]; then
  echo -e -n $NL"Export TeMoto script shortcuts? (y/n)" $RESET
  read -p " " -n 1 -r
  echo

  # If the user replied "y" or "Y"
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "" >> ~/.bashrc
    echo "# TeMoto aliases" >> ~/.bashrc
    echo "alias temoto_pull='bash $(rospack find temoto)/scripts/temoto_pull.sh'" >> ~/.bashrc
    echo "alias temoto_push='bash $(rospack find temoto)/scripts/temoto_push.sh'" >> ~/.bashrc
    echo "export TEMOTO_ALIASES_SET=1" >> ~/.bashrc
    echo -e $YELLOW"NB! The aliases are effective after you have sourced the '.bashrc' or opened a new terminal"$RESET
  else
    echo -n
  fi
fi

cd $PREV_DIR

if [[ $NEW_STUFF_INSTALLED == 1 ]]; then
  echo -e $NL"TeMoto packages are installed,$BOLD run catkin make."$RESET
  echo -e $YELLOW"NB! If"$BOLD "temoto_nlp"$RESET$YELLOW "package was just installed, then make sure that you have run 'temoto_nlp/scripts/install_meta.sh' before running catkin_make"
else
  echo -e $NL"TeMoto packages are installed."
fi
