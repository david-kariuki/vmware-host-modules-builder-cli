# Tracker

 - Script should handle a failure of wget (e.g. when there is a new VMware version but no corresponding branch yet)
 - Script should IMHO do some sanity checks (e.g. existence of the directory with module sources, check if it is executed with necessary permissions)
 - Script shouldn't remove existing tarballs until it succeeded to create new ones so that user doesn't end up with no vm{mon,net}.tar if something goes wrong.
 - Auto detect branch name so it could be determined from the information in `/etc/vmware/config` so that users wouldn't need to edit the script.
