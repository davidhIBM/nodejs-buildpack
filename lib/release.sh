echo " starting the release.sh script "
echo  "see environment variables below :" 
env 
echo "This is the application HOME directory: ${PWD}"
echo "The BlueSecure dashboard can be found in the follow URL:" 
cat ${DEFENDER_HOME}/dash ${DEFENDER_HOME}/sid 

npm start
