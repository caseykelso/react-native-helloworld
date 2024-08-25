# react-native-helloworld - boostrap an ios or android react-native project in 5 minutes.

# How-To

# Fork this project as a baseline for your new app.

# Setup Ubuntu 24.04 Environment
```bash
sudo apt-get install git npm exuberant-ctags xclip ideviceinstaller  openjdk-17-jdk
update-java-alternatives --list
sudo update-java-alternatives  --set /usr/lib/jvm/java-1.17.0-openjdk-amd64
```

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.4/install.sh | bash
```


# Build for IOS
```bash
make bootstrap
make create.project
make ci.ios
```

# Build for Android
```bash
make bootstrap
make create.project
make ci.ios
```


