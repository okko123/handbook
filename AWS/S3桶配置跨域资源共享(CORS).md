## S3桶配置跨域资源共享(CORS)
1. 登录 AWS 管理控制台并通过以下网址打开 Amazon S3 控制台：https://console.aws.amazon.com/s3/
2. 在 Bucket name 列表中，选择要为其创建存储桶策略的存储桶的名称。
3. 选择 Permissions，然后选择 CORS configuration。
4. 在 CORS configuration editor 文本框中，键入或复制并粘贴新的 CORS 配置，或者编辑现有配置。CORS 配置是一个 XML 文件。您在编辑器中键入的文本必须是有效的 XML。
5. 选择Save。
- 第一个规则允许来自 http://www.example1.com 源的跨源 PUT、POST 和 DELETE 请求。该规则还通过 Access-Control-Request-Headers 标头允许预检 OPTIONS 请求中的所有标头。作为对预检 OPTIONS 请求的响应，Amazon S3 将返回请求的标头。
- 第二个规则允许与第一个规则具有相同的跨源请求，但第二个规则应用于另一个源 http://www.example2.com。
- 第三个规则允许来自所有源的跨源 GET 请求。* 通配符将引用所有源。
  ```xml
  <CORSConfiguration>
   <CORSRule>
     <AllowedOrigin>http://www.example1.com</AllowedOrigin>
  
     <AllowedMethod>PUT</AllowedMethod>
     <AllowedMethod>POST</AllowedMethod>
     <AllowedMethod>DELETE</AllowedMethod>
  
     <AllowedHeader>*</AllowedHeader>
   </CORSRule>
   <CORSRule>
     <AllowedOrigin>http://www.example2.com</AllowedOrigin>
  
     <AllowedMethod>PUT</AllowedMethod>
     <AllowedMethod>POST</AllowedMethod>
     <AllowedMethod>DELETE</AllowedMethod>
  
     <AllowedHeader>*</AllowedHeader>
   </CORSRule>
   <CORSRule>
     <AllowedOrigin>*</AllowedOrigin>
     <AllowedMethod>GET</AllowedMethod>
   </CORSRule>
  </CORSConfiguration>
  ```

  ## 参考链接
  - [S3配置](https://docs.aws.amazon.com/zh_cn/AmazonS3/latest/user-guide/add-cors-configuration.html)
  - [S3的CORS配置解释](https://docs.aws.amazon.com/zh_cn/AmazonS3/latest/dev/cors.html#how-do-i-enable-cors)