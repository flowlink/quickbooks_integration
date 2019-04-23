#!/bin/bash
docker-compose -f docker-compose.yml \
               -f docker-compose.dev.yml \
               run --rm quickbooks-integration \
               sh -c "bundle exec rspec ${@}"
