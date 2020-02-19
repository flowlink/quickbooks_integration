#!/bin/bash
docker-compose -f docker-compose.qdev.yml \
               ${@:-up -d}
