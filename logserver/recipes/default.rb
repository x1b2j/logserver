#
# Cookbook Name:: logserver
# Recipe:: default
#
# Copyright 2013, aasaanpay
# gauravrajput@aasaanpay.com
# All rights reserved - Do Not Redistribute
################################################################


package 'make'
package 'gnutls'
package 'gcc'
package 'nc'
package 'wget'
package 'rpm-build'
package 'rpmdevtools'
package 'gcc-c++'
package 'nano'
package 'git'
package 'ruby'
package 'rubygems'
package 'ruby-devel'
package 'java'
package 'java-1.7.0-openjdk'
package 'vim'
package 'httpd'

template "/root/wget_package_download" do
	mode 0644
	source "wget.erb"
end

template "/root/cert" do
	mode 0644
	source "cert.erb"
end

template "/root/lumberjack.conf" do
	mode 0644
	source "lumberjack.erb"
end


bash "package_download" do
	user "root"
	cwd "/root"
	code <<-EOH
	iptables -F
	setenforce 0
	wget --quiet -i wget_package_download --no-check-certificate
	tar -xvf *.tar.gz
	tar -xvf v0.2.0
	chmod +x cert
	./cert
	./elastic*/bin/elasticsearch -f &
	rpm -ivh lumberjack-0.0.30-1.x86_64.rpm	
	cp server.cert /etc/ssl/certs/
	cp server.key /etc/ssl/ 	
	java -jar logstash-1.*.jar agent -f lumberjack.conf &
	/opt/lumberjack/bin/lumberjack.sh --host localhost --port 44444 --ssl-ca-path /root/server.cert /var/log/messages /var/log/yum.log &
	EOH
#	ignore_failure true
end

file "/root/Kibana-0.2.0/KibanaConfig.rb" do
	action :delete
end

template "/root/Kibana-0.2.0/KibanaConfig.rb" do
	mode 0644
	source "KibanaConfig.erb"
        action :create_if_missing
end

bash "configure_kibana" do
	user "root"
	cwd "/root/Kibana-0.2.0"
	code <<-EOH
	gem install update --no-ri --no-rdoc
	gem install bundler --no-ri --no-rdoc
	bundle install
	ruby /root/Kibana-0.2.0/kibana.rb &
	EOH
end
