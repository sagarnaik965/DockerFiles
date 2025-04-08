# Use AlmaLinux as the base image
FROM almalinux

# Metadata indicating an image maintainer
LABEL maintainer="adv@cdac.in"

# Install required packages and update in a single step to reduce layers
RUN yum -y update && \
    yum -y install openssh-server procps unzip && \
    yum clean all && \
    echo "alias ll='ls -l'" >> /root/.bashrc

# Copy the hardening script to the container and execute it in a single layer
COPY script.sh /opt/script.sh
RUN chmod 775 /opt/script.sh && /opt/script.sh

# Create Folder structure for Project in a single step
RUN mkdir -p /opt/appdata/logs/tomcatlogs \
    /usr/appserver \
    /usr/java 

# Copy all required files together to reduce layers
COPY jdk1.8.0_401.zip tomcat.zip /opt/

# Unzip jdk and tomcat files in a single step to reduce layers
RUN unzip /opt/jdk1.8.0_401.zip -d /usr/java/ && \
    unzip /opt/tomcat.zip -d /usr/appserver/ 

# Install and configure JDK in a single step to reduce layers
RUN cd /usr/java/jdk1.8.0_401/ && \
    alternatives --install /usr/bin/java java /usr/java/jdk1.8.0_401/bin/java 2 && \
    alternatives --set java /usr/java/jdk1.8.0_401/bin/java && \
    alternatives --install /usr/bin/jar jar /usr/java/jdk1.8.0_401/bin/jar 2 && \
    alternatives --set jar /usr/java/jdk1.8.0_401/bin/jar && \
    alternatives --install /usr/bin/javac javac /usr/java/jdk1.8.0_401/bin/javac 2 && \
    alternatives --set javac /usr/java/jdk1.8.0_401/bin/javac

# User creation and group assignment in a single step to reduce layers
RUN useradd -r -m -U -d /opt/tomcat -s /bin/false tomcat && \
    groupadd ApplicationServer && \
    usermod -aG ApplicationServer tomcat && \
    usermod -aG ApplicationServer root

# Permissions and ownership in a single step to reduce layers
RUN chmod -R 775 /usr/java /usr/appserver /opt/appdata && \
    chown -R root:root /usr/appserver /opt/appdata
RUN rm -rf tomcat.zip jdk1.8.0_401.zip

# Expose settings
EXPOSE 22 25 8080

# Start Tomcat and keep the container running
CMD /usr/appserver/tomcat/bin/catalina.sh start; sleep inf