#!/bin/bash

k get secrets mysecret --template={{.data.mypassword}} | base64 -d
