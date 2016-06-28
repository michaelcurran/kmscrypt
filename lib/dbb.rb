# Used for communicating with AWS DynamoDB
class DdbKms < Kms
  def initialize(table)
    @table = table
    @ddb = Aws::DynamoDB::Client.new(region: 'us-east-1')
    super()
  end

  def putdb(key, value)
    # Makes sure there's a value to put so it isn't null
    if value.nil?
      abort('ABORTED! Did you enter in a value to encrypt?')
      exit 1
    end

    # Store the value into a temp file
    file = '.tmp-encryptdb-_-1357915'
    File.open(file, 'wb') do |f|
      f.puts value
    end

    # Retrieve the encrypted data
    encrypted = encrypt(file)

    # Parse the JSON
    data = JSON.parse(encrypted)

    # Cleanup the temp file
    File.delete(file)

    # Store the key/value
    @ddb.put_item(
      table_name: @table,
      item: {
        'name' => key.to_s,
        'ciphertext' => data['ciphertext'],
        'data_key' => data['data_key'],
        'iv' => data['iv'],
        'salt' => data['salt']
      })
  end

  def getdb(key)
    # Get the encrypted data for a key
    resp = @ddb.get_item(table_name: @table, key: { 'name' => key })
    resp.item.to_json
  end

  def decryptdb(key)
    # Gets the encrypted data for the key
    resp = @ddb.get_item(table_name: @table, key: { 'name' => key })

    # Stores it in a tmp file as json
    file = '.tmp-encryptdb-_-1357915'

    # Use shared memory if available
    full_file = if File.directory?('/dev/shm')
                  "/dev/shm/#{file}"
                else
                  Dir.pwd + "/#{file}"
                end

    File.open(full_file, 'wb') do |f|
      f.puts resp.item.to_json
    end

    puts decrypt(full_file)

    # Cleanup
    File.delete(full_file)
  end

  def listdb
    # Lists all the key names
    resp = @ddb.scan(table_name: @table, attributes_to_get: ['name'])
    resp.count.times do |i|
      puts resp.items[i]['name']
    end
  end

  def deletedb(key)
    # Deletes a key from the table
    @ddb.delete_item(table_name: @table, key: { 'name' => key })
  end
end
