FROM java:8
VOLUME /tmp
COPY ./vault-client.sh /
RUN chmod +x /vault-client.sh
EXPOSE 8200
RUN ["/bin/bash","/vault-client.sh"]

COPY ./target/ /target/
RUN mv /target/spring-petclinic-2.2.0.BUILD-SNAPSHOT.jar /target/app.jar \
  && ln -s /target/app.jar /app.jar
EXPOSE 8080
ENTRYPOINT ["java","-Djava.security.egd=file:/dev/./urandom","-jar","/app.jar"]

