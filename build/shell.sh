#!/bin/bash

service nginx start;
pm2 start /usr/src/tempapp/ecosystem.config.js;