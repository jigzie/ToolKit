##
##HUM v2 Rest Installer
##By Gido Baumann & Alex Malbet


# Usage
There are two scripts to execute. 
Parameters are asked one at the time so don't pass them as arguments.

- upload-artifacts.sh : This script will upload all artifacts
to the server.  In the process it will place the company name,
environment name, datameer host/user, and product id in the
respective connections/export job.

This script will also generate a folder "artifacts_processed"
which contains all processed artifacts (after find/replace
some variables).  It will also generate "artifacts.list"
containing precisely the jobs that needs to be scheduled to
launch the entire suite of jobs in the right order.

- launch_hum.sh : This script will submit all jobs for execution
immediately. Run this script after having executed upload-artifacts.sh 
OR to re-submit all jobs again for execution.

This script will read the file "artifacts.list" which is created
by upload-artifacts.sh.

#### Troubleshooting
-Both scripts will generate an output log you can tail.
-There is no error checking/validation of inputs so make sure the
username/password for datameer is correct before continuing.
- In the event you need to cancel execution (control+c) for
upload-artifacts.sh, make sure you recover the original artifacts
"mv artifacts_backup artifacts".
