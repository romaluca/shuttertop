# Shuttertop

Update image on docker hub:
cd .ansible && ansible-playbook apps/build/update-docker-image.yml -vvv

Local deploy and build:
./deploy

Local build:
cd .ansible && ansible-playbook -i apps/build/inventory apps/build/build.yml -vvv

Local deploy:
cd .ansible && ansible-playbook -i apps/production/inventory apps/production/deploy.yml -vvv

Add secret variable
ansible-vault encrypt_string --vault-password-file ".ansible/.vault_pass.txt" --stdin-name "variable_name"

https://dreamconception.com/tech/phoenix-automated-build-and-deploy-made-simple/

New apple_id secred:
mix run config/apple_id.ex


I18n
mix gettext.extract --merge



Log level in iex
Logger.configure(level: :debug)


Kill process by port
lsof -i tcp:8081
kill -9 56625
