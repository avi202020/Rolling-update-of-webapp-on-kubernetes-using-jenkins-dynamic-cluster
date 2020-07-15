FROM centos
RUN yum install sudo -y
RUN yum install net-tools -y
RUN yum install httpd -y
COPY *.html  /var/www/html/ 
EXPOSE 80
CMD ["/usr/sbin/httpd","-DFOREGROUND"] && /bin/bash 


