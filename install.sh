#!/bin/bash

swift build -c release -Xswiftc -static-stdlib
echo "cp .build/release/baby /usr/local/bin/baby"
cp .build/release/baby /usr/local/bin/baby
