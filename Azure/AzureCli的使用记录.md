## 创建虚拟机，（注意，当虚拟机与VNet分属于不通的资源组时，subnet需要使用subnet的ID，创建出来的虚拟机才能落到指定的subnet中）
* az vm create \
  --admin-username azureuser \
  --authentication-type ssh \
  --size Standard_B2ms \
  --vnet-name vnet-01 \
  --subnet public-01 \
  --resource-group "resource-group" \
  --name "myVM03" \
  --image "UbuntuLTS" \
  --ssh-key-values authorized_keys_file \
  --public-ip-address ""
## 查询Azure区域名称
* az account list-locations
## 查询机型的名称
* az vm list-sizes --location Location
## 查询子网ID
* az network vnet subnet show --resource-group resource_group_name --vnet-name vnet_name --name subnet_name -o tsv --query id
## 查询CentOS镜像
* az vm image list -f CentOS
* az vm image list -l  westeurope -f CentOS -p OpenLogic --sku 7.6 --all
## 查询磁盘信息；是否挂载、磁盘的类型、区域、名称
* az disk list --query '[].{State:diskState,Location:location,Name:name,SKU:sku.name}' -o table
---
## 参考资料
* [Query配置参数](https://docs.microsoft.com/zh-cn/cli/azure/query-azure-cli?view=azure-cli-latest)