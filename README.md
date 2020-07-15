# Continuous-deployment-of-webapp-on-kubernetes-using-jenkins

    sudo docker login
    sudo docker build -t surinder2000/web-app:latest .
    sudo docker push surinder2000/web-app:latest
    
    
    if kubectl get deploy | grep myweb-deploy
    then
    kubectl set image deploy/myweb-deploy web-con=surinder2000/web-app:latest
    kubectl rollout restart deploy/myweb-deploy
    else
    kubectl apply -f /root/deployment.yml
    kubectl expose deploy/myweb-deploy --port 80 --type=NodePort
    fi
