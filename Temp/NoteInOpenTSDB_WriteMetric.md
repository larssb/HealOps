
        # TODO: Look further into the request data... e.g. I got this error:
        <#
            2017-11-09 10:07:44,209 ERROR [OpenTSDB I/O Worker #3] RpcHandler: [id: 0x9344fdcb, /192.168.49.22:51840 => /172.17.0.2:4242] Received an unsupported chunked request: DefaultHttpRequest(chunked: true)
POST /api/put HTTP/1.1
User-Agent: Mozilla/5.0 (Windows NT; Windows NT 6.3; da-DK) WindowsPowerShell/5.1.14409.1005
Content-Type: application/json
Host: 192.168.49.111:4242
Content-Length: 211
Expect: 100-continue
2017-11-09 10:07:44,210 WARN  [OpenTSDB I/O Worker #3] HttpQuery: [id: 0x9344fdcb, /192.168.49.22:51840 => /172.17.0.2:4242] Bad Request on /api/put: Chunked request not supported.
2017-11-09 10:07:44,213 INFO  [OpenTSDB I/O Worker #3] HttpQuery: [id: 0x9344fdcb, /192.168.49.22:51840 => /172.17.0.2:4242] HTTP /api/put done in 4ms
        #>