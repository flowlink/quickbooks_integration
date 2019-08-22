#!/bin/bash
docker-compose -f docker-compose.yml \
               -f docker-compose.qdev.yml \
               ${@:-up -d}
