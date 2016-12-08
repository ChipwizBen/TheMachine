find . -exec md5sum "{}" \; > checksums
sed -i '/checksums/d' checksums
sed -i '/.project/d' checksums
sed -i '/.*\.git.*/d' checksums
