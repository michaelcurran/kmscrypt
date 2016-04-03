class S3Kms < Kms
  def initialize(bucket)
    @bucket = bucket
    @s3 = Aws::S3::Client.new(region: 'us-east-1')
    super()
  end

  def puts3(file)
    #Parse out only the file name (useful due to the updates3 method)
    fileName = file.split("/")[-1]
    fileName = fileName.split(".updated-_-1357915")[0]

    File.open(file, 'rb') do |f|
      @s3.put_object(bucket: @bucket, key: fileName, body: f)
    end
  end

  def gets3(file)
    File.open(file, 'wb') do |f|
      obj = @s3.get_object({ bucket: @bucket, key: file }, target: f)
    end
  end

  def updates3(file)
    #Use shared memory to temporarily store the file if linux
    if File.exists?('/etc/issue')
      os = 'linux'
      fullFile = "/dev/shm/#{file}"
    else
      os = 'mac'
      fullFile = Dir.pwd + "/#{file}"
    end

    tmp = "#{fullFile}.tmp-_-1357915"
    decrypted = "#{fullFile}.decrypted-_-1357915"
    updated = "#{fullFile}.updated-_-1357915"

    #Grab the file and store it as a tmp file
    File.open(tmp, 'wb') do |f|
      obj = @s3.get_object({ bucket: @bucket, key: file }, target: f)
    end

    #Decrypt to a file and edit
    File.open(decrypted, 'wb') do |f|
      f.puts decrypt(tmp)
    end

    system('vi', decrypted)

    #Encrypt the updated file and upload it
    File.open(updated, 'wb') do |f|
      f.puts encrypt(decrypted)
    end

    puts3(updated)

    #Cleanup
    File.delete(decrypted, updated, tmp)
  end

  def deletes3(file)
    #Delete the file
    @s3.delete_object(bucket: @bucket, key: file)
  end

  def lists3
    resp = @s3.list_objects(bucket: @bucket)

    #List out the file names, sizes, and dates
    printf "%-40s\t%s\t%s\n", "Name", "Size", "Last Modified"
    (0..resp.contents.length-1).each do |num|
      printf "%-40s\t%s\t%s\n", resp.contents[num].key, resp.contents[num].size, resp.contents[num].last_modified
    end
  end
end
