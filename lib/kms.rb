# Used for communicating with AWS KMS
class Kms
  def initialize
    @kms = Aws::KMS::Client.new(region: 'us-east-1')
  end

  def encrypt(file)
    data = IO.read(file)

    # KMS key
    key_id = ENV['CMK_KEY_ID']

    # Response containing the generated ciphertext_blob
    # and plaintext key for the associated key
    resp = @kms.generate_data_key(
      key_id: key_id,
      key_spec: 'AES_256'
    )

    # Encrypt the data
    salt = Time.now.to_i.to_s
    secret_key = resp.plaintext
    iv = OpenSSL::Cipher::Cipher.new('aes-256-cbc').random_iv
    encrypted_data = Encryptor.encrypt(
      value: data,
      key: secret_key,
      iv: iv,
      salt: salt
    )

    # The encrypted data
    JSON.generate(
      'ciphertext' => Base64.encode64(encrypted_data),
      'data_key' => Base64.encode64(resp.ciphertext_blob),
      'iv' => Base64.encode64(iv),
      'salt' => salt
    )
  end

  def decrypt(file)
    data = JSON.parse(IO.read(file))

    data_key = Base64.decode64(data['data_key'])

    # Retrieve the associated plaintext key from KMS
    plaintext_resp = @kms.decrypt(ciphertext_blob: data_key)
    plaintext_key = plaintext_resp.plaintext

    # The decrypted data
    Encryptor.decrypt(
      value: Base64.decode64(data['ciphertext']),
      key: plaintext_key,
      iv: Base64.decode64(data['iv']),
      salt: data['salt']
    )
  end
end
