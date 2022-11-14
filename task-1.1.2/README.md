# InternDevOpsEngineer

This is repository for studying on Intern DevOps Engineer course in Itransition.

# Installing software

Because I'm prefer to use podman as compatible replacement of docker, I installed it by:

- sudo dnf install -y podman podman-compose
- echo "alias docker='podman'" >> ~/.bashrc
- echo "alias docker-compose='podman-compose'" >> ~/.bashrc

# Doing the first sub task:
- docker build . -t ruby:2.7.2
- docker run --name ubuntu localhost/ruby:2.7.2 ruby -v
```
ruby 2.7.2p137 (2020-10-01 revision 5445e04352) [x86_64-linux]
```