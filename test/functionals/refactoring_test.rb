`rm fixtures/*.html`
ls = `ls fixtures/*.html`
ls.empty? ? puts("OK") : abort("failed to remove old HTMLs!")

test_file = ARGV[0] || "image_generation_test.rb"
puts "running #{test_file}..."
time = Time.now
`ruby #{test_file}`
puts "... done in #{Time.now - time}sec"

diff = `bash -c "diff <(md5 fixtures/*.html) original_md5s.txt"`
diff.empty? ? puts("OK") : (puts(diff); abort("HTML checksums are wrong!"))
