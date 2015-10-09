find . -exec md5sum "{}" \; > checksums
sed -i '/checksums/d' checksums
