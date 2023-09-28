FROM fedora:38

RUN yum update -y && dnf -y groupinstall 'Development Tools'

RUN dnf -y install vim bash-completion bzip2 gcc gcc-c++ git make ncurses-devel patch \
    rsync tar unzip wget which diffutils python2 python3 perl-base \
    perl-Data-Dumper perl-File-Compare perl-File-Copy perl-FindBin \
    perl-Thread-Queue hostname perl-IPC-Cmd swig ccache-swig && \
    dnf install -y clang llvm gcc libbpf-devel libxdp-devel xdp-tools \
    bpftool kernel-headers elfutils-libelf-devel zlib-devel libpcap-devel \
    m4 wireshark-cli python3-netifaces python3-unidecode \
    python3-sqlparse python3-aiosignal python3-charset-normalizer python3-frozenlist \
    python3-networkx luajit2.1-luv luajit2.1-luv-devel && dnf clean all

RUN useradd -m user && \
    echo 'user ALL=NOPASSWD: ALL' > /etc/sudoers.d/user ; \
    echo 'export PS1="[\u@\h \W]\$ "' >> .bashrc

USER user
WORKDIR /home/user

# set dummy git config
RUN /usr/bin/git config --global user.email "you@example.com" ; \
    /usr/bin/git config --global user.name "Your Name" ; \
    echo 'export PS1="[\u@\h \W]\$ "' >> .bashrc
