FROM jupyterhub/jupyterhub:latest as aptupdate
RUN sed -i "s@/archive.ubuntu.com/@/mirrors.aliyun.com/@g" /etc/apt/sources.list && \
apt-get clean && \
apt update
# && \
#apt upgrade -y

FROM aptupdate as installcuda
#RUN apt install -y nvidia-cuda-toolkit
WORKDIR /build
ADD https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb /build
ADD https://developer.nvidia.com/downloads/compute/machine-learning/tensorrt/secure/8.6.1/local_repos/nv-tensorrt-local-repo-ubuntu2204-8.6.1-cuda-12.0_1.0-1_amd64.deb /build
RUN dpkg -i /build/cuda-keyring_1.1-1_all.deb && \
apt-get update && \
apt-get -y install cuda cudnn && \
dpkg -i /build/nv-tensorrt-local-repo-ubuntu2204-8.6.1-cuda-12.0_1.0-1_amd64.deb && \
rm -rf /build

FROM installcuda as installpip

ARG PIP_MIRRORS="https://pypi.tuna.tsinghua.edu.cn/simple \
https://mirrors.cloud.tencent.com/pypi/simple \
https://mirrors.163.com/pypi/simple/ \
https://pypi.douban.com/simple/ \
https://mirror.baidu.com/pypi/simple/ \
https://pypi.mirrors.ustc.edu.cn/simple/ \
#https://mirrors.huaweicloud.com/repository/pypi/simple/ \
"
RUN pip3 config set global.index-url http://mirrors.aliyun.com/pypi/simple && \
pip config set global.extra-index-url "${PIP_MIRRORS}" && \
pip3 config set install.trusted-host mirrors.aliyun.com && \
python3 -m pip install --upgrade pip

FROM installpip as pythonlibs
RUN pip install --default-timeout=100 --retries 10 tensorflow torch torchvision torchaudio keras
# -i https://pypi.tuna.tsinghua.edu.cn/simple 
RUN pip install  jupyterlab dockerspawner ipykernel  \
numpy matplotlib pillow scikit-learn requests jieba beautifulsoup4 \
pandas sympy transformers huggingface deepspeed accelerate bitsandbytes opencv-python
#RUN apt-get install -y python3-dev
#RUN pip install  pycuda tensorrt

FROM pythonlibs
RUN pip install  python-lsp-server python-language-server ipywidgets
RUN apt install -y git subversion

VOLUME [ "/work" ]
WORKDIR /app
EXPOSE 8000


RUN apt-get install -y vim wget curl tar zip rar p7zip-full p7zip-rar psmisc && \
apt-get autoclean && \
rm -rf /var/lib/apt/lists/*

ENV CUDA_HOME /usr/local/cuda
ENV LD_LIBRARY_PATH $LD_LIBRARY_PATH:/usr/local/cuda/lib64
#RUN python3 -m pip install tensorrt

ARG CONDA_PATH=/opt/conda
ARG CONDA_INSTALL_SCRIPT=InstallAnaconda.sh
ENV PATH ${CONDA_PATH}/bin:/usr/local/cuda:$PATH
ADD https://repo.anaconda.com/archive/Anaconda3-2023.09-0-Linux-x86_64.sh ./${CONDA_INSTALL_SCRIPT}
RUN chmod +x *.sh
RUN bash ${CONDA_INSTALL_SCRIPT} -b -p ${CONDA_PATH} && rm ${CONDA_INSTALL_SCRIPT} && \
conda config --add channels https://mirrors.bfsu.edu.cn/anaconda/pkgs/free/ && \
conda config --add channels https://mirrors.bfsu.edu.cn/anaconda/pkgs/main/ && \
conda config --add channels https://mirrors.bfsu.edu.cn/anaconda/cloud/conda-forge/ && \
conda config --add channels https://mirrors.bfsu.edu.cn/anaconda/cloud/msys2/ && \
conda config --add channels https://mirrors.bfsu.edu.cn/anaconda/cloud/bioconda/ && \
conda config --add channels https://mirrors.bfsu.edu.cn/anaconda/cloud/menpo/ && \
conda config --add channels https://mirrors.bfsu.edu.cn/anaconda/cloud/pytorch/ && \
conda config --add channels https://mirrors.bfsu.edu.cn/anaconda/cloud/peterjc123/ && \
conda config --set show_channel_urls yes && \
#RUN conda update -n base -c defaults conda -y
conda install defaults::conda-libmamba-solver && \
conda install conda-forge::conda-libmamba-solver && \
conda install conda-canary/label/dev::conda-libmamba-solver && \
echo -e "envs_dirs:\n  - /opt/conda/envs\n  - ~/.conda/envs" >> ${CONDA_PATH}/.condarc && \
groupadd conda && \
chgrp -R conda ${CONDA_PATH} && \
chmod 770 -R ${CONDA_PATH} && \
chmod g+s ${CONDA_PATH} && \
#chmod g+s `find ${CONDA_PATH} -type d` && \
find ${CONDA_PATH} -type d -exec chmod g+s {} + && \
chmod g-w ${CONDA_PATH}/envs

COPY UserReadMe.md .
COPY jupyterhub_config.py .
COPY userinit.sh .

SHELL ["/bin/bash", "-l", "-c"]
CMD jupyterhub
