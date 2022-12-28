#!/bin/bash
# This script is used to compile the debug version of the code
flutter clean;
flutter pub upgrade;
flutter pub get;
./protogen.sh
flutter run