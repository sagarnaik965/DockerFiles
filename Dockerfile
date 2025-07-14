# Use AlmaLinux as the base image
FROM almalinux

# Metadata
LABEL maintainer="adv@cdac.in"

# Define JDK version once — only change here
ENV JDK_VERSION=jdk1.8.0_451
ENV JDK_ZIP=${JDK_VERSION}.zip


# Install required packages
RUN yum -y update && \
    yum -y install openssh-server procps unzip && \
    yum clean all && \
    echo "alias ll='ls -l'" >> /root/.bashrc

# Copy and run hardening script
COPY script.sh /opt/script.sh
RUN chmod 775 /opt/script.sh && /opt/script.sh

# Create folder structure
RUN mkdir -p /opt/appdata/logs/tomcatlogs \
    /usr/appserver \
    /usr/java

# Copy JDK and Tomcat zips
COPY ${JDK_ZIP} tomcat.zip /opt/

# Unzip both archives
RUN unzip /opt/${JDK_ZIP} -d /usr/java/ && \
    unzip /opt/tomcat.zip -d /usr/appserver/

# Configure Java alternatives using hardcoded path
RUN alternatives --install /usr/bin/java java /usr/java/${JDK_VERSION}/bin/java 2 && \
    alternatives --set java /usr/java/${JDK_VERSION}/bin/java && \
    alternatives --install /usr/bin/jar jar /usr/java/${JDK_VERSION}/bin/jar 2 && \
    alternatives --set jar /usr/java/${JDK_VERSION}/bin/jar && \
    alternatives --install /usr/bin/javac javac /usr/java/${JDK_VERSION}/bin/javac 2 && \
    alternatives --set javac /usr/java/${JDK_VERSION}/bin/javac

# Add user and group
RUN useradd -r -m -U -d /opt/tomcat -s /bin/false tomcat && \
    groupadd ApplicationServer && \
    usermod -aG ApplicationServer tomcat && \
    usermod -aG ApplicationServer root

# Set permissions
RUN chmod -R 775 /usr/java /usr/appserver /opt/appdata && \
    chown -R root:root /usr/appserver /opt/appdata

# Cleanup
RUN rm -rf /opt/${JDK_ZIP} /opt/tomcat.zip

# Expose ports
EXPOSE 22 25 8080

# Symlink catalina.out to stdout so Docker logs capture Tomcat logs
RUN ln -sf  /opt/appdata/logs/tomcatlogs/catalina.out

# Start Tomcat
CMD /usr/appserver/tomcat/bin/catalina.sh start; sleep inf  & \
    tail -f /opt/appdata/logs/tomcatlogs/catalina.out
