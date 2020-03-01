FROM openjdk:8-jdk

COPY . /opt/deploy/

VOLUME [ "/opt/jenkins" ]

CMD ["/bin/bash", "-c", "/opt/deploy/startup.sh"]

EXPOSE 8080 8443