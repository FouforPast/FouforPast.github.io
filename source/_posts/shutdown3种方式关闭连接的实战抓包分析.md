---
title: shutdown3种方式关闭连接的实战抓包分析
date: 2024-01-12 10:08:49
tags:
  - 计算机网络
---



<!--more-->

测试linux版本：

```shell
Linux version 5.15.133.1-microsoft-standard-WSL2 (root@1c602f52c2e4) (gcc (GCC) 11.2.0, GNU ld (GNU Binutils) 2.37) #1 SMP Thu Oct 5 21:02:42 UTC 2023
```



抓包代码如下：

`client.py`

```python
import socket

def start_client():
    client_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    client_socket.connect(('localhost', 30567))

    # Send data to the server
    message = 'Hello, server!'
    client_socket.sendall(message.encode())
    print(f'Sent data: {message}')

    print('Sleeping for 5 seconds...')
    import time
    time.sleep(5)

    message = 'Sleeping done.'
    client_socket.sendall(message.encode())
    print(f'Sent data: {message}')

    # Wait for a moment before closing
    input('Press Enter to close the client...')
    client_socket.close()

if __name__ == "__main__":
    start_client()
```

`server.py`

```python
import socket

def start_server():
    server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server_socket.bind(('localhost', 30567))
    server_socket.listen(1)

    print('Server listening on port 30567...')

    client_socket, client_address = server_socket.accept()
    print(f'Connection from {client_address}')

    # Receive data from the client
    data = client_socket.recv(1024)
    print(f'Received data: {data.decode()}')

    input('Press Enter to SHUTDOWN the server...')
    # Shutdown the reading direction
    client_socket.shutdown(socket.SHUT_RDWR)

    input('Press Enter to close the server...')

    # Wait for a moment before closing
    server_socket.close()

if __name__ == "__main__":
    start_server()
```



### 1 SHUT_WR方式

#### 1.1 被动方一方先关闭套接字

![image-20240112101552424](https://cdn.jsdelivr.net/gh/FouforPast/pic-storage@main/img/image-20240112101552424.png)



#### 1.2 主动方一方先关闭套接字

![image-20240112104145932](https://cdn.jsdelivr.net/gh/FouforPast/pic-storage@main/img/image-20240112104145932.png)

两种方式的报文发送情况是相同的。

### 2 SHUT_RD方式

#### 2.1 被动方一方先关闭套接字

![image-20240112101718310](https://cdn.jsdelivr.net/gh/FouforPast/pic-storage@main/img/image-20240112101718310.png)

#### 2.2 主动方一方先关闭套接字

![image-20240112101738379](https://cdn.jsdelivr.net/gh/FouforPast/pic-storage@main/img/image-20240112101738379.png)

两种方式的前7行是相同的，这也是二者在调用close之前的报文发送情况。注意shutdown之后尽管被动方发来了消息，但这条消息只会直接丢弃，不会回复RST报文，因为RST是无条件重置，如果对方发来一条消息就将连接重置，那己方就无法继续向对方发消息了。

根据二者调用close的顺序不同，后面的报文也出现了差异。

如果是主动方先close，不会发送FIN报文，会回复直接回复一条RST报文，其中的ack号是最后一条消息的ack。

如果是被动方close，主动方会接收到被动方的FIN报文，意识到对方想关闭这条连接，会先回复一条这个报文的ack，然后直接回复RST报文，也就是说主动方连被动方的FIN报文也是不会读取的。

### 3 SHUT_RDWR方式

#### 3.1 被动方一方先关闭套接字

![image-20240112101814678](https://cdn.jsdelivr.net/gh/FouforPast/pic-storage@main/img/image-20240112101814678.png)

#### 3.2 主动方一方先关闭套接字

![image-20240112101835657](https://cdn.jsdelivr.net/gh/FouforPast/pic-storage@main/img/image-20240112101835657.png)

这种方式谁先关闭套接字的抓包结果是相同的，因为二者在调用close之前因为出现RST报文连接就已经重置了。主动方使用SHUT_RDWR的方式shutdown会发送FIN报文，此时再接收到对方的非FIN消息后，由于己方会回复RST报文。

这里的例子是shutdown之后被动方仍然会发消息的情况，如果被动方的消息在shutdown之前就已经发送完，那么无论哪一方先关闭套接字，最后的报文发送情况都是这样的：

![image-20240112111415069](https://cdn.jsdelivr.net/gh/FouforPast/pic-storage@main/img/image-20240112111415069.png)



### 4 close方式

如果是close之后双方没有数据传输，无论谁先close，报文都是下面这样。

![image-20240112111736273](https://cdn.jsdelivr.net/gh/FouforPast/pic-storage@main/img/image-20240112111736273.png)

上面的情况是在close之前双方的数据都发完的情况，如果主动方close之后，被动方还有数据要发送，就会出现下面的报文，这个和3.1和3.2的报文是一样的。

![image-20240112112623259](https://cdn.jsdelivr.net/gh/FouforPast/pic-storage@main/img/image-20240112112623259.png)

注意，主动方close掉TCP连接后，由于处于TIME_WAIT状态，所以此时去占用主动方close之前的端口会显示端口被占用。



## 总结

- `SHUT_RD` 将关闭读取操作，但不会发送TCP FIN，如果再收到对方普通消息会直接丢弃；如果收到FIN报文，会丢弃并回复RST报文，如果己方再次调用close，会发送RST报文。
- `SHUT_WR` 将关闭写入操作，并发送TCP FIN，最优雅的关闭方式。
- `SHUT_RDWR` 将关闭读取和写入操作，同时发送TCP FIN，从抓取的报文来看，等同于close方式。
