# Continuous deployment of webapp on Kubernetes using Jenkins
In this article i am going to create an environment for continuous deployment of the web app on top of Kubernetes with zero down time using rolling updates strategy of Kubernetes with Jenkins. The dynamic distributive cluster is created in Jenkins for the deployment of the web app on Kubernetes

## Pre-requisites
* Must have minikube installed
* Must have Jenkin running. Run Jenkins either on base system or on top of docker container

## Let's see the step by step process
### Create one yaml file for deployment of web app on Kubernetes
Put the following code in the yaml file for creating deployment of web app on Kubernetes
  
    apiVersion: apps/v1
    kind: Deployment
    metadata:
        name: myweb-deploy
        labels:
            app: myweb 
    spec:
        replicas: 3
        selector:
            matchLabels:
                app: myweb 
        template:
            metadata:
                labels:
                    app: myweb 
            spec:
                containers:
                 -  name: web-con
                    image: surinder2000/web-app:latest
                    ports:
                     -  containerPort: 80
                    imagePullPolicy: Always
                    

While creating container image copy this deployment file inside container image

### Create config file for configuring kubectl inside container
Put the following lines inside config file for configuration of kubectl inside container

    apiVersion: v1
    kind: Config

    clusters:
    - cluster:
        server: https://192.168.99.110:8443
        certificate-authority: ca.crt
      name: mycluster

    contexts:
    - context:
        cluster: mycluster
        user: surinder

    users:
    - name: surinder
      user:
        client-key: client.key
        client-certificate: client.crt


While creating container image copy this config file with other key certificate files that are used in it inside container image 

### Create container image using Dockerfile that has kubectl configured and other basic configuration to run slave node in Jenkins
Put the following set of commands in Dockerfile for creating the required container image

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


Run the following command to build an image

    docker build -t image_name:tag
    
### Configure docker server so that any docker client can access it
* Go to docker service file
* To get path of docker service file run the following command

    systemctl status docker
    
    
* Add tcp protocol in it 

### Install the required plugins for creating dynamic distributive cluster
To install plugins got to **Manage Jenkins -> Manage Plugins** click on available, search the required plugins and install them. Must install the following plugins
* Docker 
* Yet Another Docker

### Configure dynamic distributive cluster in Jenkins by using Docker 
* Go to **Manage Jenkins -> Manage clouds and nodes -> Configure clouds** and click on Add a new cloud and fill the following details

* Fill the following in Docker agent template and use the Docker images that is created above



 ### Create a Dockerfile that create container image of apache web server and copy the web pages from current workspace in container image inside the working directory of apache web server
 
    FROM centos
    RUN yum install sudo -y
    RUN yum install net-tools -y
    RUN yum install httpd -y
    COPY *.html  /var/www/html/ 
    EXPOSE 80
    CMD ["/usr/sbin/httpd","-DFOREGROUND"] && /bin/bash 


### Create Jenkins jobs for the continuous deployment of web app on Kubernetes using rolling update stategy of Kubernetes
#### Job1: Pull the code from Github repository when developer push the code and do the following
* Create a container image of apache web server and copy the web pages from current workspace
* Push the image into the Docker hub
    
    sudo docker login
    sudo docker build -t surinder2000/web-app:latest .
    sudo docker push surinder2000/web-app:latest
    
#### Job 2: Launch the web app on top of Kubernetes and do the following
* If launching the web app first time create deployment using the images created in the previous job
* Expose the application
* If the application already deployed then do roll out of existing pods making zero downtime for users
    
    if kubectl get deploy | grep myweb-deploy
    then
    kubectl set image deploy/myweb-deploy web-con=surinder2000/web-app:latest
    kubectl rollout restart deploy/myweb-deploy
    else
    kubectl apply -f /root/deployment.yml
    kubectl expose deploy/myweb-deploy --port 80 --type=NodePort
    fi


This is the pipeline view of the Jenkins jobs
