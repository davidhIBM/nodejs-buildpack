

reinstall_packages() {
  
  cd $APP_DIR || true
  rm -fr node_modules || true
  npm install || true
  npm shrinkwrap || true
  echo "reinstalled node_modules directory..."
}

backup_packages() {
  if  [ "${CONTAINER_TYPE}" = "cf" ] ; then 
        rm -f $APP_DIR/npm-shrinkwrap.json
	return;
  fi	

  # last back up - if the user need to go back one step
  if [ -e $APP_DIR/node_modules  ] ; then 
	cp -r $APP_DIR/node_modules $APP_DIR/node_modules.old || true
  fi
  
  # if there is a user supply npm-shrinkwrap.json ,this thing will override it 
  if [ -e $APP_DIR/npm-shrinkwrap.json  ] ; then 
	mv $APP_DIR/npm-shrinkwrap.json  $APP_DIR/npm-shrinkwrap.json.old || true
  fi
  
  if [ -e $APP_DIR/package.json  ] ; then 
	cp $APP_DIR/package.json  $APP_DIR/package.json.old || true
  fi	
  cd $APP_DIR || true
  echo "backup_packages node_modules directory..."
}

set_a_side_original_node_modules() {
  if  [ "${CONTAINER_TYPE}" = "cf" ] ; then 
	return;
  fi	
    
  # create original files in the app directory , so we can revert back to the 
  # original application, if the user ask for it. this is done ONLY ONCE at startup.
  if [  \( ! -e $APP_DIR/node_modules.orig \) -a \( -e $APP_DIR/node_modules \) ] ; then 
	cp -r $APP_DIR/node_modules $APP_DIR/node_modules.orig || true
	echo "set a side original node_modules directory..."
  fi
  # NOTE this is optional - the file way exist or not.
  if [ ! -e $APP_DIR/npm-shrinkwrap.json.orig -a -e $APP_DIR/npm-shrinkwrap.json  ] ; then 
	cp $APP_DIR/npm-shrinkwrap.json $APP_DIR/npm-shrinkwrap.json.orig || true
    echo "set a side original npm-shrinkwrap.json..."
  fi
  if [ ! -e $APP_DIR/package.json.orig -a -e $APP_DIR/package.json ] ; then 
	cp $APP_DIR/package.json $APP_DIR/package.json.orig || true
    echo "set a side original package.json..."
  fi
  
}

undo_all_updates(){
  if  [ "${CONTAINER_TYPE}" = "cf" ] ; then 
	return;
  fi	
  
  # move to original files in the app directory ,reverting back to the 
  # as in the original application, if the user ask for it.
  if [ -e $APP_DIR/node_modules.orig ] ; then 
	cp  -r $APP_DIR/node_modules.orig $APP_DIR/node_modules || true
  fi
  if [ -e $APP_DIR/npm-shrinkwrap.json.orig ] ; then 
	cp $APP_DIR/npm-shrinkwrap.json.orig $APP_DIR/npm-shrinkwrap.json || true
  fi
  if [ -e $APP_DIR/package.json.orig ] ; then 
	cp $APP_DIR/package.json.orig $APP_DIR/package.json || true
  fi
  
  echo "moved back to original application files  ..."

}

undo_last_update(){
  if  [ "${CONTAINER_TYPE}" = "cf" ] ; then 
	return;
  fi	

  # move to original files in the app directory ,reverting back to the 
  # as in the original application, if the user ask for it.
  if [ -e $APP_DIR/node_modules.old ] ; then 
	cp -r $APP_DIR/node_modules.old $APP_DIR/node_modules || true
  fi
  if [ -e $APP_DIR/npm-shrinkwrap.json.old ] ; then 
	cp $APP_DIR/npm-shrinkwrap.json.old $APP_DIR/npm-shrinkwrap.json || true
  fi
  if [ -e $APP_DIR/package.json.old ] ; then 
	cp $APP_DIR/package.json.old $APP_DIR/package.json || true
  fi
  
  echo "moved one step back ..."

}

package_json_update(){
	#change the json file to "^{Version}" , where {Version} is what found in the "npm-shrinkwrap.json" file.
	cd $APP_DIR
	if [ ! -e $APP_DIR/npm-shrinkwrap.json ] ; then 
	    npm shrinkwrap
		if [ $? != 0 ]; then 
			echo "Failed to run \"npm shrinkwrap\". please check your application package.json!"
			return ;
		fi
		echo `ls -l`
		sleep 5
		echo `ls $APP_DIR/npm-shrinkwrap.json`
		# try to create the file if it does not exist 
		if [ ! -e $APP_DIR/npm-shrinkwrap.json ] ; then 
		    echo  "This is the dir $APP_DIR "
			echo `ls -l`
			echo "could not create the npm-shrinkwrap.json ... $PWD"
			return;
		fi 
	fi 
 	if [ ! -e $APP_DIR/package.json ] ; then 
		echo "please check your application for package.json file. It is missing from the build!"
		return;
	fi 
 
	# take from the package.json file the list of pakages that need to be updates at production run 
	# NOTE: what about developmet stage ? 
	export DEP_PKG_LIST=`jq  '.dependencies | to_entries | .[].key  ' $APP_DIR/package.json | sed 's/"//g'`


	for dep_pkg in $DEP_PKG_LIST; do 
		# for each package get the current version as seen by the "npm shrinkwrap" command
		# add for it the general mark "^" which in npm languge allow some freedom for an upgrade of the package
		#local dep_pkg_version=`jq '.dependencies[] ' $APP_DIR/npm-shrinkwrap.json | grep -B 2 ${dep_pkg}@  | grep version | awk '{ print $2 }' | sed 's/,// ; s/^"/"^/'`
		local dep_pkg_version=`jq ".dependencies.${dep_pkg}.version " $APP_DIR/npm-shrinkwrap.json | sed 's/"/"^/'`
		#update the package.json to allowed freedom. 
		jq ".dependencies.${dep_pkg} = $dep_pkg_version " $APP_DIR/package.json > $APP_DIR/package.json.new
		mv $APP_DIR/package.json.new $APP_DIR/package.json
	done 
    
	rm  -f $APP_DIR/npm-shrinkwrap.json || true
    echo " Changed the package.json " 
		
}

enforce() {
    # enforcer start 
	cd $APP_DIR
	# check that the file exist if not return.
	if [ ! -e ${DEFENDER_HOME}/action.txt ] ;  then
		return;
	fi	

	# NOTE : we can handle a list of actions here - now only handling one action ,only.
	local action=`cat ${DEFENDER_HOME}/action.txt| head -n 1`

	# if action is empty file - rturn;
	if [ -z "${action}" ] ; then 
	   return ; 
	fi 
	echo "Updating the application with $action " 
	
	# need to be run at least once 
    set_a_side_original_node_modules $APP_DIR
	
	case "${action}" in
        reinstall_packages)
		    backup_packages $APP_DIR
            reinstall_packages $APP_DIR
            ;;
         
        update_packages)
		    backup_packages $APP_DIR
            package_json_update $APP_DIR
			reinstall_packages $APP_DIR
            ;;
         
        undo_all_updates)
			undo_all_updates $APP_DIR
            ;;
        undo_last_update)
			undo_last_update $APP_DIR
			;;
         
        *)
			if  [ "${CONTAINER_TYPE}" = "cf" ] ; then 
        			echo $"Undo all changes "
				return;
  			fi
  			echo $"Make no changes "
			
                        return;
                        echo $"Usage: $0 {reinstall_packages|update_packages|undo_all_updates|undo_last_update|}"
			#env 
            		exit 0
 
	esac

}
