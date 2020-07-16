# Continuous deployment of webapp on Kubernetes using Jenkins
In this article i am going to create an environment for continuous deployment of the web app on top of Kubernetes with zero down time using rolling updates strategy of Kubernetes with Jenkins. Configuring dynamic distributive cluster in Jenkins for deploying the web app on Kubernetes using Jenkins slave node

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
    
![Docker configuration1](https://github.com/surinder2000/Continuous-deployment-of-webapp-on-kubernetes-using-jenkins/blob/master/Screenshots/dockerconf1.png)

* Add the tcp protocol with available port number in it

![Docker configuration2](https://github.com/surinder2000/Continuous-deployment-of-webapp-on-kubernetes-using-jenkins/blob/master/Screenshots/dockerconf2.png)

* After adding tcp protocol reload daemon and restart the docker service, to do it use the following commands
    
      systemctl daemon-reload
      systemctl restart docker
   

### Install the required plugins for creating dynamic distributive cluster
To install plugins go to **Manage Jenkins -> Manage Plugins** click on available, search the required plugins and install them. Must install the following plugins
* Docker 
* Yet Another Docker

### Configure dynamic distributive cluster in Jenkins by using Docker 
* Go to **Manage Jenkins -> Manage clouds and nodes -> Configure clouds** and click on Add a new cloud and fill the following details

![Agent configuration1](https://github.com/surinder2000/Continuous-deployment-of-webapp-on-kubernetes-using-jenkins/blob/master/Screenshots/agentconf1.png)


* Fill the following in Docker agent template and use the Docker images that is created above

![Agent configuration2](https://github.com/surinder2000/Continuous-deployment-of-webapp-on-kubernetes-using-jenkins/blob/master/Screenshots/agentconf2.png)
![Agent configuration3](https://github.com/surinder2000/Continuous-deployment-of-webapp-on-kubernetes-using-jenkins/blob/master/Screenshots/agentconf3.png)


 ### Create a Dockerfile that creates a container image of apache web server and copy the web pages from current workspace in container image inside the working directory of apache web server
 
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

In Source Control Management section put the Github repository url and branch name

![Git configuration](https://github.com/surinder2000/Continuous-deployment-of-webapp-on-kubernetes-using-jenkins/blob/master/Screenshots/job11.png)

In Build trigger section select Poll SCM for checking the github repository every minute

![Build trigger](https://github.com/surinder2000/Continuous-deployment-of-webapp-on-kubernetes-using-jenkins/blob/master/Screenshots/job12.png)

In the Build section from Add build step select Execute shell and put the following code in the command box

    sudo docker login
    sudo docker build -t surinder2000/web-app:latest .
    sudo docker push surinder2000/web-app:latest
    
![Execute shell](https://github.com/surinder2000/Continuous-deployment-of-webapp-on-kubernetes-using-jenkins/blob/master/Screenshots/job13.png)
    
#### Job 2: Launch the web app on top of Kubernetes and do the following
* If launching the web app first time create deployment using the images created in the previous job
* Expose the application
* If the application already deployed then do roll out of existing pods making zero downtime for users

In General section Restrict the job to run on dynamic slave node by putting the dynamic cluster label in the Label expression box

![Restrict job](https://github.com/surinder2000/Continuous-deployment-of-webapp-on-kubernetes-using-jenkins/blob/master/Screenshots/job21.png)


In Build trigger section select Build after other projects are built and put the name of Job 1 in the Project to watch box and check Trigger only if build is stable

![Build trigger](https://github.com/surinder2000/Continuous-deployment-of-webapp-on-kubernetes-using-jenkins/blob/master/Screenshots/job22.png)


In the Build section from Add build step select Execute shell and put the following code in the command box


    if kubectl get deploy | grep myweb-deploy
    then
    kubectl set image deploy/myweb-deploy web-con=surinder2000/web-app:latest
    kubectl rollout restart deploy/myweb-deploy
    else
    kubectl apply -f /root/deployment.yml
    kubectl expose deploy/myweb-deploy --port 80 --type=NodePort
    fi

![Execute shell](https://github.com/surinder2000/Continuous-deployment-of-webapp-on-kubernetes-using-jenkins/blob/master/Screenshots/job23.png)

That's all our setup is ready

Now as soon as the developer commit new code in the github repository, it will get automatically pulled from github by jenkins job and one container image is created in which the new code get copied and the created image pushed into the Docker hub. On success of job 1, job 2 trigger and deploy the web app with the image created in the previous job on top of Kubernetes and expose it to outside world. If already deployed then roll out the exiting pods using rolling update strategy of Kubernetes which provides zero downtime of web app in the production environment.

This is the Build pipeline view of the Jenkins jobs


![Pipeline view](https://github.com/surinder2000/Continuous-deployment-of-webapp-on-kubernetes-using-jenkins/blob/master/Screenshots/pipelineview.png)


### Thank you
