class Kms
  def initialize(bucket)
    @bucket = bucket
    @kms = Aws::KMS::Client.new(region:'us-east-1')
    @s3 = Aws::S3::Client.new(region: 'us-east-1')
  end

  def encrypt(file)
    data = IO.read(file)

    #KMS key
    keyId = ENV['CMK_KEY_ID']

    #Response containing the generated ciphertext_blob and plaintext key for the associated key
    resp = @kms.generate_data_key(
      key_id: keyId,
      key_spec: 'AES_256'
    )

    #Encrypt the data
    salt = Time.now.to_i.to_s
    secretKey = resp.plaintext
    iv = OpenSSL::Cipher::Cipher.new('aes-256-cbc').random_iv
    encryptedData = Encryptor.encrypt(:value => data, :key => secretKey, :iv => iv, :salt => salt)

    puts JSON.generate({ 'ciphertext' => Base64.encode64(encryptedData), 'dataKey' => Base64.encode64(resp.ciphertext_blob), 'iv' => Base64.encode64(iv), 'salt' => salt })
  end

  def decrypt(file)
    data = JSON.parse(IO.read(file))

    dataKey =  Base64.decode64(data['dataKey'])

    #Retrieve the associated plaintext key from KMS
    plaintextResp = @kms.decrypt(:ciphertext_blob => dataKey)
    plaintextKey = plaintextResp.plaintext

    #return decrypted data
    puts Encryptor.decrypt(:value => Base64.decode64(data['ciphertext']), :key => plaintextKey, :iv => Base64.decode64(data['iv']), :salt => data['salt'])
  end

  def put(file)
    #Parse out only the file name (useful due to the updateS3 method)
    fileName = file.split("/")[-1]
    fileName = fileName.split(".updated-_-12345678901")[0]

    File.open(file, 'rb') do |f|
      @s3.put_object(bucket: @bucket, key: fileName, body: f)
    end
  end

  def get(file)
    File.open(file, 'wb') do |f|
      obj = @s3.get_object({ bucket: @bucket, key: file }, target: f)
    end
  end

  def update(file)
    #Use shared memory to temporarily store the file if linux
    if File.exists?('/etc/issue')
      os = 'linux'
      fullFile = '/dev/shm/' + file
    else
      os = 'mac'
      fullFile = Dir.pwd + '/' + file
    end

    tmp = fullFile + '.tmp-_-12345678901555'
    decrypted = fullFile + '.decrypted-_-12345678901555'
    updated = fullFile + '.updated-_-12345678901555'

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
    File.open(updated, 'wb') do |g|
      g.puts encrypt(decrypted)
    end
    put(updated)

    #Cleanup
    File.delete(decrypted, updated, tmp)
  end

  def delete(file)
    #Delete the file
    @s3.delete_object(bucket: @bucket, key: file)
  end

  def list
    resp = @s3.list_objects(bucket: @bucket)

    #List out the file names, sizes, and dates
    printf "%-40s\t%s\t%s\n", "Name", "Size", "Last Modified"
    (0..resp.contents.length-1).each do |num|
      printf "%-40s\t%s\t%s\n", resp.contents[num].key, resp.contents[num].size, resp.contents[num].last_modified
    end
  end
end
