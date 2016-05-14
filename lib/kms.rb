class Kms
  def initialize
    @kms = Aws::KMS::Client.new(region:'us-east-1')
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

    #The encrypted data
    JSON.generate({ 'ciphertext' => Base64.encode64(encryptedData), 'dataKey' => Base64.encode64(resp.ciphertext_blob), 'iv' => Base64.encode64(iv), 'salt' => salt })
  end

  def decrypt(file)
    data = JSON.parse(IO.read(file))

    dataKey =  Base64.decode64(data['dataKey'])

    #Retrieve the associated plaintext key from KMS
    plaintextResp = @kms.decrypt(:ciphertext_blob => dataKey)
    plaintextKey = plaintextResp.plaintext

    #The decrypted data
    Encryptor.decrypt(:value => Base64.decode64(data['ciphertext']), :key => plaintextKey, :iv => Base64.decode64(data['iv']), :salt => data['salt'])
  end
end
