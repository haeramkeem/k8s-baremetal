#!/bin/bash

cmd=$1

case "$cmd" in

    # Run Postgres
    --up)
        docker run -p 5432:5432 --name postgres -e POSTGRES_PASSWORD=1q2w3e4r -d -v pgdata:/var/lib/postgresql/data postgres
        ;;

    # Run DB Shell
    --sh)
        docker exec -it postgres psql -U postgres
        ;;

    # Stop Postgres
    --down)
        docker stop postgres
        ;;

    # Remove Postgres
    --rm)
        docker rm --force postgres
        ;;

    # Unknown command
    *)
        echo "Unknown command '$cmd'"
        exit 1
        ;;
esac
