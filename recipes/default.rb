#
# Cookbook Name:: ggsn-simulation-chef
# Recipe:: default
#
# Copyright (C) 2013 YOUR_NAME
# 
# All rights reserved - Do Not Redistribute
#

require_recipe "simpy"

simpy_user = node["simpy"]["user"]
simpy_home = File.join("/", "home", simpy_user)
simpy_virtualenv = File.join(simpy_home, node["simpy"]["virtualenv"])

simulation_model_repository = "git@github.com:fmetzger/ggsn-simulation.git"
study_repository = "git://github.com/cschwartz/ggsn-simulation-studies.git"
study_name = "ggsn-simulation-study"

simpy_ssh_directory = File.join(simpy_home, ".ssh")
simpy_deploy_key = File.join(simpy_ssh_directory, "deploy_key")
vagrant_directory = File.join("/", "vagrant")
vagrant_deploy_key_location = File.join(vagrant_directory, "deploy_key")
metal_deploy_key_location = File.join("/", "tmp", "deploy_key")
simpy_ssh_wrapper = File.join(simpy_home, "deploy_ssh")
simulation_directory = File.join(simpy_home, "ggsn-simulation")
study_directory = File.join(simpy_home, study_name)
virtualenv_file_location = File.join(study_directory, ".virtualenv")
simulationbase_file_location = File.join(study_directory, ".simbase")

gem_package "bundler"

package "git"

directory simpy_ssh_directory do
  owner simpy_user
end

file simpy_deploy_key do
  is_vagrant = File.exists?("/vagrant") && File.directory?("/vagrant")
  mode 00600
  owner simpy_user
  content File.read is_vagrant ? vagrant_deploy_key_location : metal_deploy_key_location
end

file simpy_ssh_wrapper do
  content <<-eos
#!/bin/sh
exec /usr/bin/ssh -o StrictHostKeyChecking=no -i #{ simpy_deploy_key } "$@"
eos
  mode 00755
  owner simpy_user
end

git simulation_directory do
  user simpy_user
  repository simulation_model_repository
  ssh_wrapper simpy_ssh_wrapper
end

bash "bundle install for simulation" do
  user simpy_user
  cwd simulation_directory
  code "bundle install --path vendor"
end

git study_directory do
  user simpy_user
  repository study_repository
end

bash "bundle install for model" do
  user simpy_user
  cwd study_directory
  code "bundle install --path vendor"
end

file virtualenv_file_location do
  user simpy_user
  content simpy_virtualenv
end

file simulationbase_file_location do
  user simpy_user
  content simulation_directory
end
