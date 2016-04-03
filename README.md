# KMSCrypt

# What does this do?
kmscrypt utilizes the AWS Key Management Service (KMS) to help securely encrypt and decrypt data.  Using kmscrypt, you can securely encrypt and decrypt files, store and retrieve them from s3, and even store and retrieve secrets from DynamoDB.

# How does it work?
KMS provides a way of encrypting and decrypting data without having to store the plaintext key used during the encryption process locally.  Using KMS, you create a customer master key (CMK), which provides a CMK ID.  The CMK ID is used to provide a unique encrypted key and plaintext key version of the CMK data key.  The plaintext key is used to encrypt/decrypt the data, and is then discarded.  The encrypted key is saved, as it is used to retrieve the plaintext key.

For example, when encrypting a file with `./kmscrypt encrypt file_name`, the kmscrypt script uses the CMK ID to retrieve the plaintext and encrypted key.  It then uses the plaintext key in order to AES256 encrypt the file, discarding the plaintext key when done.  The encrypted data is then stored, along with the encrypted data key.  When this file needs to be decrypted with `kmscrypt decrypt file`, the script uses the encrypted data key, which is stored along side the encrypted data, to retrieve the plaintext key from KMS, and decrypt the data using the plaintext key, which is then discarded again.

In order to use kmscrypt, you need an IAM user or IAM role.

##S3
kmscrypt allows storing and retrieving the encrypted files in/from an S3 bucket.  It also allows updating the stored encrypted file from the s3 bucket, listing the items in the bucket, and deleting them.

##DynamoDB
kmscrypt allows the storing of secrets within DynamoDB.  A secret can be something like a password, which is stored along with a key name, which is used to identify that secret.  You can store the encrypted secrets, retrieve them (still encrypted or decrypted), update them, delete them, or list them.

## Setup
1. Setup KMS
   - Go to the IAM tab of the AWS console
   - Click on "Encryption Keys" in the left nav menu
   - Click "Create Key" at the top. 
     - For "Alias (required)", put any logical name.
     - For "Key Administrators", pick the user(s) that has access to manage the key itself
     - For "Key Usage Permissions", pick the IAM user(s) or role(s) that have access to use this script.
     - Record the Key ID created
2. Setup kmscrypt
    - Have ruby and bundler installed
    - Clone the repo
    - Run the `bundle install` command within the locally cloned repo
    - Do one of the following:
      - Setup an environment variable for the Key ID created above, with something like: `export CMK_KEY_ID=<Key ID here>`
      - Update the keyId variable in the encrypt method, line 12, within lib/kms.rb
    - Have an IAM role setup that allows access from the instance the script is running on, or configure the IAM keys in environment variables or in a file (directions in the links below):
      - http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html#cli-environment
      - http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html#cli-config-files
    - Provide an S3 bucket name for the bucket variable on line 11 of the kmscrypt file (Note: this is optional, and not supplying a bucket name will just mean you cannot use the s3 features)
    - Provide a DynamoDB table name for the DDB table name used to store secrets in on line 12 of the kmscrypt file (Note: this is optional, and not supplying a table name will just mean you cannot use the DDB features)
      - Make sure that the primary key for this table is created with the name of "name"
