#!/bin/bash

swift build -c release -Xswiftc -static-stdlib
echo "cp .build/release/Baby /usr/local/bin/baby"
cp .build/release/Baby /usr/local/bin/baby
