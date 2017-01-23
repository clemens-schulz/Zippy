#!/bin/bash

#  create_test_data.sh
#  Zippy
#
#  Created by Clemens on 17/01/2017.
#  Copyright © 2017 Clemens Schulz. All rights reserved.

TESTDATA_PATH='./testdata/'

UNCOMPRESSED_DIR='uncompressed'
COMPRESSED_DIR='zip'

if [ ! -d $TESTDATA_PATH ];
then
	mkdir -p "$TESTDATA_PATH"
fi

cd "$TESTDATA_PATH"

if [ -f "complete" ];
then
	echo "Testdata already exists. Please remove 'testdata' fodler completely to generate new testdata."
	exit 0 # Testdata already exists
fi

# Generate files containing random data for testing
mkdir "$UNCOMPRESSED_DIR"
cd "$UNCOMPRESSED_DIR"

for i in `seq 1 500`;
do
	head -c $((i*64)) < /dev/urandom > "file_${i}.txt"
	head -c $((i*64)) < /dev/zero >> "file_${i}.txt" # Makes data compressible
done

FILENAMETEST_FILENAME='filename_length_and_encoding_test äöüßÄÖÜ^°!§$%&()=?#+-;:,.あうえいおコンピュータ　日本語 한국어 普通话 العَرَبِيَّة ру́сский язы́к le français [lə fʁɑ̃sɛ].txt'
head -c $((i*64)) < /dev/urandom > "$FILENAMETEST_FILENAME"

mkdir "../$COMPRESSED_DIR"

head -c 2147500000 < /dev/zero | zip "../$COMPRESSED_DIR/zip64.zip" -
head -c 600000000 < /dev/urandom | zip "../$COMPRESSED_DIR/large.zip" -

zip "../$COMPRESSED_DIR/deflate.zip" file_*.txt "$FILENAMETEST_FILENAME"
zip -s 1m "../$COMPRESSED_DIR/split.zip" file_*.txt "$FILENAMETEST_FILENAME"

touch "../complete"

# TODO:
# weak encrypted (zipcloat)
# file comment
