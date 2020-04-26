#!/bin/bash

echo "Are you currently inside the correct project directory and pipenv shell? (y/n)"
read -r response

CONTINUE=false
if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]; then
  CONTINUE=true
fi

if ! $CONTINUE; then
  echo "Please navigate to the correct directory and activate the pipenv shell"
  echo "Then run this script again"
  exit
fi

echo "Do you want to delete and re-run migrations? (y/n)"
read -r make_migrations
delete_migrations=false
if [[ $make_migrations =~ ^([yY][eE][sS]|[yY])$ ]]; then
    delete_migrations=true
fi


docker-compose down
sleep 3
docker system prune
docker volume rm neutron_postgres-data
docker-compose up -d
sleep 5

if $delete_migrations; then
  find . -path "*/migrations/*.py" -not -name "__init__.py" -delete
  python manage.py makemigrations
fi

python manage.py migrate
python manage.py create_org
python manage.py loaddata locations-fixture.json
python manage.py tenant_command loaddata tenant-fixture.json
