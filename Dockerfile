FROM fedora:36

RUN yum update -y

RUN dnf -y groupinstall 'Development Tools'

RUN dnf -y install bash-completion bzip2 gcc gcc-c++ git make ncurses-devel patch \
    rsync tar unzip wget which diffutils python2 python3 perl-base \
    perl-Data-Dumper perl-File-Compare perl-File-Copy perl-FindBin \
    perl-Thread-Queue vim hostname && \
    yum clean all

RUN useradd -m user && \
    echo 'user ALL=NOPASSWD: ALL' > /etc/sudoers.d/user

USER user
WORKDIR /home/user

# set dummy git config
RUN /usr/bin/git config --global user.email "you@example.com" ; \
    /usr/bin/git config --global user.name "Your Name"
