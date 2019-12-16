# 使用索引生命周期管理实现热温冷架构
* Elasticsearch: 7.3
## 配置分片分配感知
由于热温冷依赖于分片分配感知，因此，我们首先标记哪些节点是热节点、温节点和（可选）冷节点。此操作可以通过启动参数或在 elasticsearch.yml 配置文件中完成。例如：
```bash
bin/elasticsearch -Enode.attr.data=hot
bin/elasticsearch -Enode.attr.data=warm
bin/elasticsearch -Enode.attr.data=cold
```
## 配置 ILM 策略
接下来，我们需要定义一个 ILM 策略。ILM 策略可以在您选择的任意多个索引中重用。ILM 策略分为四个主要阶段 - 热、温、冷和删除。您不需要在一个策略中定义每个阶段，ILM 会始终按该顺序执行各个阶段（跳过任何未定义的阶段）。对于每个阶段，您都需要定义进入该阶段的时间，还需要定义一组操作来按照您认为合适的方式管理索引。对于热温冷架构，您可以配置分配操作，将数据从热节点移动到温节点，继而再从温节点移动到冷节点。

除了在热温冷节点之间移动数据外，您还可以配置许多附加操作。滚动更新操作用于管理每个索引的大小或寿命。强制合并操作可用于优化索引。冻结操作可用于减少集群中的内存压力。此外，还有许多其他操作；请参考适用于您的 Elasticsearch 版本的文档，以了解可供使用的操作。
## 基本 ILM 策略
下面我们来看一个非常基本的 ILM 策略：这个策略规定，在索引存储时间达到 30 天后或者索引大小达到 50GB（基于主分片）时，就会滚动更新该索引并开始写入一个新索引。
```json
PUT /_ilm/policy/my_policy
{
  "policy":{
    "phases":{
      "hot":{
        "actions":{
          "rollover":{
            "max_size":"50gb",
            "max_age":"30d"
          }
        }
      }
    }
  }
}
```
## ILM 和索引模板
接下来，我们需要将这个 ILM 策略与索引模板关联起来：注意：当使用滚动更新操作在索引模板中（而不是直接在索引上）指定 ILM 策略时，必需进行此关联。对于包括滚动更新操作的策略，您还必须在创建索引模板后使用写入别名启动索引。假设进行滚动更新的所有要求均得到正确满足，任何以 test-* 开头的新索引将在 30 天后或达到 50GB 时自动滚动更新。通过使用滚动更新管理以 max_size 开头的索引后，可以极大减少索引的分片数量，进而减少开销。
```json
PUT _template/my_template
{
  "index_patterns": ["test-*"],
  "settings": {
    "index.lifecycle.name": "my_policy",
    "index.lifecycle.rollover_alias": "test-alias"
  }
}

PUT test-000001
{
  "aliases": {
    "test-alias":{
      "is_write_index": true
    }
  }
}
```
---

## 针对热温冷优化 ILM 策略
首先，让我们创建一个针对热温冷架构优化的 ILM 策略。再次强调，这不是一刀切的设置，您的要求将有所不同。
1. 热：这个 ILM 策略首先会将索引优先级设置为一个较高的值，以便热索引在其他索引之前恢复。30 天后或达到 50GB 时（符合任何一个即可），该索引将滚动更新，系统将创建一个新索引。该新索引将重新启动策略，而当前的索引（刚刚滚动更新的索引）将在滚动更新后等待 7 天再进入温阶段。
2. 温：索引进入温阶段后，ILM 会将索引收缩到 1 个分片，将索引强制合并为 1 个段，并将索引优先级设置为比热阶段低（但比冷阶段高）的值，通过分配操作将索引移动到温节点。完成该操作后，索引将等待 30 天（从滚动更新时算起）后进入冷阶段。
3. 冷：索引进入冷阶段后，ILM 将再次降低索引优先级，以确保热索引和温索引得到先行恢复。然后，ILM 将冻结索引并将其移动到冷节点。完成该操作后，索引将等待 60 天（从滚动更新时算起）后进入删除阶段。
4. 删除：我们还没有讨论过这个删除阶段。简单来说，删除阶段具有用于删除索引的删除操作。在删除阶段，您将始终需要有一个 min_age 条件，以允许索引在给定时段内待在热、温或冷阶段。
```json
PUT _ilm/policy/hot-warm-cold-delete-60days
{
  "policy": {
    "phases": {
      "hot": {
        "actions": {
          "rollover": {
            "max_size":"50gb",
            "max_age":"30d"
          },
          "set_priority": {
            "priority":50
          }
        }
      },
      "warm": {
        "min_age":"7d",
        "actions": {
          "forcemerge": {
            "max_num_segments":1
          },
          "shrink": {
            "number_of_shards":1
          },
          "allocate": {
            "require": {
              "data": "warm"
            }
          },
          "set_priority": {
            "priority":25
          }
        }
      },
      "cold": {
        "min_age":"30d",
        "actions": {
          "set_priority": {
            "priority":0
          },
          "freeze": {},
          "allocate": {
            "require": {
              "data": "cold"
            }
          }
        }
      },
      "delete": {
        "min_age":"60d",
        "actions": {
          "delete": {}
        }
      }
    }
  }
}
```
---
## 参考连接
1. [官方博客，使用索引生命周期管理实现热温冷架构](https://www.elastic.co/cn/blog/implementing-hot-warm-cold-in-elasticsearch-with-index-lifecycle-management)
2. [官方硬件配置建议](https://www.elastic.co/guide/en/cloud/current/ec-getting-started-templates-hot-warm.html)