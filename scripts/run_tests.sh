#!/bin/bash
docker-compose run --rm quickbooks-integration sh -c "bundle exec rspec ${@}"
