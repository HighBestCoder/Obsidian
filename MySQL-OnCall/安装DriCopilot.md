1. 安装anaconda
2. git clone msdata@vs-ssh.visualstudio.com:v3/msdata/Database%20Systems/DRICopilot
3. ![[Pasted image 20240513144353.png]]然后
```
pip install --upgrade -r requirements.txt
git checkout  rel/20240410
cd src/deployment/config
cp -rf template.py config_mysql.py
```

然后`config_mysql.py`

首先设置region

```
# Chose the location of your copilot.

# If you plan to deploy a new Open AI workspace, this needs to be in a region with GPT4 enabled.

# Typically, East us is a good choice.

location = "canadaeast"
```

# User object ID

```
# This is the id of YOUR identity.

# You can find it by looking at yourself on Microsoft Intra ID on the Azure portal.

# IMPORTANT: this is the object id of your identity.

# EXAMPLE: e0976b19-655c-421d-8043-f77989a894db

deployment_identity_principal_id = ""
```

![[Pasted image 20240513144803.png]]