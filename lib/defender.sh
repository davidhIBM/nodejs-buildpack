compile_files_from_buildpack () {


	# BlueSecure - Creating parmeters to run with url,sid and dash at $DEFENDER_HOME.
	# Will be the same for all the instances of the same application. 
	chmod +x $BP_DIR/lib/*.sh  $BP_DIR/lib/*.js
	chmod +r $BP_DIR/lib/importedPackages.csv

	# BlueSecure 
	#copy over the protect application.
	cp $BP_DIR/lib/defender.sh              "$DEFENDER_HOME/"
	cp $BP_DIR/lib/protect.sh               "$DEFENDER_HOME/"
	cp $BP_DIR/lib/NodeProtect.js           "$DEFENDER_HOME/"
	cp $BP_DIR/lib/plugin.js                "$DEFENDER_HOME/"
	cp $BP_DIR/lib/package.json             "$DEFENDER_HOME/"
	cp $BP_DIR/lib/enforcer.sh              "$DEFENDER_HOME/"  
	cp $BP_DIR/lib/importedPackages.csv     "$DEFENDER_HOME/"  
	cp $BP_DIR/lib/release.sh               "$DEFENDER_HOME/"  
	
	#BlueSecure installing defender Nodejs libraries for NodeProtect.js
	cd $DEFENDER_HOME
	npm install
	cd ..
}


create_sid_url_dash () {
	echo "running defender ..."

    cat /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 32 > ${DEFENDER_HOME}/sid || true
    echo -n "https://bluesecure.mybluemix.net" > ${DEFENDER_HOME}/url || true
    echo -n "https://bluesecuredashboard.mybluemix.net?channel=" > ${DEFENDER_HOME}/dash || true

	sid=`cat ${DEFENDER_HOME}/sid`
	url=`cat ${DEFENDER_HOME}/url`
	dash=`cat ${DEFENDER_HOME}/dash`
	echo "Defender URL         : " $url
	echo "Application Identity : " $sid
	echo "Application Dashboard: " ${dash}${sid}
}


compile_files_from_buildpack
create_sid_url_dash