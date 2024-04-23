FROM centos:centos7
MAINTAINER Sagar Naik

# Install ssh server.
RUN yum install -y which openssh-clients openssh-server
RUN ssh-keygen -f /etc/ssh/ssh_host_rsa_key
RUN ssh-keygen -t dsa -f /etc/ssh/ssh_host_dsa_key
RUN sed -i '/pam_loginuid.so/c session    optional     pam_loginuid.so'  /etc/pam.d/sshd



# Add user
RUN useradd user1 -p iamuser1

# Install system tools and libraries.
#RUN yum -y install glibc.i686
#RUN yum -y install libstdc++.so.6
#RUN yum -y install net-tools

# Install X Window System
# yum -y groupinstall "X Window System" "Desktop" "Fonts" "General Purpose Desktop"
#RUN yum -y groupinstall "X Window System" "Fonts"

# Install other tools.
#RUN yum -y install xterm
#RUN yum -y install gedit
#RUN yum -y install gvim
#RUN yum -y install okular

RUN yum -y install vim

#------------------------------------------------------------------------

# Copy the hardening script to the container
COPY script.sh /opt/script.sh
 
# Make the hardening script executable
RUN chmod 775 /opt/script.sh
 
# Run the hardening script
RUN /opt/script.sh


 #Create Folder structure for Project
 RUN mkdir -p /opt/appdata/logs/tomcatlogs
 RUN mkdir -p /opt/appdata/logs/vault
 RUN mkdir -p /opt/appdata/logs/crypto
 RUN mkdir -p /usr/appserver
 RUN mkdir -p /usr/java
RUN mkdir -p /usr/appserver/tomcat/webapps/dashboard
  

 #Copy folder from local machine to container
 COPY jdk1.8.0_401.zip  /opt
 COPY tomcat.zip /opt
 COPY dashboard.war  /opt

#unzip jdk and tomcat file in perticular folder 
RUN yum install unzip -y 
RUN unzip /opt/jdk1.8.0_401.zip -d  /usr/java/
RUN unzip /opt/tomcat.zip  -d /usr/appserver/
RUN unzip /opt/dashboard.war  -d /usr/appserver/tomcat/webapps/dashboard
# Install and Configuration  jdk 
RUN cd /usr/java/jdk1.8.0_401/
RUN alternatives --install /usr/bin/java java /usr/java/jdk1.8.0_401/bin/java 2
RUN alternatives --set java /usr/java/jdk1.8.0_401/bin/java
RUN alternatives --install /usr/bin/jar jar /usr/java/jdk1.8.0_401/bin/jar 2
RUN alternatives --install /usr/bin/javac javac /usr/java/jdk1.8.0_401/bin/javac 2
RUN alternatives --set jar /usr/java/jdk1.8.0_401/bin/jar
RUN alternatives --set javac /usr/java/jdk1.8.0_401/bin/javac

# user creation and add group 
RUN useradd -r -m -U -d /opt/tomcat -s /bin/false tomcat
RUN groupadd ApplicationServer
RUN usermod -aG ApplicationServer tomcat
RUN usermod -aG ApplicationServer root

#give permission and ownership to all folders

RUN chmod -R 775 /usr/java
RUN chmod -R 775 /usr/appserver 
RUN chmod -R 775 /opt/appdata
RUN chown -R root:root /usr/appserver 
RUN chown -R root:root /opt/appdata 

RUN rm -rf  /opt/jdk1.8.0_401.zip 
RUN rm -rf /opt/tomcat.zip  
RUN rm -rf /opt/dashboard.war  

# Expose settings.
EXPOSE 22 8080

#ENTRYPOINT ["/usr/sbin/sshd", "-D"]
CMD /usr/appserver/tomcat/bin/catalina.sh run



