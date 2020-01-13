range 查询可同时提供包含（inclusive）和不包含（exclusive）这两种范围表达式，可供组合的选项如下：
gt: > 大于（greater than）
lt: < 小于（less than）
gte: >= 大于或等于（greater than or equal to）
lte: <= 小于或等于（less than or equal to）

GET /nginx-proxy-2019.12.29/_search {
    "query":{
        "match":{
            "http_user_agent": "MUID"
        }
    },
    "_source": ["http_user_agent"]
}

# size指定返回的数量，from指定偏移量
GET /nginx-proxy-2019.11.30/_search?size=20&from=80 {
    "query":{
        "bool":{
            "must":[
                {
                    "match":{
                        "domain":"app.easyrentcars.com"
                    }
                },
                {
                    "match":{
                        "http_user_agent":"MUID"
                    }
                }
            ],
            "filter":{
                "range":{
                    "time_local":{
                        "gte":"30/Nov/2019:08:00:00 +0800",
                        "lte":"30/Nov/2019:08:59:59 +0800"
                    }
                }
            }
        }
    },
    "_source":"http_user_agent"
}




python elasticsearch-dsl
https://elasticsearch-dsl.readthedocs.io/en/latest/search_dsl.html
https://github.com/lujun9972/-/blob/master/Programming/Python/elasticsearch-dsl.org
https://juejin.im/post/5d346f9551882549a70ad729