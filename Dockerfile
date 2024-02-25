FROM jupyterhub/jupyterhub:latest as aptupdate
RUN sed -i "s@/archive.ubuntu.com/@/mirrors.aliyun.com/@g" /etc/apt/sources.list && \
apt-get clean && \
apt update
# && \
#apt upgrade -y

FROM aptupdate as installcuda
#RUN apt install -y nvidia-cuda-toolkit
ADD https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb .
RUN dpkg -i cuda-keyring_1.1-1_all.deb && \
apt-get update && \
apt-get -y install cuda

FROM installcuda as installpip
RUN pip3 config set global.index-url http://mirrors.aliyun.com/pypi/simple && \
pip3 config set install.trusted-host mirrors.aliyun.com && \
python3 -m pip install --upgrade pip

FROM installpip as pythonlibs
RUN pip install --no-cache-dir --default-timeout=100 tensorflow torch torchvision torchaudio
# -i https://pypi.tuna.tsinghua.edu.cn/simple 
RUN pip install --no-cache-dir jupyterlab dockerspawner ipykernel tensorrt \
numpy matplotlib pillow scikit-learn requests jieba beautifulsoup4 \
pandas sympy transformers huggingface deepspeed accelerate bitsandbytes opencv-python

FROM pythonlibs
RUN pip install --no-cache-dir python-lsp-server python-language-server ipywidgets
RUN apt install -y git subversion

VOLUME [ "/work" ]
WORKDIR /app
EXPOSE 8000
COPY jupyterhub_config.py .
COPY userinit.sh .

RUN apt-get install -y vim wget curl sed awk grep tar zip rar p7zip-full p7zip-rar fuser; \
apt-get autoclean; \
rm -rf /var/lib/apt/lists/*

ARG CONDA_INSTALL_SCRIPT=InstallAnaconda.sh
ADD https://repo.anaconda.com/archive/Anaconda3-2023.09-0-Linux-x86_64.sh ./${CONDA_INSTALL_SCRIPT}
RUN chmod +x *.sh
RUN bash ${CONDA_INSTALL_SCRIPT} -b && rm ${CONDA_INSTALL_SCRIPT}
ENV PATH /root/anaconda3/bin:/usr/local/cuda:$PATH
ENV CODA_HOME /usr/local/cuda

RUN conda config --add channels https://mirrors.bfsu.edu.cn/anaconda/pkgs/free/ && \
conda config --add channels https://mirrors.bfsu.edu.cn/anaconda/pkgs/main/ && \
conda config --add channels https://mirrors.bfsu.edu.cn/anaconda/cloud/conda-forge/ && \
conda config --add channels https://mirrors.bfsu.edu.cn/anaconda/cloud/msys2/ && \
conda config --add channels https://mirrors.bfsu.edu.cn/anaconda/cloud/bioconda/ && \
conda config --add channels https://mirrors.bfsu.edu.cn/anaconda/cloud/menpo/ && \
conda config --add channels https://mirrors.bfsu.edu.cn/anaconda/cloud/pytorch/ && \
conda config --add channels https://mirrors.bfsu.edu.cn/anaconda/cloud/peterjc123/ && \
conda config --set show_channel_urls yes
#RUN conda update -n base -c defaults conda -y
RUN conda install defaults::conda-libmamba-solver && \
conda install conda-forge::conda-libmamba-solver && \
conda install conda-canary/label/dev::conda-libmamba-solver

SHELL ["/bin/bash", "-l", "-c"]
CMD jupyterhub
