# 创建虚拟机

```bash
az vm create     --name yoj-debug-mysql    --image MicrosoftCBLMariner:cbl-mariner:cbl-mariner-2:latest     --assign-identity [system]     --resource-group migration-group  --admin-username yoj   --ssh-key-values  'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDOfMy8MXU12DPRicqJLSjWsHFu5if/2XLaJMbFnZvEmZ9khDGCLgY/ENYAVbOvBYfIzdxKIoc+h6Xg8QiFv2TGPh7Jh5d+IKP7LHeGjsjsHg3ky7aL/f2ysYOd2+Rp1JbtVaF5laIHOSvwEmVK1EQ3VX3BD6xK/kp4GnEw9qRIDzH4yGck2UIy0dVaAKfm7A/6QDrXo2DRr9AciRa5zgyzHnV7N6m4cUT1Fk8LAJ6WcCxSyNCcJvnmN/zI0UEjwj+tpC8nwBsmavGYnxz3Q4sLO2yw7HfFpmXrVvXT44vNfPVV9rC7/d054czrGE/RPbgjPPGatA3za/E6L6YSCdbq6sSJXsTVnH/uZcwKShjifYZEW+o93e1MaAPGvj7mXL2/LB15HFah0B2zqOjfmKqBDPoQDXild+M/ze1Epiom+TuIWk+cJs2tm7A6FaL7JbYNoBHrC+XR2y15l588JdbdVAT9L88SpOZ+KLzNopAngxHfkW9uTU6HCQgHQ0b6Ivc= yoj@Yous-MacBook-Pro.local'  --os-disk-size-gb 16     --public-ip-sku Standard    --location northeurope --subscription 2941a09d-7bcf-42fe-91ca-1765f521c829 --size Standard_D8ds_v4
```

