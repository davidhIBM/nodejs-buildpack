FROM readytalk/nodejs

############################## Handle Defender Creation files ################ 
# create the SID , URL and DASH
ONBUILD RUN rm  /etc/defender/sid
ONBUILD RUN bash -c "cat /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 32 > /etc/defender/sid"
RUN echo 'IBM Defender'
RUN mkdir /etc/defender
RUN cat /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 32 > /etc/defender/sid
RUN echo -n "https://bluesecure.mybluemix.net" > /etc/defender/url
RUN echo -n "https://bluesecuredashboard.mybluemix.net?channel=" > /etc/defender/dash


############# Add the hooks for IPR  ###############################
# LD_PRELOAD defender hooks
ADD blueSecure_hook.so /lib/
ENV LD_PRELOAD=/lib/blueSecure_hook.so

# defender cli 
ADD defender /usr/bin
ADD defend /usr/bin
ADD trigger /usr/bin
#RUN nohup trigger 1 time


################### Adding package managment / enforcment ##################
RUN mkdir -p /app/.defender
ENV DEFENDER_HOME=/app/.defender
ENV APP_DIR=/app
ENV CONTAINER_TYPE=docker
ENV VCAP_APPLICATION='{"limits":{"fds":16384,"mem":1024,"disk":1024},"application_name":"TerminalApp","application_uris":["terminalapp.mybluemix.net"],"name":"TerminalApp","space_name":"soffery_dev","space_id":"24177892-5067-4806-8897-2414cc2a36ae","uris":["terminalapp.mybluemix.net"],"users":null,"version":"1a46d628-7a6f-41ea-8a69-4f02431a2b51","application_version":"1a46d628-7a6f-41ea-8a69-4f02431a2b51","application_id":"f2d51ac7-5ff5-4b02-90ec-3729d87dc15e","instance_id":"7b6503775d374a3aa278362a702d8eba","instance_index":0,"host":"0.0.0.0","port":63103,"started_at":"2016-08-22 10:25:39 +0000","started_at_timestamp":1471861539,"start":"2016-08-22 10:25:39 +0000","state_timestamp":1471861539}'


# NOTE: better solution would be with a softlink  
ONBUILD RUN bash -c "ln -sf /etc/defender/sid  /app/.defender/sid" 
ONBUILD RUN bash -c "ln -sf /etc/defender/url  /app/.defender/url"
ONBUILD RUN bash -c "ln -sf /etc/defender/dash /app/.defender/dash" 
#please read on Linux Standart Base project 
RUN apt-get install -y lsb-release


ADD enforcer.sh /app/.defender
ADD importedPackages.csv /app/.defender
ADD NodeProtect.js /app/.defender
ADD package.json /app/.defender
ADD plugin.js /app/.defender
ADD protect.sh /app/.defender
ADD release.sh /app/.defender

WORKDIR /app/.defender
RUN npm install
WORKDIR /app

# I think we should work with defender.sh  ?
#ONBUILD RUN /app/.defender/defender.sh -c 



EXPOSE 80
ENTRYPOINT ["/app/.defender/release.sh", "/app/.defender/"]


