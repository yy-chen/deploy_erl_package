#
# Cookbook Name:: test_deploy
# Recipe:: default
#
# Copyright 2015, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

APP_NAME = data_bag_item("application", "deploy")['app']
VERSION = data_bag_item("application", "deploy")['version']
IP = data_bag_item("application", "deploy")['ip']
GIT_URL = data_bag_item('application','appinfo')[APP_NAME]['git_url']
LOCALHOST = node.automatic['ipaddress']
WORK_DIR = "/home/dhcd/boss"
def send_to_node(app, ip)
    execute "send" do
        command <<-EOH
                scp -r #{WORK_DIR}/repo/#{app} dhcd@#{ip}:/tmp
        EOH
        returns [0]
        not_if{LOCALHOST == ip}
    end

    directory "/tmp/#{app}" do
        action :delete
        recursive true
        only_if{File.exists?("#{WORK_DIR}/repo/#{app}") && LOCALHOST == ip}
    end

    ruby_block "cp" do
        block do
            FileUtils.cp_r("#{WORK_DIR}/repo/#{app}", "/tmp")
        end
        only_if{LOCALHOST == ip}
    end
end

create_workdir "create workdir" do 
    work_dir WORK_DIR
end

update_git "update_git" do
    app_name APP_NAME
    git_url GIT_URL
    work_dir WORK_DIR	
end

package "package app" do
    git_url GIT_URL
    app_name APP_NAME
    version VERSION
    work_dir WORK_DIR
end

config_file = File.read("#{WORK_DIR}/source/#{APP_NAME}/rebar.config")
if config_file.scan(/egeoip/).length > 0
    cookbook_file "#{WORK_DIR}/repo/#{APP_NAME}_#{VERSION}/etc/GeoIP2-Country.mmdb" do
        source 'geoip'
        action :create
    end
end

send_to_node("#{APP_NAME}_#{VERSION}", IP)
