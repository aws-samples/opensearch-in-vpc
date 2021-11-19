#!/bin/bash

# Install nginx
amazon-linux-extras install nginx1.12

# Generate a self-signed certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/cert.key \
    -out /etc/nginx/cert.crt \
    -subj "${self_signed_certificate_subject}"

# Configure nginx
cat > /etc/nginx/conf.d/default.conf << 'EOF'
resolver ${vpc_dns_resolver_ip} ipv6=off;

server {
    listen 443;
    server_name $host;
    rewrite ^/$ https://$host/_plugin/kibana redirect;

    ssl_certificate /etc/nginx/cert.crt;
    ssl_certificate_key /etc/nginx/cert.key;

    ssl on;
    ssl_session_cache builtin:1000 shared:SSL:10m;
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
    ssl_ciphers HIGH:!aNULL:!eNULL:!EXPORT:!CAMELLIA:!DES:!MD5:!PSK:!RC4;
    ssl_prefer_server_ciphers on;

    set $es_endpoint ${elasticsearch_endpoint};
    set $cognito_endpoint ${cognito_host};

    location ^~ /_plugin/kibana {
        # Forward requests to Kibana
        proxy_pass https://$es_endpoint;

        # Handle redirects to Amazon Cognito
        proxy_redirect https://$cognito_endpoint https://$host;

        # Update cookie domain and path
        proxy_cookie_domain $es_endpoint $host;

        # Response buffer settings
        proxy_buffer_size 128k;
        proxy_buffers 4 256k;
        proxy_busy_buffers_size 256k;
    }

    location ~ \/(log|sign|error|fav|forgot|change|confirm) {
        # Forward requests to Cognito
        proxy_pass https://$cognito_endpoint;

        # Handle redirects to Kibana
        proxy_redirect https://$es_endpoint https://$host;

        # Handle redirects to Amazon Cognito
        proxy_redirect https://$cognito_endpoint https://$host;

        # Update cookie domain
        proxy_cookie_domain $cognito_endpoint $host;
    }
}
EOF

systemctl enable nginx.service
systemctl restart nginx.service
