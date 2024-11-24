FROM fedora:41

RUN yum update -y && dnf -y group install development-tools

RUN dnf -y install vim bash-completion file bzip2 gcc gcc-c++ git make ncurses-devel patch \
    rsync tar unzip wget which diffutils python3 glibc-gconv-extra perl-base \
    perl-Data-Dumper perl-File-Compare perl-File-Copy perl-FindBin \
    perl-Thread-Queue hostname perl-IPC-Cmd swig ccache-swig && \
    dnf install -y clang llvm gcc libbpf-devel libxdp-devel xdp-tools \
    bpftool kernel-headers elfutils-libelf-devel zlib-devel libpcap-devel \
    m4 wireshark-cli python3-netifaces python3-unidecode \
    python3-sqlparse python3-aiosignal python3-charset-normalizer python3-frozenlist \
    python3-networkx python3-setuptools luajit2.1-luv libnghttp2-devel \
    perl-Time-Piece perl-Test-CPAN-Meta-JSON net-snmp-libs \
    e2fsprogs-libs pam-devel gcc-g++ cmake glibc-static libstdc++-static util-linux \
    libstdc++-static && dnf clean all

# To build BPI-R4-MT76-OPENWRT-V21.02
RUN dnf install -y usbutils bison flex openssl-devel \
    jsoncpp-devel json-devel cjson-devel && dnf clean all

RUN ln -s /usr/lib64/$(ls /usr/lib64/ | grep libbz2 | sort -r | head -n1) /usr/lib64/libbz2.so.1.0 || true ; \
    ln -s /usr/lib64/$(ls /usr/lib64/ | grep libbz2 | sort -r | head -n1) /usr/lib64/libbz2.so.1 || true

RUN echo 'export PS1="[\u@\h \W]\$ "' >> /etc/skel/.bashrc ; \
    useradd -rm -d /home/user -s /bin/bash -k /etc/skel user ; \
    echo 'user ALL=NOPASSWD: ALL' > /etc/sudoers.d/user ;

USER user
WORKDIR /home/user

# set dummy git config
RUN /usr/bin/git config --global user.email "you@example.com" ; \
    /usr/bin/git config --global user.name "Your Name" ; \
    /usr/bin/git config --global pull.rebase true
