#!/bin/bash

swift build -c release -Xswiftc -static-stdlib
cp .build/release/Baby /usr/local/bin/baby
