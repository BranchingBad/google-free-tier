apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello-gke-deployment
spec:
  replicas: 2 # Run two instances of our application
  selector:
    matchLabels:
      app: hello-gke
  template:
    metadata:
      labels:
        app: hello-gke
    spec:
      containers:
      - name: hello-gke-container
        image: ${image}
        ports:
        - containerPort: 8080
