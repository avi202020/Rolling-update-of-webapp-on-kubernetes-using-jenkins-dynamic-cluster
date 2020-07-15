FROM centos
RUN yum install sudo -y
RUN yum install net-tools -y
RUN yum install git -y
RUN yum install curl -y
RUN yum install openssh-server -y
RUN yum install openssh-clients -y
RUN yum install java -y
RUN ssh-keygen -A

RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
RUN chmod +x ./kubectl
RUN cp ./kubectl /usr/bin/
RUN mkdir /root/.kube
COPY client.key /root/.kube
COPY client.crt /root/.kube
COPY ca.crt /root/.kube
COPY config /root/.kube
COPY deployment.yml /root 
CMD ["/usr/sbin/sshd","-D"] && /bin/bash 


