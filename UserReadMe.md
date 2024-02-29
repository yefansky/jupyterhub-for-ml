## 环境使用说明

基础环境已经安装了tensorflow pytorch， python3.10 和一些常备的深度学习库
但因为一些特殊需求需要装新的软件包，怕影响到基础环境，需要搞自己的虚拟环境，
请使用一下指令

### 新建环境
``` bash
conda create --name tf python=3.11 tensorflow ipykernel
python -m ipykernel install --user --name tf --display-name "tensorflow"
```
重新登陆jupyterlab就可以看到多了一种环境类型

### 在命令行中切换环境
原来的 conda activate envname 被官方废弃了，可以使用以下指令
``` bash
source activate envname
```

### 退出环境还是老的
``` bash
conda deactivate envname
```

