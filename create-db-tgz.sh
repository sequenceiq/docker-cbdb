#!/bin/bash

DBNAME=cbdb

start_db(){

  declare ver=${1:? version required}
  
  echo 'export PUBLIC_IP=1.1.1.1'>Profile
  echo "export DOCKER_TAG_CLOUDBREAK=$ver" >> Profile
  cbd init
  #cbd pull
  
  cbd startdb
  cbd migrate ${DBNAME} up
  if cbd migrate ${DBNAME} status|grep "MyBatis Migrations SUCCESS" ; then
      echo Migration: OK
  else
      echo Migration: ERROR
      exit 1
  fi
}

db_backup() {

    declare ver=${1:? version required}

    # for gracefull shutdown: run another containe with --volumes from
    # docker exec ${DBNAME} bash -c 'kill -INT $(head -1 /var/lib/postgresql/data/postmaster.pid)'
    
    mkdir -p release
    docker exec  cbreak_${DBNAME}_1 tar cz -C /var/lib/postgresql/data . > release/${DBNAME}-${ver}.tgz
}

clean() {
    rm -rf Profile *.yml release/
}

release() {
    declare ver=${1:? version required}
    gh-release create sequenceiq/docker-${DBNAME} "${ver}"
}

update_dockerfile() {
    declare ver=${1:? version required}
     
    sed -i "/^ENV VERSION/ s/[0-9\.]*$/${ver}/" Dockerfile
    git add Dockerfile
    git commit -m "Update Dockerfile to v${ver}"
    git push origin master
}

main() {
    clean
    update_dockerfile "$@"
    start_db "$@"
    db_backup "$@"
    release "$@"
}

[[ "$0" ==  "$BASH_SOURCE" ]] && main "$@"
