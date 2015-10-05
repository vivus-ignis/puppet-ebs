#!/bin/sh
set -x

echo "Defaults: baron !requiretty" > /etc/sudoers.d/999-vagrant
echo "Defaults env_keep += \"SSH_AUTH_SOCK\"" >> /etc/sudoers.d/999-vagrant
echo "vagrant ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/999-vagrant
chmod 0440 /etc/sudoers.d/999-vagrant
