

extract_packages() {

  # write the information in JSON format
  # each line has it output here
  # { "PkgList" : "   --- start the 
  
  echo -n { \"UNIX_PKGS\": { \"packages\" :[ >  $DEFENDER_HOME/distro.json
  # packageVersion,packageVersion ...packageVersion
  dpkg-query -W -f='{\n"pkg":"${Package}_${Version}"},' | sed 's/,$//' >>  $DEFENDER_HOME/distro.json
  # add aditional packages, written in a file and supply by the buildpack it self 
  if [  -s $DEFENDER_HOME/importedPackages.csv -a -r $DEFENDER_HOME/importedPackages.csv ]; then
    echo "adding packages from $DEFENDER_HOME/importedPackages.csv" 
    awk -F , '{ if(FNR > 1 && $1 != "" && $2 != "" ) { printf( "\n,{\"pkg\":\"%s_%s\"}",$1,$2 )} };' $DEFENDER_HOME/importedPackages.csv   >>  $DEFENDER_HOME/distro.json
  fi
  # ", ---- end the packageVersion list  
  echo ], >>  $DEFENDER_HOME/distro.json
  # "Codename": "trusty", 
  lsb_release -a 2>&1 |  grep Codename | awk '{printf "\"version\": \"%s\"," ,$2}' >> $DEFENDER_HOME/distro.json
  # "DistributorID": "Ubunto", 
  lsb_release -a 2>&1 | grep "Distributor ID:" | awk '{printf "\n\"distribution\": \"%s\"",$3}'>> $DEFENDER_HOME/distro.json
  # ", ---- end the Ubonto list and start SID` 
  echo }, >>  $DEFENDER_HOME/distro.json
  echo -n \"sid\":\" >>  $DEFENDER_HOME/distro.json
  cat $DEFENDER_HOME/sid  >>  $DEFENDER_HOME/distro.json
  # ", ---- end the SID and start url`
  echo \", >>  $DEFENDER_HOME/distro.json
  echo -n \"url\": \">>  $DEFENDER_HOME/distro.json
  cat $DEFENDER_HOME/url >>  $DEFENDER_HOME/distro.json
  echo  \",>>  $DEFENDER_HOME/distro.json
}

shrinkwrap_json() {
   cd $APP_DIR
   npm shrinkwrap --dev || true
   if [ -f npm-shrinkwrap.json ] ; then 
     echo -n \"shrinkwrap\" :  >>  $DEFENDER_HOME/distro.json
	 cat npm-shrinkwrap.json >>  $DEFENDER_HOME/distro.json
	 echo -n , >>  $DEFENDER_HOME/distro.json
   else 
     echo "Error : could not produce npm-shrinkwrap.json";
	 echo -n \"shrinkwrap\" : {} , >> $DEFENDER_HOME/distro.json
   fi 
}

package_json(){
	cd $APP_DIR
	if [ -f package.json ] ; then 
		echo -n \"packagejson\" :  >>  $DEFENDER_HOME/distro.json
		cat package.json >>  $DEFENDER_HOME/distro.json
	else 
		echo "Error : could not find  package.json";
		#  generate an empty one.
		echo -n \"packagejson\" : {}  >> $DEFENDER_HOME/distro.json
	fi 
}
nodejs_section(){
	echo -n \"nodejs\" : { >>  $DEFENDER_HOME/distro.json
	shrinkwrap_json
	package_json
	echo -n }, >>  $DEFENDER_HOME/distro.json
}
close_json () { 
  # "date": "Wed Jul 27 13:19:17 IDT 2016" }   
  echo -n \"date\": \"`date`\" }>> $DEFENDER_HOME/distro.json
}

extract_node_modules() {
    extract_packages
	nodejs_section
	close_json
	cd $APP_DIR
	#need to to wipe out the action.txt file - so an old operation will not be used.
	rm -f $DEFENDER_HOME/action.txt
	#npm ls -json 2>/dev/null | node $DEFENDER_HOME/NodeProtect.js  
	cat $DEFENDER_HOME/distro.json | node $DEFENDER_HOME/NodeProtect.js  
}

# install node modules for the nodejs files in defender dir 
cd $DEFENDER_HOME
export NODE_PATH=$DEFENDER_HOME
echo installing defender at $DEFENDER_HOME
    
#NOTE: the "e" at the end is to avoid empty string comparision
if [ "${2}e" = "runoncee" ] ; then 
	extract_node_modules 
	echo extract_node_modules once
	cd $APP_DIR
	exit 0;
fi

#Run forever 
i=0
while [ true ]; do
  i=`expr $i + 1`
  
  # extract the node modules every 120 seconds  
  if [ $(( $i % 10)) == 2 ];then  
	extract_node_modules 
	echo extract_node_modules
  fi
  sleep 12;
done;

