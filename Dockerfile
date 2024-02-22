FROM jupyterhub/jupyterhub:latest as aptupdate
RUN sed -i "s@/archive.ubuntu.com/@/mirrors.aliyun.com/@g" /etc/apt/sources.list && \
apt-get clean && \
apt update
# && \
#apt upgrade -y

FROM aptupdate as installcuda
RUN apt install -y nvidia-cuda-toolkit

FROM installcuda as installpip
RUN pip3 config set global.index-url http://mirrors.aliyun.com/pypi/simple && \
pip3 config set install.trusted-host mirrors.aliyun.com && \
python3 -m pip install --upgrade pip

FROM installpip as pythonlibs
RUN pip install --no-cache-dir --default-timeout=100 tensorflow torch torchvision torchaudio
# -i https://pypi.tuna.tsinghua.edu.cn/simple 
RUN pip install --no-cache-dir jupyterlab dockerspawner ipykernel \
numpy matplotlib pillow scikit-learn requests jieba beautifulsoup4 \
pandas sympy transformers huggingface deepspeed accelerate bitsandbytes 

FROM pythonlibs
RUN pip install --no-cache-dir python-lsp-server python-language-server ipywidgets
RUN apt install -y git subversion

VOLUME [ "/work" ]
WORKDIR /app
EXPOSE 8000
COPY jupyterhub_config.py .
COPY userinit.sh .

ARG CONDA_INSTALL_SCRIPT=InstallAnaconda.sh
ADD https://repo.anaconda.com/archive/Anaconda3-2023.09-0-Linux-x86_64.sh ./${CONDA_INSTALL_SCRIPT}
RUN chmod +x *.sh
RUN bash ${CONDA_INSTALL_SCRIPT} -b && rm ${CONDA_INSTALL_SCRIPT}

CMD jupyterhub
