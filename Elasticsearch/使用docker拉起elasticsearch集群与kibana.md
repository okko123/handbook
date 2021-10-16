## 使用docker拉起elasticsearch集群与kibana
- es集群规模：
  - 为3个master节点
  - 3个data节点
  - 1个kibana节点
- kibana镜像中，环境变量
- 配置docker-compose配置文件
  ```bash
  mkdir -p /data/{es01,es02,es03,es04,es05,es05}
  chown -R 1000.1000 /data/{es01,es02,es03,es04,es05,es05}

  cat > es-docker-compose.yml <<EOF
  version: '3'
  services:
    es01:
      image: elasticsearch:6.4.3
      container_name: es01
      restart: always
      environment:
        - node.name=es01
        - cluster.name=stage-docker-cluster
        - bootstrap.memory_lock=true
        - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
        - "discovery.zen.ping.unicast.hosts=es01,es02,es03"
        - node.data=false
        - node.master=true
      ulimits:
        memlock:
          soft: -1
          hard: -1
      volumes:
        - /data/es01:/usr/share/elasticsearch/data
      ports:
        - 9200:9200
        - 9300:9300
      networks:
        - elastic
    es02:
      image: elasticsearch:6.4.3
      container_name: es02
      restart: always
      environment:
        - node.name=es02
        - cluster.name=stage-docker-cluster
        - bootstrap.memory_lock=true
        - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
        - "discovery.zen.ping.unicast.hosts=es01,es02,es03"
        - node.data=false
        - node.master=true
      ulimits:
        memlock:
          soft: -1
          hard: -1
      volumes:
        - /data/es02:/usr/share/elasticsearch/data
      ports:
        - 9202:9200
        - 9302:9300
      networks:
        - elastic
    es03:
      image: elasticsearch:6.4.3
      container_name: es03
      restart: always
      environment:
        - node.name=es03
        - cluster.name=stage-docker-cluster
        - bootstrap.memory_lock=true
        - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
        - "discovery.zen.ping.unicast.hosts=es01,es02,es03"
        - node.data=false
        - node.master=true
      ulimits:
        memlock:
          soft: -1
          hard: -1
      volumes:
        - /data/es03:/usr/share/elasticsearch/data
      ports:
        - 9203:9200
        - 9303:9300
      networks:
        - elastic
    es04:
      image: elasticsearch:6.4.3
      container_name: es04
      restart: always
      environment:
        - node.name=es04
        - cluster.name=stage-docker-cluster
        - bootstrap.memory_lock=true
        - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
        - "discovery.zen.ping.unicast.hosts=es01,es02,es03"
        - node.data=true
        - node.master=false
      ulimits:
        memlock:
          soft: -1
          hard: -1
      volumes:
        - /data/es04:/usr/share/elasticsearch/data
      networks:
        - elastic
    es05:
      image: elasticsearch:6.4.3
      container_name: es05
      restart: always
      environment:
        - node.name=es05
        - cluster.name=stage-docker-cluster
        - bootstrap.memory_lock=true
        - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
        - "discovery.zen.ping.unicast.hosts=es01,es02,es03"
        - node.data=true
        - node.master=false
      ulimits:
        memlock:
          soft: -1
          hard: -1
      volumes:
        - /data/es05:/usr/share/elasticsearch/data
      networks:
        - elastic
    es06:
      image: elasticsearch:6.4.3
      container_name: es06
      restart: always
      environment:
        - node.name=es06
        - cluster.name=stage-docker-cluster
        - bootstrap.memory_lock=true
        - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
        - "discovery.zen.ping.unicast.hosts=es01,es02,es03"
        - node.data=true
        - node.master=false
      ulimits:
        memlock:
          soft: -1
          hard: -1
      volumes:
        - /data/es06:/usr/share/elasticsearch/data
      networks:
        - elastic
    kibana:
      image: kibana:6.4.3
      container_name: kibana
      restart: always
      environment:
        - ELASTICSEARCH_URL="http://es01:9200"
      ports:
        - 5601:5601
      networks:
        - elastic
  networks:
    elastic:
      driver: bridge
  EOF
  
  #使用docker-compose启动
  docker-compose -f es-docker-compose.yml up -d
  ```
---
[Docker 容器中运行 Kibana](https://www.elastic.co/guide/cn/kibana/current/docker.html)